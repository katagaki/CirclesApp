//
//  MainTabView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(FavoritesManager.self) var favorites
    @Environment(DatabaseManager.self) var database

    @State var isInitialTokenRefreshComplete: Bool = false

    @State var isProgressDeterminate: Bool = false

    var body: some View {
        @Bindable var authManager = authManager
        TabView(selection: $navigationManager.selectedTab) {
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
            FavoritesView()
                .tabItem {
                    Label("Tab.Favorites", systemImage: "star.fill")
                }
                .tag(TabType.favorites)
            MoreView()
                .tabItem {
                    Label("Tab.More", systemImage: "ellipsis")
                }
                .tag(TabType.more)
        }
        .overlay {
            if database.isBusy {
                ZStack {
                    Color.clear
                        .ignoresSafeArea()
                    VStack(spacing: 12.0) {
                        if let progressTextKey = database.progressTextKey {
                            Text(NSLocalizedString(progressTextKey, comment: ""))
                                .foregroundStyle(.secondary)
                        }
                        if database.isDownloading {
                            ProgressView(value: database.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                        } else {
                            ProgressView()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Material.ultraThin)
            }
        }
        .sheet(isPresented: $authManager.isAuthenticating) {
            LoginView()
                .interactiveDismissDisabled()
        }
        .task {
            if !isInitialTokenRefreshComplete {
                await authManager.refreshAuthenticationToken()
                isInitialTokenRefreshComplete = true
            }
        }
        .onChange(of: authManager.token) { _, newValue in
            if newValue != nil {
                withAnimation(.snappy.speed(2.0)) {
                    database.isBusy = true
                } completion: {
                    Task.detached {
                        await loadDataFromDatabase()
                        await loadFavorites()
                        await MainActor.run {
                            withAnimation(.snappy.speed(2.0)) {
                                database.isBusy = false
                            }
                        }
                    }
                }
            }
        }
        .onReceive(navigationManager.$selectedTab, perform: { newValue in
            if newValue == navigationManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            navigationManager.previouslySelectedTab = newValue
        })
    }

    func loadDataFromDatabase() async {
        if let token = authManager.token {
            if let eventData = await WebCatalog.events(authToken: token),
                let latestEvent = eventData.list.first(where: {$0.id == eventData.latestEventID}) {
                UIApplication.shared.isIdleTimerDisabled = true

                await database.download(for: latestEvent, authToken: token)

                await setProgressTextKey("Shared.LoadingText.Database")
                database.connect()

                if !database.isInitialLoadCompleted() {
                    let actor = DataConverter(modelContainer: sharedModelContainer)

                    await actor.deleteAllData()

                    await setProgressTextKey("Shared.LoadingText.Events")
                    await actor.loadEvents(from: database.textDatabase)
                    await actor.loadDates(from: database.textDatabase)

                    await setProgressTextKey("Shared.LoadingText.Maps")
                    await actor.loadMaps(from: database.textDatabase)
                    await actor.loadAreas(from: database.textDatabase)
                    await actor.loadBlocks(from: database.textDatabase)
                    await actor.loadMapping(from: database.textDatabase)
                    await actor.loadLayouts(from: database.textDatabase)

                    await setProgressTextKey("Shared.LoadingText.Genres")
                    await actor.loadGenres(from: database.textDatabase)

                    await setProgressTextKey("Shared.LoadingText.Circles")
                    await actor.loadCircles(from: database.textDatabase)

                    await actor.save()

                    database.setInitialLoadCompleted()
                } else {
                    debugPrint("Skipped loading database into persistent model cache")
                }

                await setProgressTextKey("Shared.LoadingText.Images")
                database.loadCommonImages()
                database.loadCircleImages()

                database.disconnect()

                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }

    func loadFavorites() async {
        if let token = authManager.token {
            let actor = FavoritesActor()
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }

    func setProgressTextKey(_ progressTextKey: String) async {
        await MainActor.run {
            database.progressTextKey = progressTextKey
        }
    }
}
