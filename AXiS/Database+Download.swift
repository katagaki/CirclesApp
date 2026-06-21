//
//  Database+Download.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2026/02/01.
//

import RADiUS
import SQLite
import UIKit
import ZIPFoundation

extension Database {

    public func downloadTextDatabase(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        updateProgress: @escaping (Double?) async -> Void
    ) async {
        self.textDatabaseURL = await download(
            for: event, of: .text, authToken: authToken, updateProgress: updateProgress
        )
    }

    public func downloadImageDatabase(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        updateProgress: @escaping (Double?) async -> Void
    ) async {
        self.imageDatabaseURL = await download(
            for: event, of: .images, authToken: authToken, updateProgress: updateProgress
        )
    }

    public func download(
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

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let databaseInformation = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) {
            self.databaseInformation = databaseInformation
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

    public func fetchDownloadSizes(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken
    ) async -> Int64? {
        var request = urlRequestForWebCatalogAPI("All", authToken: authToken)
        let parameters: [String: String] = ["event_id": String(event.id), "event_no": String(event.number)]
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let info = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) else {
            return nil
        }

        self.databaseInformation = info

        let urls = [
            info.response.databaseForText(),
            info.response.databaseFor211By300Images()
        ].compactMap { $0 }

        var totalSize: Int64 = 0
        for url in urls {
            var headRequest = URLRequest(url: url, timeoutInterval: circleMsHeadTimeout)
            headRequest.httpMethod = "HEAD"
            if let (_, response) = try? await URLSession.shared.data(for: headRequest),
               let httpResponse = response as? HTTPURLResponse,
               let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let length = Int64(contentLength) {
                totalSize += length
            }
        }

        return totalSize > 0 ? totalSize : nil
    }

    public func isDownloaded(for event: WebCatalogEvent.Response.Event) -> Bool {
        if let dataStoreURL {
            let textDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number).db")
            let groupTextDatabaseURL = Database.groupContainerURL?
                .appending(path: "webcatalog\(event.number).db")
            let imageDatabaseURL = dataStoreURL.appending(path: "webcatalog\(event.number)Image1.db")
            let textExists = FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false))
                || (groupTextDatabaseURL.map {
                    FileManager.default.fileExists(atPath: $0.path(percentEncoded: false))
                } ?? false)
            let imageExists = FileManager.default.fileExists(atPath: imageDatabaseURL.path(percentEncoded: false))
            return textExists && imageExists
        }
        return false
    }

    public func download(_ url: URL?, updateProgress: @escaping (Double?) async -> Void) async -> URL? {
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

    public func unzip(_ url: URL?) -> URL? {
        if let url, let dataStoreURL {
            do {
                let unzipDestinationURL = dataStoreURL
                try? FileManager.default.removeItem(at: unzipDestinationURL
                    .appendingPathComponent(url.deletingPathExtension().lastPathComponent))
                try FileManager.default.unzipItem(at: url, to: unzipDestinationURL)
                if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: .utf8),
                   let firstFileInArchive = archive.first(where: { _ in return true }) {
                    try? FileManager.default.removeItem(at: url)
                    return unzipDestinationURL.appending(path: firstFileInArchive.path)
                }
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    public func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/CatalogBase/\(endpoint)/")!

        var request = URLRequest(url: endpoint, timeoutInterval: circleMsAPITimeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    // MARK: Indexing

    // One-time, idempotent: builds secondary indexes on the hot filter columns and an FTS5 trigram
    // table for circle search. The catalog DB ships without these, so every filter is otherwise a
    // full table scan and search is a triple leading-wildcard LIKE. Runs once per event (gated by a
    // flag) on a background connection so it never blocks the main thread.
    public func prepareIndexes(for event: WebCatalogEvent.Response.Event) async {
        let flagKey = "Database.Indexed.\(event.number)"
        if UserDefaults.standard.bool(forKey: flagKey) { return }
        guard let textDatabaseURL else { return }
        let path = textDatabaseURL.path(percentEncoded: false)
        let didBuild = await Task.detached(priority: .userInitiated) {
            Self.buildIndexes(atPath: path)
        }.value
        if didBuild {
            UserDefaults.standard.set(true, forKey: flagKey)
        }
    }

    private nonisolated static func buildIndexes(atPath path: String) -> Bool {
        guard let database = try? Connection(path, readonly: false) else { return false }
        let indexStatements = [
            "CREATE INDEX IF NOT EXISTS idx_circlewc_block ON ComiketCircleWC(blockId)",
            "CREATE INDEX IF NOT EXISTS idx_circlewc_genre ON ComiketCircleWC(genreId)",
            "CREATE INDEX IF NOT EXISTS idx_circlewc_day ON ComiketCircleWC(day)",
            "CREATE INDEX IF NOT EXISTS idx_circlewc_day_block ON ComiketCircleWC(day, blockId)",
            "CREATE INDEX IF NOT EXISTS idx_extend_wcid ON ComiketCircleExtend(WCId)",
            "CREATE INDEX IF NOT EXISTS idx_mapping_map ON ComiketMappingWC(mapId)",
            "CREATE INDEX IF NOT EXISTS idx_mapping_block ON ComiketMappingWC(blockId)",
            "CREATE INDEX IF NOT EXISTS idx_layout_map ON ComiketLayoutWC(mapId)"
        ]
        // Each statement is isolated so one missing column can't abort the rest.
        for statement in indexStatements {
            try? database.run(statement)
        }

        // FTS5 trigram for substring search. Best-effort: if the tokenizer is unavailable the
        // search path falls back to LIKE, so failure here is non-fatal.
        let rawCount = try? database.scalar(
            "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='CircleSearchFTS'"
        )
        let ftsExists = ((rawCount ?? nil) as? Int64) ?? 0
        if ftsExists == 0 {
            do {
                try database.run(
                    """
                    CREATE VIRTUAL TABLE CircleSearchFTS USING fts5(
                        circleName, circleKana, penName,
                        content='ComiketCircleWC', content_rowid='id', tokenize='trigram'
                    )
                    """
                )
                try database.run(
                    """
                    INSERT INTO CircleSearchFTS(rowid, circleName, circleKana, penName)
                    SELECT id, circleName, circleKana, penName FROM ComiketCircleWC
                    """
                )
            } catch {
                // Leave no half-built table behind: drop it so search cleanly falls back to LIKE.
                try? database.run("DROP TABLE IF EXISTS CircleSearchFTS")
            }
        }
        return true
    }

}
