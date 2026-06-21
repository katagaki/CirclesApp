//
//  Database+Fetchers.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2026/02/01.
//

import SQLite
import UIKit

extension Database {
    // MARK: Text Data

    public func circles(_ identifiers: [Int], reversed: Bool = false) -> [ComiketCircle] {
        if let textDatabase = getTextDatabase() {
            do {
                let circlesTable = Table("ComiketCircleWC")
                let circleExtendedInformationTable = Table("ComiketCircleExtend")
                let id = Expression<Int>("id")

                let joinedTable = circlesTable.join(
                    .leftOuter,
                    circleExtendedInformationTable,
                    on: circlesTable[id] == circleExtendedInformationTable[id]
                )

                // Order in SQL (PK) so we don't sort the hydrated array in Swift on the main actor.
                let query = joinedTable
                    .filter(identifiers.contains(circlesTable[id]))
                    .order(reversed ? circlesTable[id].desc : circlesTable[id].asc)
                let circles = try textDatabase.prepare(query).map { row in
                    let circle = ComiketCircle(from: row)
                    let extendedInformation = ComiketCircleExtendedInformation(from: row)
                    circle.extendedInformation = extendedInformation
                    return circle
                }

                let blockIDs = Set(circles.map { $0.blockID })
                if !blockIDs.isEmpty {
                    let blocksTable = Table("ComiketBlockWC")
                    let blockIDCol = Expression<Int>("id")

                    let blockQuery = blocksTable.filter(blockIDs.contains(blockIDCol))
                    let blocks = try textDatabase.prepare(blockQuery).map { ComiketBlock(from: $0) }
                    let blockDict = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })

                    for circle in circles {
                        circle.block = blockDict[circle.blockID]
                    }
                }

                return circles
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    public func genres() -> [ComiketGenre] {
        if let textDatabase = getTextDatabase() {
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

    public func blocks() -> [ComiketBlock] {
        if let textDatabase = getTextDatabase() {
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

    public func dates() -> [ComiketDate] {
        if let textDatabase = getTextDatabase() {
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

    public func maps() -> [ComiketMap] {
        if let textDatabase = getTextDatabase() {
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

    public func events() -> [ComiketEvent] {
        if let textDatabase = getTextDatabase() {
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

    // MARK: Images

    public func coverImage() -> UIImage? { commonImage(named: "0001") }
    public func blockImage(_ blockID: Int) -> UIImage? { commonImage(named: "B\(blockID)") }
    public func jikoCircleCutImage() -> UIImage? { commonImage(named: "JIKO") }

    public func mapImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        return commonImage(named: "\(usingHighDefinition ? "LWMP" : "WMP")\(day)\(hall.rawValue)")
    }

    public func genreImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        return commonImage(named: "\(usingHighDefinition ? "LWGR" : "WGR")\(day)\(hall.rawValue)")
    }

    public func circleImage(for id: Int) -> UIImage? {
        let key = "circle:\(id)"
        if let cachedImage = cachedDecodedImage(key) {
            return cachedImage
        }
        guard circleImageIDs.contains(id),
              let imageDatabase = getImageDatabase(),
              let circleImageData = Database.readCircleImageData(from: imageDatabase, id: id),
              let circleImage = UIImage(data: circleImageData) else {
            return nil
        }
        cacheDecodedImage(circleImage, key: key, cost: decodedCost(of: circleImage))
        return circleImage
    }

    // Synchronous in-memory cache lookup only (no DB read). Lets cells render an already-decoded
    // cut immediately without spawning a task.
    public func cachedCircleImage(for id: Int) -> UIImage? {
        cachedDecodedImage("circle:\(id)")
    }

    // Off-main variant for list/grid cells: the BLOB read and the (otherwise main-thread, at-draw)
    // decode both happen on a background task so scrolling the catalog stays smooth. Returns cached
    // results instantly on subsequent calls.
    public func circleImageAsync(for id: Int) async -> UIImage? {
        let key = "circle:\(id)"
        if let cachedImage = cachedDecodedImage(key) {
            return cachedImage
        }
        guard circleImageIDs.contains(id), let imageDatabase = getImageDatabase() else {
            return nil
        }
        let decoded = await Task.detached(priority: .userInitiated) {
            guard let data = Database.readCircleImageData(from: imageDatabase, id: id),
                  let image = UIImage(data: data) else {
                return nil as UIImage?
            }
            // Force-decode off the main thread so SwiftUI doesn't decode at draw time.
            return image.preparingForDisplay() ?? image
        }.value
        guard let decoded else { return nil }
        cacheDecodedImage(decoded, key: key, cost: decodedCost(of: decoded))
        return decoded
    }

    public func commonImage(named imageName: String) -> UIImage? {
        let key = "common:\(imageName)"
        if let cachedImage = cachedDecodedImage(key) {
            return cachedImage
        }
        guard commonImageNames.contains(imageName),
              let imageDatabase = getImageDatabase(),
              let imageData = Database.readCommonImageData(from: imageDatabase, name: imageName),
              let image = UIImage(data: imageData) else {
            return nil
        }
        cacheDecodedImage(image, key: key, cost: decodedCost(of: image))
        return image
    }

    private func decodedCost(of image: UIImage) -> Int {
        if let cgImage = image.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        return Int(image.size.width * image.size.height * 4.0)
    }
}
