//
//  Database.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import SQLite

import UIKit
import ZIPFoundation

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

    func isDownloaded(for event: WebCatalogEvent.Response.Event) -> Bool {
        if let documentsDirectoryURL {
            let textDatabaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number).db")
            let imageDatabaseURL = documentsDirectoryURL.appending(path: "webcatalog\(event.number)Image1.db")
            return FileManager.default.fileExists(atPath: textDatabaseURL.path(percentEncoded: false)) &&
                   FileManager.default.fileExists(atPath: imageDatabaseURL.path(percentEncoded: false))
        }
        return false
    }

    // MARK: Loading

    func loadCommonImages() {
        if let imageDatabase {
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
        if let imageDatabase {
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

    // MARK: Persistent Identifier Fetches

    func layouts(_ identifiers: [Int]) -> [ComiketLayout] {
        if let textDatabase {
            do {
                let table = Table("ComiketLayoutWC")
                let id = Expression<Int>("id")
                let query = table.filter(identifiers.contains(id))
                return try textDatabase.prepare(query).map { ComiketLayout(from: $0) }
                    .sorted(by: { $0.mapID < $1.mapID })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func blocks(_ identifiers: [Int]) -> [ComiketBlock] {
        if let textDatabase {
            do {
                let table = Table("ComiketBlockWC")
                let id = Expression<Int>("id")
                let query = table.filter(identifiers.contains(id))
                return try textDatabase.prepare(query).map { ComiketBlock(from: $0) }
                    .sorted(by: { $0.id < $1.id })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func circles(_ identifiers: [Int], reversed: Bool = false) -> [ComiketCircle] {
        if let textDatabase {
            do {
                let circlesTable = Table("ComiketCircleWC")
                let circleExtendedInformationTable = Table("ComiketCircleExtend")
                let id = Expression<Int>("id")

                let joinedTable = circlesTable.join(
                    .leftOuter,
                    circleExtendedInformationTable,
                    on: circlesTable[id] == circleExtendedInformationTable[id]
                )

                let query = joinedTable.filter(identifiers.contains(circlesTable[id]))
                let circles = try textDatabase.prepare(query).map { row in
                    let circle = ComiketCircle(from: row)
                    let extendedInformation = ComiketCircleExtendedInformation(from: row)
                    circle.extendedInformation = extendedInformation
                    return circle
                }

                if reversed {
                    return circles.sorted(by: { $0.id > $1.id })
                } else {
                    return circles.sorted(by: { $0.id < $1.id })
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func allGenres() -> [ComiketGenre] {
        if let textDatabase {
            do {
                let table = Table("ComiketGenreWC")
                return try textDatabase.prepare(table).map { ComiketGenre(from: $0) }
                    .sorted(by: { $0.id < $1.id })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func allBlocks() -> [ComiketBlock] {
        if let textDatabase {
            do {
                let table = Table("ComiketBlockWC")
                return try textDatabase.prepare(table).map { ComiketBlock(from: $0) }
                    .sorted(by: { $0.id < $1.id })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func allDates() -> [ComiketDate] {
        if let textDatabase {
            do {
                let table = Table("ComiketDateWC")
                return try textDatabase.prepare(table).map { ComiketDate(from: $0) }
                    .sorted(by: { $0.id < $1.id })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func allMaps() -> [ComiketMap] {
        if let textDatabase {
            do {
                let table = Table("ComiketMapWC")
                return try textDatabase.prepare(table).map { ComiketMap(from: $0) }
                    .sorted(by: { $0.id < $1.id })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func allEvents() -> [ComiketEvent] {
        if let textDatabase {
            do {
                let table = Table("ComiketInfoWC")
                return try textDatabase.prepare(table).map { ComiketEvent(from: $0) }
                    .sorted(by: { $0.eventNumber < $1.eventNumber })
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
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
