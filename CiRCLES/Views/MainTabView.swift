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

    @State var isReloadingData: Bool = false

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
        #if DEBUG
        .overlay {
            ZStack(alignment: .topLeading) {
                Color.clear
                VStack(alignment: .leading) {
                    Group {
                        switch authenticator.onlineState {
                        case .online:
                            RoundedRectangle(cornerRadius: 6.0)
                                .fill(Color.green)
                        case .offline:
                            RoundedRectangle(cornerRadius: 6.0)
                                .fill(Color.red)
                        case .undetermined:
                            RoundedRectangle(cornerRadius: 6.0)
                                .fill(Color.gray)
                        }
                    }
                    .frame(width: 8.0, height: 8.0)
                    Group {
                        Text(verbatim: "Token expiry: \(authenticator.tokenExpiryDate)")
                        Text(verbatim: "Token string: \((authenticator.token?.accessToken ?? "").prefix(5))")
                        Text(verbatim: "Active event number: \(planner.activeEventNumber)")
                        Text(verbatim: "Event count: \(String(describing: planner.eventData?.list.count))")
                    }
                    .font(.system(size: 10.0))
                }
            }
        }
        #endif
        .overlay {
            if oasis.isShowing || authenticator.onlineState == .undetermined {
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
            if authenticator.onlineState == .online {
                reloadData()
            }
        }
        .onChange(of: authenticator.onlineState) { oldValue, newValue in
            switch newValue {
            case .online:
                if oldValue == .offline && newValue == .online {
                    let isAuthFresh = authenticator.restoreAuthenticationFromKeychainAndDefaults()
                    if isAuthFresh {
                        Task {
                            await authenticator.refreshAuthenticationToken()
                        }
                    }
                } else {
                    Task {
                        await authenticator.refreshAuthenticationToken()
                    }
                }
            case .offline:
                authenticator.useOfflineAuthenticationToken()
                reloadData()
            case .undetermined: break
            }
        }
        .onChange(of: authenticator.token) { _, newValue in
            if newValue != nil {
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
    }

    func reloadData(forceDownload: Bool = false) {
        if !isReloadingData {
            isReloadingData = true
            if forceDownload {
                isDatabaseInitialized = false
            }
            oasis.open {
                Task {
                    await oasis.setHeaderText("Shared.LoadingHeader.Event")
                    await oasis.setBodyText("Shared.LoadingText.FetchEventData")
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
                            isReloadingData = false
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
        }

        UIApplication.shared.isIdleTimerDisabled = false
    }

    func loadFavorites() async {
        await oasis.setModality(false)
        await oasis.setHeaderText("Shared.LoadingHeader.Favorites")
        await oasis.setBodyText("Shared.LoadingText.Favorites")
        let actor = FavoritesActor(modelContainer: sharedModelContainer)
        if let token = authenticator.token {
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        } else {
            let (items, wcIDMappedItems) = await actor.all(authToken: OpenIDToken())
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }
}
