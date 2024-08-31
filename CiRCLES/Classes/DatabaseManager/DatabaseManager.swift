//
//  DatabaseManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import SQLite
import SwiftData
import UIKit

@Observable
class DatabaseManager {

    @ObservationIgnored let documentsDirectoryURL: URL?
    @ObservationIgnored var modelContext: ModelContext

    let databasesInitializedKey: String = "Database.Initialized"

    var textDatabaseURL: URL?
    var imageDatabaseURL: URL?

    var textDatabase: Connection?
    var imageDatabase: Connection?

    var isBusy: Bool = false
    @ObservationIgnored var downloader: Downloader = Downloader()
    var downloadProgressTextKey: String?
    var downloadProgress: Double?

    var commonImages: [String: Data] = [:]
    var circleImages: [Int: Data] = [:]

    @MainActor
    init() {
        documentsDirectoryURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        modelContext = sharedModelContainer.mainContext
    }

    func deleteDatabases() {
        if let documentsDirectoryURL {
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
            textDatabaseURL = nil
            imageDatabaseURL = nil
            textDatabase = nil
            imageDatabase = nil
        }
    }

    func deleteAllData() {
        debugPrint("Deleting all data")
        try? modelContext.delete(model: ComiketEvent.self)
        try? modelContext.delete(model: ComiketDate.self)
        try? modelContext.delete(model: ComiketMap.self)
        try? modelContext.delete(model: ComiketArea.self)
        try? modelContext.delete(model: ComiketBlock.self)
        try? modelContext.delete(model: ComiketMapping.self)
        try? modelContext.delete(model: ComiketGenre.self)
        try? modelContext.delete(model: ComiketLayout.self)
        try? modelContext.delete(model: ComiketCircleExtendedInformation.self)
        try? modelContext.delete(model: ComiketCircle.self)
        try? modelContext.save()
    }
}
