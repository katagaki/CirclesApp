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
    @State var authenticator = Authenticator()
    @State var favorites = Favorites()
    @State var database = Database()
    @State var imageCache = ImageCache()
    @State var planner = Planner()
    @State var oasis = Oasis()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    if url.absoluteString == circleMsCancelURLSchema {
                        authenticator.isWaitingForAuthenticationCode = false
                    } else {
                        authenticator.getAuthenticationCode(from: url)
                    }
                }
                .onChange(of: authenticator.code) { _, newValue in
                    if newValue != nil {
                        Task {
                            await authenticator.getAuthenticationToken()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(navigator)
        .environment(authenticator)
        .environment(favorites)
        .environment(database)
        .environment(imageCache)
        .environment(planner)
        .environment(oasis)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
    }
}
