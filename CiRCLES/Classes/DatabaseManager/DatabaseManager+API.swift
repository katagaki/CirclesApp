//
//  DatabaseManager+API.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import ZIPFoundation

extension DatabaseManager {

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

        downloadProgressTextKey = "Shared.LoadingText.DatabaseDownload"

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
            self.downloadProgress = nil
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
                return try await downloader.download(from: url, to: documentsDirectoryURL) { progress in
                    self.downloadProgress = progress
                }
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
