//
//  Database+Download.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/02/01.
//

import UIKit
import ZIPFoundation

extension Database {

    func downloadTextDatabase(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        updateProgress: @escaping (Double?) async -> Void
    ) async {
        self.textDatabaseURL = await download(
            for: event, of: .text, authToken: authToken, updateProgress: updateProgress
        )
    }

    func downloadImageDatabase(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        updateProgress: @escaping (Double?) async -> Void
    ) async {
        self.imageDatabaseURL = await download(
            for: event, of: .images, authToken: authToken, updateProgress: updateProgress
        )
    }

    // swiftlint:disable cyclomatic_complexity
    func download(
        for event: WebCatalogEvent.Response.Event,
        of type: DatabaseType,
        authToken: OpenIDToken,
        updateProgress: @escaping (Double?) async -> Void
    ) async -> URL? {
        var databaseNameSuffix: String = ""
        switch type {
        case .text: break
        case .images: databaseNameSuffix = "Image1"
        }

        if let dataStoreURL {
            let databaseURL = dataStoreURL.appending(path: "webcatalog\(event.number)\(databaseNameSuffix).db")
#if DEBUG
            debugPrint(databaseURL)
#endif
            if FileManager.default.fileExists(atPath: databaseURL.path(percentEncoded: false)) {
                return databaseURL
            } else {
                if !FileManager.default.fileExists(atPath: dataStoreURL.path()) {
                    try? FileManager.default.createDirectory(
                        at: dataStoreURL, withIntermediateDirectories: false
                    )
                }
            }
        }

        var downloadedDatabaseURL: URL?
        var request = urlRequestForWebCatalogAPI("All", authToken: authToken)
        let parameters: [String: String] = ["event_id": String(event.id), "event_no": String(event.number)]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            if let databaseInformation = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) {
                self.databaseInformation = databaseInformation
            }
        }

        if let databaseInformation = self.databaseInformation {
            switch type {
            case .text: downloadedDatabaseURL = databaseInformation.response.databaseForText()
            case .images: downloadedDatabaseURL = databaseInformation.response.databaseFor211By300Images()
            }
        }

        let databaseZippedURL = await download(downloadedDatabaseURL, updateProgress: updateProgress)
        await updateProgress(nil)

        if let databaseZippedURL {
            return unzip(databaseZippedURL)
        }

        return nil
    }
    // swiftlint:enable cyclomatic_complexity

    func isDownloaded(for event: WebCatalogEvent.Response.Event) -> Bool {
        if let dataStoreURL {
            let textDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number).db")
            let imageDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number)Image1.db")
            return FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false)) &&
            FileManager.default.fileExists(atPath: imageDatabaseURL.path(percentEncoded: false))
        }
        return false
    }

    func download(_ url: URL?, updateProgress: @escaping (Double?) async -> Void) async -> URL? {
        if let url = url, let dataStoreURL {
            do {
                let downloader: Downloader = Downloader()
                return try await downloader.download(from: url, to: dataStoreURL) { progress in
                    await updateProgress(progress)
                }
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    func unzip(_ url: URL?) -> URL? {
        if let url, let dataStoreURL {
            do {
                let unzipDestinationURL = dataStoreURL
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

    func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/CatalogBase/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }

}
