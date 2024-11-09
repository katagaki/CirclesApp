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
    @EnvironmentObject var imageCache: ImageCache
    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(Oasis.self) var oasis

    @State var isDownloading: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool
    @AppStorage(wrappedValue: -1, "Events.Active.Number") var activeEventNumber: Int
    @AppStorage(wrappedValue: true, "Events.Active.IsLatest") var isActiveEventLatest: Bool

    @Namespace var loadingNamespace

    var body: some View {
        @Bindable var authManager = authManager
        @Bindable var database = database
        TabView(selection: $navigator.selectedTab) {
            MapView()
                .tabItem {
                    Label("Tab.Map", systemImage: "map.fill")
                }
                .tag(TabType.map)
            CirclesView()
                .tabItem {
                    Label("Tab.Circles", systemImage: "square.grid.3x3.fill")
                }
                .tag(TabType.circles)
            if isActiveEventLatest {
                FavoritesView()
                    .tabItem {
                        Label("Tab.Favorites", systemImage: "star.fill")
                    }
                    .tag(TabType.favorites)
            }
            MyView()
                .tabItem {
                    Label("Tab.My", image: .tabIconMy)
                }
                .tag(TabType.my)
            MoreView()
                .tabItem {
                    Label("Tab.More", systemImage: "ellipsis")
                }
                .tag(TabType.more)
        }
        .overlay {
            if oasis.isShowing {
                oasis.progressView(loadingNamespace)
            }
        }
        .sheet(isPresented: $authManager.isAuthenticating) {
            LoginView()
                .environment(authManager)
                .interactiveDismissDisabled()
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        .onChange(of: authManager.onlineState) { _, newValue in
            switch newValue {
            case .online:
                Task {
                    authManager.restoreAuthentication()
                    await authManager.refreshAuthenticationToken()
                }
            case .offline:
                authManager.useOfflineAuthenticationToken()
                if !isDownloading {
                    isDownloading = true
                    Task.detached {
                        await loadDataFromDatabase(for: activeEventNumber)
                    }
                }
            default: break
            }
        }
        .onChange(of: authManager.token) { _, _ in
            if authManager.token != nil && !authManager.isRestoring {
                if !isDownloading {
                    isDownloading = true
                    oasis.open {
                        Task.detached {
                            await loadDataFromDatabase(for: activeEventNumber)
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
        .onChange(of: activeEventNumber) { oldValue, newValue in
            if oldValue != -1 && newValue != -1 {
                if !isDownloading {
                    isDownloading = true
                    isDatabaseInitialized = false
                    oasis.open {
                        Task.detached {
                            await loadDataFromDatabase(for: newValue)
                            await MainActor.run {
                                oasis.close()
                                isDownloading = false
                            }
                        }
                    }
                }
            }
        }
        .onReceive(navigator.$selectedTab, perform: { newValue in
            if newValue == navigator.previouslySelectedTab {
                navigator.popToRoot(for: newValue)
            }
            navigator.previouslySelectedTab = newValue
        })
    }

    func loadDataFromDatabase(for eventNumber: Int) async {
        UIApplication.shared.isIdleTimerDisabled = true

        let token = authManager.token ?? OpenIDToken()

        if let eventData = await WebCatalog.events(authToken: token),
           let latestEvent = eventData.list.first(where: {$0.id == eventData.latestEventID}) {

            var activeEvent: WebCatalogEvent.Response.Event?
            if eventNumber != -1 {
                if let eventInList = eventData.list.first(where: {$0.number == eventNumber}) {
                    activeEvent = WebCatalogEvent.Response.Event(
                        id: eventInList.id,
                        number: eventNumber
                    )
                    isActiveEventLatest = eventNumber == eventData.latestEventNumber
                } else {
                    isActiveEventLatest = false
                }
            } else {
                activeEvent = latestEvent
                activeEventNumber = eventNumber
            }
            isActiveEventLatest = activeEventNumber == eventData.latestEventNumber

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
        if let token = authManager.token {
            let actor = FavoritesActor()
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }
}
