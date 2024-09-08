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

    @ObservationIgnored let documentsDirectoryURL: URL?
    @ObservationIgnored var modelContext: ModelContext

    @ObservationIgnored var databaseInformation: WebCatalogDatabase?
    @ObservationIgnored var textDatabase: Connection?
    @ObservationIgnored var imageDatabase: Connection?
    @ObservationIgnored var textDatabaseURL: URL?
    @ObservationIgnored var imageDatabaseURL: URL?
    var commonImages: [String: Data] = [:]
    var circleImages: [Int: Data] = [:]
    @ObservationIgnored var imageCache: [String: UIImage] = [:]

    var isBusy: Bool = false
    var progressTextKey: String?
    var isDownloading: Bool = false
    var downloadProgress: Double = .zero

    @ObservationIgnored var actor: DataConverter = DataConverter(modelContainer: sharedModelContainer)

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
            debugPrint("Opening text database")
            textDatabase = try? Connection(textDatabaseURL.path(percentEncoded: false), readonly: true)
        }
        if let imageDatabaseURL {
            debugPrint("Opening image database")
            imageDatabase = try? Connection(imageDatabaseURL.path(percentEncoded: false), readonly: true)
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
        if let cachedImage = imageCache[String(id)] {
            return cachedImage
        }
        if let circleImageData = circleImages[id] {
            let circleImage = UIImage(data: circleImageData)
            imageCache[String(id)] = circleImage
            return circleImage
        }
        return nil
    }

    func commonImage(named imageName: String) -> UIImage? {
        if let cachedImage = imageCache[imageName] {
            return cachedImage
        }
        if let imageData = commonImages[imageName] {
            let image = UIImage(data: imageData)
            imageCache[imageName] = image
            return image
        }
        return nil
    }

    // MARK: Others

    func download(_ url: URL?) async -> URL? {
        if let url = url, let documentsDirectoryURL {
            do {
                debugPrint("Downloading \(url.path())")
                let downloader: Downloader = Downloader()
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

    func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/CatalogBase/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
