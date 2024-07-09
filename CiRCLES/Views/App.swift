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
    
    @State var authManager = AuthManager()

    // TODO: Move model container to shared space
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(authManager)
                .onOpenURL { url in
                    debugPrint("URL scheme invoked: \(url)")
                    authManager.completeAuthentication(from: url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
