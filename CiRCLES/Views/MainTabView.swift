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
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(FavoritesManager.self) var favorites
    @Environment(DatabaseManager.self) var database

    @State var isInitialTokenRefreshComplete: Bool = false
    @State var isProgressDeterminate: Bool = false
    @State var progressHeaderText: String?

    var body: some View {
        @Bindable var authManager = authManager
        @Bindable var database = database
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
        .fullScreenCover(isPresented: $database.isBusy) {
            VStack(spacing: 12.0) {
                VStack(spacing: 6.0) {
                    if let progressHeaderText {
                        Text(NSLocalizedString(progressHeaderText, comment: ""))
                            .font(.body)
                            .fontWeight(.bold)
                    }
                    if let progressTextKey = database.progressTextKey {
                        Text(NSLocalizedString(progressTextKey, comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
            .presentationBackground(.black.opacity(0.7))
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
                        self.database.isBusy = false
                        progressHeaderText = nil
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

                await setProgressHeaderKey(nil)

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
}
