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

    @ObservationIgnored let databasesInitializedKey: String = "Database.Initialized"

    @ObservationIgnored var textDatabaseURL: URL?
    @ObservationIgnored var imageDatabaseURL: URL?

    @ObservationIgnored var textDatabase: Connection?
    @ObservationIgnored var imageDatabase: Connection?

    var isBusy: Bool = false
    var progressTextKey: String?

    var isDownloading: Bool = false
    var downloadProgress: Double = .zero

    var commonImages: [String: Data] = [:]
    var circleImages: [Int: Data] = [:]

    var actor: DatabaseActor = DatabaseActor(modelContainer: sharedModelContainer)

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

    func deleteAllData() async {
        debugPrint("Deleting all data")
        await actor.deleteAllData()
    }
}
