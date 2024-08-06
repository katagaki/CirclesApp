//
//  MainTabView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(EventManager.self) var eventManager
    @Environment(DatabaseManager.self) var database

    @State var isInitialTokenRefreshComplete: Bool = false
    @State var isAuthenticating: Bool = false
    @State var isLoadingDatabase: Bool = false

    @State var progressViewTextKey: String = ""

    var body: some View {
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
            if isLoadingDatabase {
                ZStack {
                    Color.clear
                        .ignoresSafeArea()
                    ProgressView(NSLocalizedString(progressViewTextKey, comment: ""))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Material.ultraThin)
            }
        }
        .sheet(isPresented: $isAuthenticating) {
            LoginView()
                .interactiveDismissDisabled()
        }
        .task {
            if !isInitialTokenRefreshComplete {
                if authManager.token == nil {
                    isAuthenticating = true
                } else {
                    await authManager.refreshAuthenticationToken()
                    isInitialTokenRefreshComplete = true
                }
            }
        }
        .onChange(of: authManager.token) { _, newValue in
            if newValue == nil {
                isAuthenticating = true
            } else {
                Task.detached {
                    await loadDatabase()
                    isAuthenticating = false
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

    func loadDatabase() async {
        withAnimation(.snappy.speed(2.0)) {
            progressViewTextKey = "Shared.LoadingText.Databases"
            isLoadingDatabase = true
        }
        if let token = authManager.token {
            await eventManager.getEvents(authToken: token)
            if let latestEvent = eventManager.latestEvent() {
                await database.downloadDatabases(for: latestEvent, authToken: token)
                await database.loadDatabase()
                await MainActor.run {
                    progressViewTextKey = "Shared.LoadingText.Events"
                }
                await database.loadEvents()
                await database.loadDates()
                await MainActor.run {
                    progressViewTextKey = "Shared.LoadingText.Maps"
                }
                await database.loadMaps()
                await database.loadAreas()
                await database.loadBlocks()
                await MainActor.run {
                    progressViewTextKey = "Shared.LoadingText.Genres"
                }
                await database.loadGenres()
                await database.loadLayouts()
                await MainActor.run {
                    progressViewTextKey = "Shared.LoadingText.Circles"
                }
                await database.loadCircles()
                await database.loadCircleExtendedInformtion()
                await MainActor.run {
                    progressViewTextKey = "Shared.LoadingText.Images"
                }
                await database.loadCommonImages()
                await database.loadCircleImages()
                debugPrint("Database loaded")
            }
        }
        withAnimation(.snappy.speed(2.0)) {
            isLoadingDatabase = false
        }
    }
}
