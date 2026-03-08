//
//  Database.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import RADiUS
import SQLite

import UIKit

@Observable
@MainActor
public class Database {

    @ObservationIgnored public var databaseInformation: WebCatalogDatabase?
    @ObservationIgnored public var textDatabase: Connection?
    @ObservationIgnored public var imageDatabase: Connection?
    @ObservationIgnored public var textDatabaseURL: URL?
    @ObservationIgnored public var imageDatabaseURL: URL?
    @ObservationIgnored public var commonImages: [String: Data] = [:]
    @ObservationIgnored public var circleImages: [Int: Data] = [:]
    @ObservationIgnored public var imageCache: [String: UIImage] = [:]

    public var commonImagesLoadCount: Int = 0
    public var circleImagesLoadCount: Int = 0

    public let dataStoreURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    public static let groupContainerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
    )

    public init() {
        // No initialization required; properties are set lazily or by callers.
    }

    // MARK: Database Connection

    public func getTextDatabase() -> Connection? {
        if let textDatabaseURL, textDatabase == nil {
            #if DEBUG
            debugPrint("Database: Connecting to text database at \(textDatabaseURL.path(percentEncoded: false))")
            #endif
            textDatabase = try? Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)
        }
        return textDatabase
    }

    public func getImageDatabase() -> Connection? {
        if let imageDatabaseURL, imageDatabase == nil {
            #if DEBUG
            debugPrint("Database: Connecting to image database at \(imageDatabaseURL.path(percentEncoded: false))")
            #endif
            imageDatabase = try? Connection(imageDatabaseURL.path(percentEncoded: false), readonly: true)
        }
        return imageDatabase
    }

    public func disconnect() {
        #if DEBUG
        debugPrint("Database: Disconnecting...")
        #endif
        textDatabase = nil
        imageDatabase = nil
    }

    public func prepare(for event: WebCatalogEvent.Response.Event) {
        disconnect()
        #if DEBUG
        debugPrint("Database: Preparing for event \(event.number)...")
        #endif
        if let dataStoreURL {
            let textDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number).db")
            let groupTextDatabaseURL = Database.groupContainerURL?
                .appending(path: "webcatalog\(event.number).db")

            // Migrate from Documents to group container if needed
            if FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false)) {
                migrateTextDatabaseToGroupContainer(textDatabaseURL, eventNumber: event.number)
            }

            // Use group container database if available, fall back to Documents
            if let groupTextDatabaseURL,
               FileManager.default.fileExists(atPath: groupTextDatabaseURL.path(percentEncoded: false)) {
                #if DEBUG
                debugPrint("Database: Found text database in group container.")
                #endif
                self.textDatabaseURL = groupTextDatabaseURL
            } else if FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false)) {
                #if DEBUG
                debugPrint("Database: Found text database.")
                #endif
                self.textDatabaseURL = textDatabaseURL
            }

            let imageDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number)Image1.db")
            if FileManager.default.fileExists(atPath: imageDatabaseURL.path(percentEncoded: false)) {
                #if DEBUG
                debugPrint("Database: Found image database.")
                #endif
                self.imageDatabaseURL = imageDatabaseURL
            }
        }
    }

    private func migrateTextDatabaseToGroupContainer(_ sourceURL: URL, eventNumber: Int) {
        guard let groupContainerURL = Database.groupContainerURL else { return }
        let destinationURL = groupContainerURL.appending(path: "webcatalog\(eventNumber).db")

        do {
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            #if DEBUG
            debugPrint("Database: Migrated text database to group container.")
            #endif
        } catch {
            debugPrint("Database: Failed to migrate to group container: \(error.localizedDescription)")
        }
    }

    public func delete() {
        if let dataStoreURL {
            textDatabaseURL = nil
            imageDatabaseURL = nil
            databaseInformation = nil
            textDatabase = nil
            imageDatabase = nil
            commonImages.removeAll()
            circleImages.removeAll()
            imageCache.removeAll()
            try? FileManager.default.removeItem(at: dataStoreURL)
        }
    }

    public func delete(event: WebCatalogEvent.Response.Event) {
        if let dataStoreURL {
            let targetTextDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number).db")
            let targetImageDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number)Image1.db")
            let groupTextDatabaseURL = Database.groupContainerURL?
                .appending(path: "webcatalog\(event.number).db")

            if textDatabaseURL == targetTextDatabaseURL || textDatabaseURL == groupTextDatabaseURL {
                textDatabase = nil
                textDatabaseURL = nil
                databaseInformation = nil
            }
            if imageDatabaseURL == targetImageDatabaseURL {
                imageDatabase = nil
                imageDatabaseURL = nil
                commonImages.removeAll()
                circleImages.removeAll()
                imageCache.removeAll()
            }

            try? FileManager.default.removeItem(at: targetTextDatabaseURL)
            try? FileManager.default.removeItem(at: targetImageDatabaseURL)
            if let groupTextDatabaseURL {
                try? FileManager.default.removeItem(at: groupTextDatabaseURL)
            }
        }
    }

    public func reset() {
        #if DEBUG
        debugPrint("Database: Resetting...")
        #endif
        textDatabaseURL = nil
        imageDatabaseURL = nil
        textDatabase = nil
        imageDatabase = nil
        imageCache.removeAll()
        commonImages.removeAll()
        circleImages.removeAll()
    }

    // MARK: Loading

    public func loadCommonImages() async {
        guard let imageDatabase = getImageDatabase() else { return }
        let loaded = await Task.detached(priority: .userInitiated) {
            Self.readCommonImages(from: imageDatabase)
        }.value
        if let loaded {
            self.commonImages = loaded
            self.commonImagesLoadCount += 1
        }
    }

    public func loadCircleImages() async {
        guard let imageDatabase = getImageDatabase() else { return }
        let loaded = await Task.detached(priority: .userInitiated) {
            Self.readCircleImages(from: imageDatabase)
        }.value
        if let loaded {
            self.circleImages = loaded
            self.circleImagesLoadCount += 1
        }
    }

    private nonisolated static func readCommonImages(from imageDatabase: Connection) -> [String: Data]? {
        do {
            let colName = Expression<String>("name")
            let colImage = Expression<Data>("image")
            let table = Table("ComiketCommonImage").select(colName, colImage)
            return try imageDatabase.prepare(table).reduce(into: [:]) { partialResult, row in
                partialResult[row[colName]] = row[colImage]
            }
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    private nonisolated static func readCircleImages(from imageDatabase: Connection) -> [Int: Data]? {
        do {
            let colID = Expression<Int>("id")
            let colCutImage = Expression<Data>("cutImage")
            let table = Table("ComiketCircleImage").select(colID, colCutImage)
            return try imageDatabase.prepare(table).reduce(into: [:]) { partialResult, row in
                partialResult[row[colID]] = row[colCutImage]
            }
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}
