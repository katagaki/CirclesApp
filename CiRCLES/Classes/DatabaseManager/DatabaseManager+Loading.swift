//
//  DatabaseManager+Loading.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

extension DatabaseManager {

    func loadDatabase() async {
        downloadProgressTextKey = "Shared.LoadingText.Databases"
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

    func loadAll() async {
        await loadDatabase()
        await loadEvents()
        await loadDates()
        await loadMaps()
        await loadAreas()
        await loadBlocks()
        await loadMapping()
        await loadLayouts()
        await loadGenres()
        await loadCircles()
        await loadCircleExtendedInformtion()
        await loadCommonImages()
        await loadCircleImages()
        downloadProgressTextKey = nil
    }
}
