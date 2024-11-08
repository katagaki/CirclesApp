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
    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database

    let databasesInitializedKey: String = "Database.Initialized"

    @State var isInitialTokenRefreshComplete: Bool = false
    @State var isLoadingModal: Bool = true
    @State var isProgressDeterminate: Bool = false
    @State var progressHeaderText: String?

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
            if database.isBusy {
                if isLoadingModal {
                    LoadingOverlay(namespace: loadingNamespace, progressHeaderText: $progressHeaderText)
                } else {
                    LoadingPill(namespace: loadingNamespace, progressHeaderText: $progressHeaderText)
                }
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
                Task.detached {
                    await loadDataFromDatabase(for: activeEventNumber)
                }
            default: break
            }
        }
        .onChange(of: authManager.token) { _, _ in
            if authManager.token != nil && !authManager.isRestoring {
                if !database.isBusy {
                    withAnimation(.snappy.speed(2.0)) {
                        self.database.isBusy = true
                    } completion: {
                        Task.detached {
                            await loadDataFromDatabase(for: activeEventNumber)
                            await loadFavorites()
                            await MainActor.run {
                                closeLoadingOverlay()
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: activeEventNumber) { oldValue, newValue in
            if oldValue != -1 && newValue != -1 {
                UserDefaults.standard.set(false, forKey: databasesInitializedKey)
                withAnimation(.snappy.speed(2.0)) {
                    self.database.isBusy = true
                } completion: {
                    Task.detached {
                        await loadDataFromDatabase(for: newValue)
                        await MainActor.run {
                            closeLoadingOverlay()
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

            if let activeEvent {
                await setProgressHeaderKey("Shared.LoadingHeader.Download")

                await setProgressTextKey("Shared.LoadingText.DownloadTextDatabase")
                await database.downloadTextDatabase(for: activeEvent, authToken: token)

                await setProgressTextKey("Shared.LoadingText.DownloadImageDatabase")
                await database.downloadImageDatabase(for: activeEvent, authToken: token)
            }
        }

        await setProgressTextKey("Shared.LoadingText.Database")
        database.connect()

        if !UserDefaults.standard.bool(forKey: databasesInitializedKey) {
            await setProgressHeaderKey("Shared.LoadingHeader.Initial")

            let actor = DataConverter(modelContainer: sharedModelContainer)

            await actor.disableAutoSave()
            await actor.deleteAll()

            await setProgressTextKey("Shared.LoadingText.Events")
            await actor.loadEvents(from: database.textDatabase)

            await setProgressTextKey("Shared.LoadingText.Maps")
            await actor.loadMaps(from: database.textDatabase)
            await actor.loadLayouts(from: database.textDatabase)

            await setProgressTextKey("Shared.LoadingText.Genres")
            await actor.loadGenres(from: database.textDatabase)

            await setProgressTextKey("Shared.LoadingText.Circles")
            await actor.loadCircles(from: database.textDatabase)

            await actor.save()
            await actor.enableAutoSave()

            UserDefaults.standard.set(true, forKey: databasesInitializedKey)
        } else {
            debugPrint("Skipped loading database into persistent model cache")
        }

        await setProgressTextKey("Shared.LoadingText.Images")
        database.imageCache.removeAll()
        database.loadCommonImages()
        database.loadCircleImages()

        database.disconnect()

        UIApplication.shared.isIdleTimerDisabled = false
    }

    func loadFavorites() async {
        await makeLoadingNonModal()
        await setProgressHeaderKey("Shared.LoadingHeader.Favorites")
        await setProgressTextKey("Shared.LoadingText.Favorites")
        if let token = authManager.token {
            let actor = FavoritesActor()
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }

    func makeLoadingNonModal() async {
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                isLoadingModal = false
            }
        }
        try? await Task.sleep(nanoseconds: 20000000)
    }

    func setProgressHeaderKey(_ progressHeaderKey: String?) async {
        await MainActor.run {
            progressHeaderText = progressHeaderKey
        }
        try? await Task.sleep(nanoseconds: 20000000)
    }

    func setProgressTextKey(_ progressTextKey: String) async {
        await MainActor.run {
            database.progressTextKey = progressTextKey
        }
        try? await Task.sleep(nanoseconds: 20000000)
    }

    func closeLoadingOverlay() {
        withAnimation(.smooth.speed(2.0)) {
            self.database.isBusy = false
            progressHeaderText = nil
            database.progressTextKey = nil
        } completion: {
            isLoadingModal = true
        }
    }
}
