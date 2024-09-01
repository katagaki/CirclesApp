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
@MainActor
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

    init() {
        documentsDirectoryURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        modelContext = sharedModelContainer.mainContext
    }

    func connect() {
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

    func disconnect() {
        textDatabase = nil
        imageDatabase = nil
    }

    func download(for event: WebCatalogEvent.Response.Event, authToken: OpenIDToken) async {
        // Reuse existing database if it exists
        if let documentsDirectoryURL {
            let textDatabaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number).db")
            let imageDatabaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number)Image1.db")
            if FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false)),
               FileManager.default.fileExists(atPath: imageDatabaseURL.path(percentEncoded: false)) {
                self.textDatabaseURL = textDatabaseURL
                self.imageDatabaseURL = imageDatabaseURL
                return
            }
        }

        // Create Documents folder if it doesn't exist
        if let documentsDirectoryURL,
           !FileManager.default.fileExists(atPath: documentsDirectoryURL.path()) {
            try? FileManager.default.createDirectory(at: documentsDirectoryURL, withIntermediateDirectories: false)
        }

        // Download zipped database
        var textDatabaseURL: URL?
        var imageDatabaseURL: URL?
        var request = urlRequestForWebCatalogAPI("All", authToken: authToken)
        let parameters: [String: String] = [
            "event_id": String(event.id),
            "event_no": String(event.number)
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Web Catalog databases response length: \(data.count)")
            if let databases = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) {
                debugPrint("Decoded databases")
                textDatabaseURL = databases.response.databaseForText()
                imageDatabaseURL = databases.response.databaseFor211By300Images()
            }
        }

        // Download databases
        self.isDownloading = true

        progressTextKey = "Shared.LoadingText.DownloadTextDatabase"
        let textDatabaseZippedURL = await download(textDatabaseURL)

        progressTextKey = "Shared.LoadingText.DownloadImageDatabase"
        let imageDatabaseZippedURL = await download(imageDatabaseURL)

        self.isDownloading = false

        // Unzip databases
        if let textDatabaseZippedURL, let imageDatabaseZippedURL {
            self.textDatabaseURL = unzip(textDatabaseZippedURL)
            self.imageDatabaseURL = unzip(imageDatabaseZippedURL)
        }
    }

    func delete() {
        if let documentsDirectoryURL {
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
            textDatabaseURL = nil
            imageDatabaseURL = nil
            textDatabase = nil
            imageDatabase = nil
        }
    }

    func setInitialLoadCompleted() {
        UserDefaults.standard.set(true, forKey: databasesInitializedKey)
    }

    func isInitialLoadCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: databasesInitializedKey)
    }
}
