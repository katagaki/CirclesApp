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
                    VStack {
                        if let progressTextKey = database.downloadProgressTextKey {
                            Text(NSLocalizedString(progressTextKey, comment: ""))
                                .foregroundStyle(.secondary)
                        }
                        if isProgressDeterminate {
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
            if let newValue {
                authManager.isAuthenticating = false
                Task.detached {
                    await loadDatabase()
                    await favorites.getAll(authToken: newValue)
                }
            } else {
                authManager.isAuthenticating = true
            }
        }
        .onChange(of: database.downloadProgress) { _, newValue in
            if newValue != nil {
                isProgressDeterminate = true
            } else {
                isProgressDeterminate = false
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
            database.isBusy = true
        }
        if let token = authManager.token {
            await eventManager.getEvents(authToken: token)
            if let latestEvent = eventManager.latestEvent() {
                UIApplication.shared.isIdleTimerDisabled = true
                await database.downloadDatabases(for: latestEvent, authToken: token)
                await database.loadAll()
                UIApplication.shared.isIdleTimerDisabled = false
                debugPrint("Database loaded")
            }
        }
        withAnimation(.snappy.speed(2.0)) {
            database.isBusy = false
        }
    }
}
