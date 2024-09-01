//
//  App.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI
import SwiftData

@main
struct CirclesApp: App {

    @StateObject var navigationManager = NavigationManager()
    @State var authManager = AuthManager()
    @State var favorites = FavoritesManager()
    @State var database = DatabaseManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    debugPrint("URL scheme invoked: \(url)")
                    authManager.getAuthenticationCode(from: url)
                }
                .onChange(of: authManager.code) { _, newValue in
                    if newValue != nil {
                        Task {
                            await authManager.getAuthenticationToken()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(navigationManager)
        .environment(authManager)
        .environment(favorites)
        .environment(database)
        .onChange(of: navigationManager.selectedTab) { _, _ in
            navigationManager.saveToDefaults()
        }
    }
}
