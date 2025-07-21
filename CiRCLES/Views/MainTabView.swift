//
//  MainTabView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import Komponents
import StoreKit
import SwiftUI
import SwiftData
import TipKit

struct MainTabView: View {

    @Environment(\.requestReview) var requestReview
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>
    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Oasis.self) var oasis
    @Environment(Planner.self) var planner
    @Environment(UserSelections.self) var selections

    @State var isReloadingData: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool
    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    @Namespace var loadingNamespace

    var body: some View {
        @Bindable var authenticator = authenticator
        @Bindable var database = database
        @Bindable var oasis = oasis
        TabView(selection: $navigator.selectedTab) {
            Tab("Tab.Map", systemImage: "map.fill", value: .map) {
                MapView()
            }
            Tab("Tab.Circles", systemImage: "square.grid.3x3.fill", value: .circles, role: .search) {
                CatalogView()
            }
            Tab("Tab.Favorites", systemImage: "star.fill", value: .favorites) {
                FavoritesView()
            }
            .hidden(!planner.isActiveEventLatest)
            Tab("Tab.My", image: "TabIcon.My", value: .my) {
                MyView()
            }
            Tab("Tab.More", systemImage: "ellipsis", value: .more) {
                MoreView()
            }
        }
        .tabBarMinimizeBehavior(.automatic)
        .tabViewBottomAccessory {
            UnifiedControl()
        }
        #if DEBUG
        .debugOverlay()
        #endif
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
            authenticator.setupReachability()
        }
        .onChange(of: authenticator.onlineState) { _, newValue in
            switch newValue {
            case .online, .offline:
                reloadData()
                launchCount += 1
                if launchCount > 2 && !hasReviewBeenPrompted {
                    requestReview()
                    hasReviewBeenPrompted = true
                }
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
                    await oasis.setBodyText("Loading.FetchEventData")
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
            await oasis.setBodyText("Loading.DownloadTextDatabase")
            await database.downloadTextDatabase(for: activeEvent, authToken: token) { progress in
                await oasis.setProgress(progress)
            }
            await oasis.setBodyText("Loading.DownloadImageDatabase")
            await database.downloadImageDatabase(for: activeEvent, authToken: token) { progress in
                await oasis.setProgress(progress)
            }

            await oasis.setBodyText("Loading.Database")
            database.connect()

            await oasis.setHeaderText("Shared.LoadingHeader.Initial")

            if !isDatabaseInitialized {

                let actor = DataConverter(modelContainer: sharedModelContainer)

                await actor.disableAutoSave()
                await actor.deleteAll()
                imageCache.clear()

                await oasis.setBodyText("Loading.Events")
                await actor.loadEvents(from: database.textDatabase)
                await oasis.setBodyText("Loading.Maps")
                await actor.loadMaps(from: database.textDatabase)
                await actor.loadLayouts(from: database.textDatabase)
                await oasis.setBodyText("Loading.Genres")
                await actor.loadGenres(from: database.textDatabase)
                await oasis.setBodyText("Loading.Circles")
                await actor.loadCircles(from: database.textDatabase)

                await actor.save()
                await actor.enableAutoSave()

                isDatabaseInitialized = true
            }

            await oasis.setBodyText("Loading.Images")
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
        await oasis.setBodyText("Loading.Favorites")
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
