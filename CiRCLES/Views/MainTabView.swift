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
            ChecklistsView()
                .tabItem {
                    Label("Tab.Checklists", systemImage: "checklist")
                }
                .tag(TabType.checklists)
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
                    ProgressView("Shared.LoadingText.Databases")
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
                Task {
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
            isLoadingDatabase = true
        }
        if let token = authManager.token {
            await eventManager.getEvents(authToken: token)
            if let latestEvent = eventManager.latestEvent() {
                await database.downloadDatabases(for: latestEvent, authToken: token)
                database.loadDatabase()
                database.loadEvents()
                database.loadDates()
                database.loadMaps()
                database.loadAreas()
                database.loadBlocks()
                database.loadGenres()
                database.loadLayouts()
                database.loadCircles()
                database.loadCircleExtendedInformtion()
                database.loadCommonImages()
                database.loadCircleImages()
                debugPrint("Database loaded")
            }
        }
        withAnimation(.snappy.speed(2.0)) {
            isLoadingDatabase = false
        }
    }
}
