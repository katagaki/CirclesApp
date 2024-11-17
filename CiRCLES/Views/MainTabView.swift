//
//  MainTabView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI
import SwiftData
import TipKit

struct MainTabView: View {

    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var navigator: Navigator
    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Oasis.self) var oasis
    @Environment(Planner.self) var planner

    @State var isDownloading: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    @Namespace var loadingNamespace

    var body: some View {
        @Bindable var authenticator = authenticator
        @Bindable var database = database
        TabView(selection: $navigator.selectedTab) {
            Tab("Tab.Map", systemImage: "map.fill", value: .map) {
                MapView()
            }
            Tab("Tab.Circles", systemImage: "square.grid.3x3.fill", value: .circles) {
                CatalogView()
            }
            if planner.isActiveEventLatest {
                Tab("Tab.Favorites", systemImage: "star.fill", value: .favorites) {
                    FavoritesView()
                }
            }
            Tab("Tab.My", image: "TabIcon.My", value: .my) {
                MyView()
            }
            Tab("Tab.More", systemImage: "ellipsis", value: .more) {
                MoreView()
            }
        }
        .overlay {
            if oasis.isShowing {
                oasis.progressView(loadingNamespace)
            }
        }
        .sheet(isPresented: $authenticator.isAuthenticating) {
            LoginView()
                .environment(authenticator)
                .interactiveDismissDisabled()
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        .onChange(of: authenticator.onlineState) { _, newValue in
            switch newValue {
            case .online:
                Task {
                    authenticator.restoreAuthentication()
                    await authenticator.refreshAuthenticationToken()
                }
            case .offline:
                authenticator.useOfflineAuthenticationToken()
                reloadData()
            case .undetermined: break
            }
        }
        .onChange(of: authenticator.token) { _, _ in
            if authenticator.token != nil, !authenticator.isRestoring {
                reloadData()
            }
        }
        .onChange(of: planner.activeEventNumber) { oldValue, _ in
            if oldValue != -1 {
                planner.activeEventNumberUserDefault = planner.activeEventNumber
                planner.updateActiveEvent(onlineState: authenticator.onlineState)
                reloadData(forceDownload: true)
            }
        }
        .onChange(of: planner.participation) { _, _ in
            planner.participationUserDefault = planner.participation
        }
    }

    func reloadData(forceDownload: Bool = false) {
        if !isDownloading {
            isDownloading = true
            if forceDownload {
                isDatabaseInitialized = false
            }
            oasis.open {
                Task {
                    if let authToken = authenticator.token {
                        await planner.prepare(authToken: authToken)
                    }
                    planner.updateActiveEvent(onlineState: authenticator.onlineState)
                    let activeEvent = planner.activeEvent
                    Task.detached {
                        await loadDataFromDatabase(for: activeEvent)
                        await loadFavorites()
                        await MainActor.run {
                            oasis.close()
                            isDownloading = false
                        }
                    }
                }
            }
        }
    }

    func loadDataFromDatabase(for activeEvent: WebCatalogEvent.Response.Event? = nil) async {
        UIApplication.shared.isIdleTimerDisabled = true

        let token = authenticator.token ?? OpenIDToken()

        if let activeEvent {
            await oasis.setHeaderText("Shared.LoadingHeader.Download")
            await oasis.setBodyText("Shared.LoadingText.DownloadTextDatabase")
            await database.downloadTextDatabase(for: activeEvent, authToken: token) { progress in
                await oasis.setProgress(progress)
            }
            await oasis.setBodyText("Shared.LoadingText.DownloadImageDatabase")
            await database.downloadImageDatabase(for: activeEvent, authToken: token) { progress in
                await oasis.setProgress(progress)
            }
        }

        await oasis.setBodyText("Shared.LoadingText.Database")
        database.connect()

        if !isDatabaseInitialized {
            await oasis.setHeaderText("Shared.LoadingHeader.Initial")

            let actor = DataConverter(modelContainer: sharedModelContainer)

            await actor.disableAutoSave()
            await actor.deleteAll()
            imageCache.clear()

            await oasis.setBodyText("Shared.LoadingText.Events")
            await actor.loadEvents(from: database.textDatabase)
            await oasis.setBodyText("Shared.LoadingText.Maps")
            await actor.loadMaps(from: database.textDatabase)
            await actor.loadLayouts(from: database.textDatabase)
            await oasis.setBodyText("Shared.LoadingText.Genres")
            await actor.loadGenres(from: database.textDatabase)
            await oasis.setBodyText("Shared.LoadingText.Circles")
            await actor.loadCircles(from: database.textDatabase)

            await actor.save()
            await actor.enableAutoSave()

            isDatabaseInitialized = true
        }

        await oasis.setBodyText("Shared.LoadingText.Images")
        database.imageCache.removeAll()
        database.loadCommonImages()
        database.loadCircleImages()

        database.disconnect()

        UIApplication.shared.isIdleTimerDisabled = false
    }

    func loadFavorites() async {
        await oasis.setModality(false)
        await oasis.setHeaderText("Shared.LoadingHeader.Favorites")
        await oasis.setBodyText("Shared.LoadingText.Favorites")
        if let token = authenticator.token {
            let actor = FavoritesActor()
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }
}
