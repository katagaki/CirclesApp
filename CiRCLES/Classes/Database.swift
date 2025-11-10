//
//  Database.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import SQLite
import SwiftData
import UIKit
import ZIPFoundation

@Observable
@MainActor
class Database {

    @ObservationIgnored var modelContext: ModelContext

    @ObservationIgnored var databaseInformation: WebCatalogDatabase?
    @ObservationIgnored var textDatabase: Connection?
    @ObservationIgnored var imageDatabase: Connection?
    @ObservationIgnored var textDatabaseURL: URL?
    @ObservationIgnored var imageDatabaseURL: URL?
    var commonImages: [String: Data] = [:]
    var circleImages: [Int: Data] = [:]
    @ObservationIgnored var imageCache: [String: UIImage] = [:]

    init() {
        modelContext = sharedModelContainer.mainContext
    }

    // MARK: Database Connection

    func connect() {
        if let textDatabaseURL {
            textDatabase = try? Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)
        }
        if let imageDatabaseURL {
            imageDatabase = try? Connection(imageDatabaseURL.path(percentEncoded: false), readonly: true)
        }
    }

    func disconnect() {
        textDatabase = nil
        imageDatabase = nil
    }

    // MARK: Database Download

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

        if let documentsDirectoryURL {
            let databaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number)\(databaseNameSuffix).db")
            #if DEBUG
            debugPrint(databaseURL)
            #endif
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
        let parameters: [String: String] = ["event_id": String(event.id), "event_no": String(event.number)]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        if self.databaseInformation == nil {
            if let (data, _) = try? await URLSession.shared.data(for: request) {
                if let databaseInformation = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) {
                    self.databaseInformation = databaseInformation
                }
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

    func delete() {
        if let documentsDirectoryURL {
            textDatabaseURL = nil
            imageDatabaseURL = nil
            textDatabase = nil
            imageDatabase = nil
            imageCache.removeAll()
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
        }
    }

    // MARK: Loading

    func loadCommonImages() {
        // Load all common image DATA into memory (fast, no UIImage decoding)
        if let imageDatabase {
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
        // Load all circle image DATA into memory (fast, no UIImage decoding)
        // UIImage decoding happens lazily on-demand to reduce startup time
        if let imageDatabase {
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

    // MARK: Persistent Identifier Fetches

    func layouts(_ identifiers: [PersistentIdentifier]) -> [ComiketLayout] {
        return models(identifiers, sortedBy: \ComiketLayout.mapID, in: modelContext)
    }

    func blocks(_ identifiers: [PersistentIdentifier]) -> [ComiketBlock] {
        return models(identifiers, sortedBy: \ComiketBlock.id, in: modelContext)
    }

    func circles(_ identifiers: [PersistentIdentifier]) -> [ComiketCircle] {
        return models(identifiers, sortedBy: \ComiketCircle.id, in: modelContext)
    }

    func models<T, K: Comparable>(
        _ identifiers: [PersistentIdentifier],
        sortedBy keyPath: KeyPath<T, K>,
        in modelContext: ModelContext
    ) -> [T] {
        var models: [T] = []
        for identifier in Set(identifiers) {
            if let model = modelContext.model(for: identifier) as? T {
                models.append(model)
            }
        }
        models.sort(by: {$0[keyPath: keyPath] < $1[keyPath: keyPath]})
        return models
    }

    // MARK: Common Images

    func coverImage() -> UIImage? { commonImage(named: "0001") }
    func blockImage(_ blockID: Int) -> UIImage? { commonImage(named: "B\(blockID)") }
    func jikoCircleCutImage() -> UIImage? { commonImage(named: "JIKO") }

    func mapImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        return commonImage(named: "\(usingHighDefinition ? "LWMP" : "WMP")\(day)\(hall.rawValue)")
    }

    func genreImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        return commonImage(named: "\(usingHighDefinition ? "LWGR" : "WGR")\(day)\(hall.rawValue)")
    }

    // MARK: Circle Images

    func circleImage(for id: Int) -> UIImage? {
        // Check UIImage cache first for instant return
        if let cachedImage = imageCache[String(id)] {
            return cachedImage
        }
        
        // Decode from in-memory data (fast, no SQLite query)
        if let circleImageData = circleImages[id] {
            let circleImage = UIImage(data: circleImageData)
            imageCache[String(id)] = circleImage
            return circleImage
        }
        
        return nil
    }

    func commonImage(named imageName: String) -> UIImage? {
        // Check UIImage cache first for instant return
        if let cachedImage = imageCache[imageName] {
            return cachedImage
        }
        
        // Decode from in-memory data (fast, no SQLite query)
        if let imageData = commonImages[imageName] {
            let image = UIImage(data: imageData)
            imageCache[imageName] = image
            return image
        }
        
        return nil
    }

    // MARK: Others

    func download(_ url: URL?, updateProgress: @escaping (Double?) async -> Void) async -> URL? {
        if let url = url, let documentsDirectoryURL {
            do {
                let downloader: Downloader = Downloader()
                return try await downloader.download(from: url, to: documentsDirectoryURL) { progress in
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
        if let url, let documentsDirectoryURL {
            do {
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

    func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/CatalogBase/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    // MARK: Destructive

    func reset() {
        textDatabaseURL = nil
        imageDatabaseURL = nil
        imageCache.removeAll()
        commonImages.removeAll()
        circleImages.removeAll()
    }
}
