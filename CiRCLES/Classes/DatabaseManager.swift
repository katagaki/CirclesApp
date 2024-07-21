//
//  DatabaseManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import SQLite
import ZIPFoundation

typealias Expression = SQLite.Expression

@Observable
@MainActor
class DatabaseManager {

    @ObservationIgnored let documentsDirectoryURL: URL? = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first

    var textDatabaseURL: URL?
    var imageDatabaseURL: URL?

    var database: Connection?

    var events: [ComiketEvent] = []
    var eventDates: [ComiketDate] = []
    var eventMaps: [ComiketMap] = []
    var eventAreas: [ComiketArea] = []

    // MARK: SQLite Database Operations

    func loadDatabase() {
        if let textDatabaseURL {
            do {
                debugPrint("Opening database")
                database = try Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadEvents() {
        if let events = loadTable("ComiketInfoWC", of: ComiketEvent.self) as? [ComiketEvent] {
            self.events = events
        }
    }

    func loadDates() {
        if let eventDates = loadTable("ComiketDateWC", of: ComiketDate.self) as? [ComiketDate] {
            self.eventDates = eventDates
        }
    }

    func loadMaps() {
        if let eventMaps = loadTable("ComiketMapWC", of: ComiketMap.self) as? [ComiketMap] {
            self.eventMaps = eventMaps
        }
    }

    func loadAreas() {
        if let eventAreas = loadTable("ComiketAreaWC", of: ComiketArea.self) as? [ComiketArea] {
            self.eventAreas = eventAreas
        }
    }

    func loadTable<T: SQLiteable>(_ tableName: String, of type: T.Type) -> [SQLiteable]? {
        if let database {
            do {
                debugPrint("Selecting from \(tableName)")
                let table = Table("\(tableName)")
                var loadedRows: [SQLiteable] = []
                for row in try database.prepare(table) {
                    loadedRows.append(T(from: row))
                }
                return loadedRows
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    // MARK: API Operations

    func downloadDatabases(for event: WebCatalogEvent.Response.Event, authToken: OpenIDToken) async {
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

        // Unzip databases
        if let textDatabaseZippedURL = await download(textDatabaseURL),
           let imageDatabaseZippedURL = await download(imageDatabaseURL) {
            self.textDatabaseURL = unzip(textDatabaseZippedURL)
            self.imageDatabaseURL = unzip(imageDatabaseZippedURL)
        }
    }

    func deleteDatabases() {
        if let documentsDirectoryURL {
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
            self.textDatabaseURL = nil
            self.imageDatabaseURL = nil
            self.database = nil
            self.events.removeAll()
            self.eventDates.removeAll()
            self.eventMaps.removeAll()
            self.eventAreas.removeAll()
        }
    }

    func unzip(_ url: URL?) -> URL? {
        if let url, let documentsDirectoryURL {
            do {
                debugPrint("Unzipping \(url.path())")
                let unzipDestinationURL = documentsDirectoryURL
                try? FileManager.default.removeItem(at: unzipDestinationURL
                    .appendingPathComponent(url.deletingPathExtension().lastPathComponent))
                try FileManager.default.unzipItem(at: url, to: unzipDestinationURL)
                if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: .utf8) {
                    if let firstFileInArchive = archive.first(where: { _ in return true }) {
                        try? FileManager.default.removeItem(at: url)
                        return unzipDestinationURL.appending(path: firstFileInArchive.path)
                    }
                }
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    func download(_ url: URL?) async -> URL? {
        if let url = url, let documentsDirectoryURL {
            do {
                debugPrint("Downloading \(url.path())")
                let (downloadedFileURL, _) = try await URLSession.shared.download(from: url)

                let saveDestinationURL = documentsDirectoryURL.appending(path: url.lastPathComponent)
                try? FileManager.default.removeItem(at: saveDestinationURL)
                try FileManager.default.moveItem(at: downloadedFileURL, to: saveDestinationURL)
                return saveDestinationURL
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/CatalogBase/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
