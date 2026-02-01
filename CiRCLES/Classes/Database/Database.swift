//
//  Database.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import SQLite

import UIKit

@Observable
@MainActor
class Database {

    @ObservationIgnored var databaseInformation: WebCatalogDatabase?
    @ObservationIgnored var textDatabase: Connection?
    @ObservationIgnored var imageDatabase: Connection?
    @ObservationIgnored var textDatabaseURL: URL?
    @ObservationIgnored var imageDatabaseURL: URL?
    @ObservationIgnored var commonImages: [String: Data] = [:]
    @ObservationIgnored var circleImages: [Int: Data] = [:]
    @ObservationIgnored var imageCache: [String: UIImage] = [:]

    var commonImagesLoadCount: Int = 0
    var circleImagesLoadCount: Int = 0

    init() { }

    // MARK: Database Connection



    func getTextDatabase() -> Connection? {
        if let textDatabaseURL, textDatabase == nil {
            #if DEBUG
            debugPrint("Database: Connecting to text database at \(textDatabaseURL.path(percentEncoded: false))")
            #endif
            textDatabase = try? Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)
        }
        return textDatabase
    }

    func getImageDatabase() -> Connection? {
        if let imageDatabaseURL, imageDatabase == nil {
            #if DEBUG
            debugPrint("Database: Connecting to image database at \(imageDatabaseURL.path(percentEncoded: false))")
            #endif
            imageDatabase = try? Connection(imageDatabaseURL.path(percentEncoded: false), readonly: true)
        }
        return imageDatabase
    }

    func disconnect() {
        #if DEBUG
        debugPrint("Database: Disconnecting...")
        #endif
        textDatabase = nil
        imageDatabase = nil
    }

    func prepare(for event: WebCatalogEvent.Response.Event) {
        disconnect()
        #if DEBUG
        debugPrint("Database: Preparing for event \(event.number)...")
        #endif
        if let documentsDirectoryURL {
            let textDatabaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number).db")
            if FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false)) {
                #if DEBUG
                debugPrint("Database: Found text database.")
                #endif
                self.textDatabaseURL = textDatabaseURL
            }
            let imageDatabaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number)Image1.db")
            if FileManager.default.fileExists(atPath: imageDatabaseURL.path(percentEncoded: false)) {
                #if DEBUG
                debugPrint("Database: Found image database.")
                #endif
                self.imageDatabaseURL = imageDatabaseURL
            }
        }
    }

    func delete() {
        if let documentsDirectoryURL {
            textDatabaseURL = nil
            imageDatabaseURL = nil
            databaseInformation = nil
            textDatabase = nil
            imageDatabase = nil
            commonImages.removeAll()
            circleImages.removeAll()
            imageCache.removeAll()
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
        }
    }

    func reset() {
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

    func loadCommonImages() {
        if let imageDatabase = getImageDatabase() {
            do {
                let colName = Expression<String>("name")
                let colImage = Expression<Data>("image")
                let table = Table("ComiketCommonImage").select(colName, colImage)
                let commonImages: [String: Data] = try imageDatabase.prepare(table).reduce(
                    into: [:]
                ) { partialResult, row in
                    partialResult[row[colName]] = row[colImage]
                }
                self.commonImages = commonImages
                self.commonImagesLoadCount += 1
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadCircleImages() {
        if let imageDatabase = getImageDatabase() {
            do {
                let colID = Expression<Int>("id")
                let colCutImage = Expression<Data>("cutImage")
                let table = Table("ComiketCircleImage").select(colID, colCutImage)
                let circleImages: [Int: Data] = try imageDatabase.prepare(table).reduce(
                    into: [:]
                ) { partialResult, row in
                    partialResult[row[colID]] = row[colCutImage]
                }
                self.circleImages = circleImages
                self.circleImagesLoadCount += 1
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
}
