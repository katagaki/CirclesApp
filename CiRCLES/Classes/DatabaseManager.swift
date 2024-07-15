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

    @ObservationIgnored let documentsDirectoryURL: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    var textDatabaseURL: URL?
    var imageDatabaseURL: URL?

    var maps: [ComiketMap] = []

    func getComiketMap() {
        if let textDatabaseURL {
            do {
                debugPrint("Opening database")
                let database = try Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)

                debugPrint("Selecting from ComiketMapWC")
                let mapTable = Table("ComiketMapWC")
                let comiketNumber = Expression<Int>("comiketNo")
                let name = Expression<String>("name")

                for map in try database.prepare(mapTable) {
                    maps.append(ComiketMap(
                        comiketNumber: map[comiketNumber], name: map[name]
                    ))
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        // SELECT * FROM ComiketMapWC
    }

    func getDatabases(for event: WebCatalogEvent.Response.Event, authToken: OpenIDToken) async {
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
                self.textDatabaseURL = databases.response.databaseForText()
                self.imageDatabaseURL = databases.response.databaseFor211By300Images()
            }
        }
    }

    func downloadDatabases() async {
        if let textDatabaseZippedURL = await download(textDatabaseURL),
           let imageDatabaseZippedURL = await download(imageDatabaseURL) {
            self.textDatabaseURL = unzip(textDatabaseZippedURL)
            self.imageDatabaseURL = unzip(imageDatabaseZippedURL)
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
