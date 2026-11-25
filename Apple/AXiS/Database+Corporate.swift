import Foundation
import RADiUS
import SQLite
import UIKit

extension Database {

    public var hasCorporateData: Bool {
        _ = corporateLoadCount
        return corporateDatabaseURL != nil
    }

    // MARK: Download

    public func corporateDatabaseInformation(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken
    ) async -> WebCatalogDatabase? {
        var components = URLComponents(
            url: circleMsAPIEndpoint.appending(path: "CatalogBase/Booth/"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "event_id", value: String(event.id)),
            URLQueryItem(name: "event_no", value: String(event.number))
        ]
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url, timeoutInterval: circleMsAPITimeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let information = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data),
              information.response.databaseForCorporateBooths() != nil else {
            return nil
        }
        return information
    }

    @discardableResult
    public func refreshCorporateDatabase(
        for event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        isActiveEvent: Bool = true,
        updateProgress: @escaping (Double?) async -> Void = { _ in }
    ) async -> Bool {
        guard let dataStoreURL,
              let information = await corporateDatabaseInformation(for: event, authToken: authToken),
              let downloadURL = information.response.databaseForCorporateBooths() else {
            return false
        }
        let destinationURL = dataStoreURL.appending(path: Database.corporateDatabaseName(for: event.number))
        let updateDateKey = Database.corporateUpdateDateKey(forEvent: event.number)
        let isPresent = FileManager.default.fileExists(atPath: destinationURL.path(percentEncoded: false))
        if isPresent, UserDefaults.standard.string(forKey: updateDateKey) == information.response.updateDate {
            return false
        }

        let zippedURL = await download(downloadURL, updateProgress: updateProgress)
        await updateProgress(nil)
        if isActiveEvent {
            corporateDatabase = nil
        }
        guard let zippedURL, let unzippedURL = unzip(zippedURL) else { return false }
        if unzippedURL.lastPathComponent != destinationURL.lastPathComponent {
            try? FileManager.default.removeItem(at: destinationURL)
            guard (try? FileManager.default.moveItem(at: unzippedURL, to: destinationURL)) != nil else {
                return false
            }
        }
        UserDefaults.standard.set(information.response.updateDate, forKey: updateDateKey)
        if isActiveEvent {
            corporateDatabaseURL = destinationURL
            clearDecodedImages()
            corporateLoadCount += 1
        }
        return true
    }

    // MARK: Data

    public func corporateBooths() -> [CorporateBooth] {
        guard let database = getCorporateDatabase() else { return [] }
        do {
            let boothNumber = Expression<Int>("boothNo")
            return try database.prepare(Table("ComiketBooth").order(boothNumber.asc)).map {
                CorporateBooth(from: $0)
            }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    public func corporateBooth(_ identifier: Int) -> CorporateBooth? {
        guard let database = getCorporateDatabase() else { return nil }
        let boothID = Expression<Int>("boothId")
        return (try? database.pluck(Table("ComiketBooth").filter(boothID == identifier))).flatMap {
            $0.map { CorporateBooth(from: $0) }
        }
    }

    public func corporateLinks(forBooth identifier: Int) -> [CorporateLink] {
        guard let database = getCorporateDatabase() else { return [] }
        do {
            let boothID = Expression<Int>("boothId")
            let displayOrder = Expression<Int>("displayOrder")
            let query = Table("ComiketBoothLink").filter(boothID == identifier).order(displayOrder.asc)
            return try database.prepare(query).map { CorporateLink(from: $0) }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    public func corporateLayouts(inArea areaName: String) -> [CorporateLayout] {
        guard let database = getCorporateDatabase() else { return [] }
        do {
            let area = Expression<String>("area")
            return try database.prepare(Table("ComiketBoothLayout").filter(area == areaName)).map {
                CorporateLayout(from: $0)
            }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    public func corporateMaps() -> [CorporateMap] {
        guard let database = getCorporateDatabase() else { return [] }
        do {
            let area = Expression<String>("area")
            let columns: [any Expressible] = [
                Expression<Int>("comiketNo"), area, Expression<Int>("scale"),
                Expression<Int>("width"), Expression<Int>("height")
            ]
            return try database.prepare(Table("ComiketBoothMap").select(columns).order(area.asc)).map {
                CorporateMap(from: $0)
            }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    // MARK: Images

    public func cachedCorporateCutImage(for identifier: Int) -> UIImage? {
        cachedDecodedImage("corporate:cut:\(identifier)")
    }

    public func corporateCutImageAsync(for identifier: Int) async -> UIImage? {
        await corporateImageAsync(
            key: "corporate:cut:\(identifier)", table: "ComiketBoothImage",
            filter: Expression<Int>("boothId") == identifier
        )
    }

    public func corporateMapImageAsync(forArea areaName: String) async -> UIImage? {
        await corporateImageAsync(
            key: "corporate:map:\(areaName)", table: "ComiketBoothMap",
            filter: Expression<String>("area") == areaName
        )
    }

    private func corporateImageAsync(key: String, table: String, filter: Expression<Bool>) async -> UIImage? {
        if let cachedImage = cachedDecodedImage(key) {
            return cachedImage
        }
        guard let database = getCorporateDatabase() else { return nil }
        let decoded = await Task.detached(priority: .userInitiated) {
            let image = Expression<Data?>("image")
            guard let row = try? database.pluck(Table(table).select(image).filter(filter)),
                  let data = row[image],
                  let decoded = UIImage(data: data) else {
                return nil as UIImage?
            }
            return decoded.preparingForDisplay() ?? decoded
        }.value
        guard let decoded else { return nil }
        cacheDecodedImage(decoded, key: key, cost: decodedCost(of: decoded))
        return decoded
    }
}
