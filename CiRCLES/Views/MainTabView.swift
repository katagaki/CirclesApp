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

    @State var isInitialTokenRefreshComplete: Bool = false
    @State var isProgressDeterminate: Bool = false
    @State var progressHeaderText: String?

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
            FavoritesView()
                .tabItem {
                    Label("Tab.Favorites", systemImage: "star.fill")
                }
                .tag(TabType.favorites)
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
                ZStack {
                    Color.black.opacity(0.7)
                    VStack(spacing: 12.0) {
                        if progressHeaderText != nil || database.progressTextKey != nil {
                            VStack(spacing: 6.0) {
                                if let progressHeaderText {
                                    Text(NSLocalizedString(progressHeaderText, comment: ""))
                                        .fontWeight(.bold)
                                }
                                if let progressTextKey = database.progressTextKey {
                                    Text(NSLocalizedString(progressTextKey, comment: ""))
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if database.isDownloading {
                            ProgressView(value: database.downloadProgress, total: 1.0)
                                .progressViewStyle(.linear)
                        } else {
                            ProgressView()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Material.regular)
                    .clipShape(RoundedRectangle(cornerRadius: 16.0))
                    .padding(32.0)
                }
                .ignoresSafeArea()
                .transition(.opacity.animation(.snappy.speed(2.0)))
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
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        .onChange(of: authManager.token) { _, newValue in
            if newValue != nil {
                self.database.isBusy = true
                Task.detached {
                    await loadDataFromDatabase()
                    await loadFavorites()
                    await MainActor.run {
                        closeLoadingOverlay()
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

    func loadDataFromDatabase() async {
        if let token = authManager.token {
            if let eventData = await WebCatalog.events(authToken: token),
                let latestEvent = eventData.list.first(where: {$0.id == eventData.latestEventID}) {
                UIApplication.shared.isIdleTimerDisabled = true

                await setProgressHeaderKey("Shared.LoadingHeader.Download")

                await setProgressTextKey("Shared.LoadingText.DownloadTextDatabase")
                await database.downloadTextDatabase(for: latestEvent, authToken: token)

                await setProgressTextKey("Shared.LoadingText.DownloadImageDatabase")
                await database.downloadImageDatabase(for: latestEvent, authToken: token)

                await setProgressTextKey("Shared.LoadingText.Database")
                database.connect()

                if !database.isInitialLoadCompleted() {
                    await setProgressHeaderKey("Shared.LoadingHeader.Initial")

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

    func setProgressHeaderKey(_ progressHeaderKey: String?) async {
        await MainActor.run {
            progressHeaderText = progressHeaderKey
        }
    }

    func setProgressTextKey(_ progressTextKey: String) async {
        await MainActor.run {
            database.progressTextKey = progressTextKey
        }
    }

    func closeLoadingOverlay() {
        withAnimation(.snappy.speed(2.0)) {
            self.database.isBusy = false
            progressHeaderText = nil
            database.progressTextKey = nil
        }
    }
}
