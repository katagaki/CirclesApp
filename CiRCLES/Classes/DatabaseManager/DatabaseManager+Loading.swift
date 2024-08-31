//
//  DatabaseManager+Loading.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite
import SwiftData

extension DatabaseManager {

    func loadDatabase() {
        downloadProgressTextKey = "Shared.LoadingText.Database"

        if let textDatabaseURL {
            do {
                debugPrint("Opening text database")
                textDatabase = try Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        if let imageDatabaseURL {
            do {
                debugPrint("Opening image database")
                imageDatabase = try Connection(imageDatabaseURL.path(percentEncoded: false), readonly: true)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadAll(forcefully: Bool = false) async {
        if !UserDefaults.standard.bool(forKey: databasesInitializedKey) || forcefully {
            do {
                loadDatabase()
                try modelContext.transaction {
                    loadEvents()
                    loadDates()
                    loadMaps()
                    loadAreas()
                    loadBlocks()
                    loadMapping()
                    loadLayouts()
                    loadGenres()
                    loadCircles()
                }
                try modelContext.save()
            } catch {
                debugPrint(error.localizedDescription)
            }
            UserDefaults.standard.set(true, forKey: databasesInitializedKey)
            debugPrint("Database loaded")
        } else {
            debugPrint("Skipped loading database into persistent model cache")
            loadDatabase()
        }
        // TODO: Cache images
        await loadCommonImages()
        await loadCircleImages()
        downloadProgressTextKey = nil
    }
}
