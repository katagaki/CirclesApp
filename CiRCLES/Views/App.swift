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
                .onOpenURL { url in
                    debugPrint("URL scheme invoked: \(url)")
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                        if let queryItems = components.queryItems {
                            var parameters: [String: String] = [:]
                            for item in queryItems {
                                if let value = item.value {
                                    parameters[item.name] = value
                                    debugPrint("\(item.name)  :  \(value)")
                                }
                            }
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
