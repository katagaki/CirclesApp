//
//  SwiftData.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import SwiftData

let sharedModelContainer: ModelContainer = {
    let schema = Schema([])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
