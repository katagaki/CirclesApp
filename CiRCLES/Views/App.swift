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

    @StateObject var navigator = Navigator()
    @State var authManager = AuthManager()
    @State var favorites = Favorites()
    @State var database = Database()
    @State var oasis = OasisManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
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
        .environmentObject(navigator)
        .environment(authManager)
        .environment(favorites)
        .environment(database)
        .environment(oasis)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
    }
}
