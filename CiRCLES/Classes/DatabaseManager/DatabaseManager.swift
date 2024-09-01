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

    @ObservationIgnored var databaseInformation: WebCatalogDatabase?
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

   @ObservationIgnored var imageCache: [String: UIImage] = [:]

    var actor: DataConverter = DataConverter(modelContainer: sharedModelContainer)

    init() {
        documentsDirectoryURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        modelContext = sharedModelContainer.mainContext
    }

    // MARK: Database Connection

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

    // MARK: Database Download

    func downloadTextDatabase(for event: WebCatalogEvent.Response.Event, authToken: OpenIDToken) async {
        self.textDatabaseURL = await download(for: event, of: .text, authToken: authToken)
    }

    func downloadImageDatabase(for event: WebCatalogEvent.Response.Event, authToken: OpenIDToken) async {
        self.imageDatabaseURL = await download(for: event, of: .images, authToken: authToken)
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func download(
        for event: WebCatalogEvent.Response.Event, of type: DatabaseType, authToken: OpenIDToken
    ) async -> URL? {
        var databaseNameSuffix: String = ""
        switch type {
        case .text: break
        case .images: databaseNameSuffix = "Image1"
        }

        if let documentsDirectoryURL {
            let databaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number)\(databaseNameSuffix).db")
            debugPrint(databaseURL)
            if FileManager.default.fileExists(atPath: databaseURL.path(percentEncoded: false)) {
                return databaseURL
            } else {
                if !FileManager.default.fileExists(atPath: documentsDirectoryURL.path()) {
                    try? FileManager.default.createDirectory(
                        at: documentsDirectoryURL, withIntermediateDirectories: false
                    )
                }
            }
        }

        var downloadedDatabaseURL: URL?
        var request = urlRequestForWebCatalogAPI("All", authToken: authToken)
        let parameters: [String: String] = [
            "event_id": String(event.id),
            "event_no": String(event.number)
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        if self.databaseInformation == nil {
            if let (data, _) = try? await URLSession.shared.data(for: request) {
                debugPrint("Web Catalog databases response length: \(data.count)")
                if let databaseInformation = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) {
                    debugPrint("Decoded databases")
                    self.databaseInformation = databaseInformation
                }
            }
        }

        if let databaseInformation = self.databaseInformation {
            switch type {
            case .text:
                downloadedDatabaseURL = databaseInformation.response.databaseForText()
            case .images:
                downloadedDatabaseURL = databaseInformation.response.databaseFor211By300Images()
            }
        }

        self.isDownloading = true
        let databaseZippedURL = await download(downloadedDatabaseURL)
        self.isDownloading = false

        if let databaseZippedURL {
            return unzip(databaseZippedURL)
        }

        return nil
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func delete() {
        if let documentsDirectoryURL {
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
            textDatabaseURL = nil
            imageDatabaseURL = nil
            textDatabase = nil
            imageDatabase = nil
        }
    }

    // MARK: Loading

    func loadCommonImages() {
        if let imageDatabase {
            debugPrint("Loading common images")
            do {
                let table = Table("ComiketCommonImage")
                let colName = Expression<String>("name")
                let colImage = Expression<Data>("image")
                var commonImages: [String: Data] = [:]
                for row in try imageDatabase.prepare(table) {
                    commonImages[row[colName]] = row[colImage]
                }
                self.commonImages = commonImages
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadCircleImages() {
        if let imageDatabase {
            debugPrint("Loading circle images")
            do {
                let table = Table("ComiketCircleImage")
                let colID = Expression<Int>("id")
                let colCutImage = Expression<Data>("cutImage")
                var circleImages: [Int: Data] = [:]
                for row in try imageDatabase.prepare(table) {
                    circleImages[row[colID]] = row[colCutImage]
                }
                self.circleImages = circleImages
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func setInitialLoadCompleted() {
        UserDefaults.standard.set(true, forKey: databasesInitializedKey)
    }

    func isInitialLoadCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: databasesInitializedKey)
    }
}
