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

    @State var isAuthenticating: Bool = false

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
            ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
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
        .sheet(isPresented: $isAuthenticating) {
            LoginView()
                .interactiveDismissDisabled()
        }
        .onAppear {
            if authManager.token == nil {
                isAuthenticating = true
            }
        }
        .onChange(of: authManager.token) { _, newValue in
            isAuthenticating = newValue == nil
        }
        .onReceive(navigationManager.$selectedTab, perform: { newValue in
            if newValue == navigationManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            navigationManager.previouslySelectedTab = newValue
        })
    }
}
