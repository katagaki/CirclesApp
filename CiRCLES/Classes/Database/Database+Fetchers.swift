//
//  Database+Fetchers.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/02/01.
//

import SQLite
import UIKit

extension Database {
    // MARK: Text Data

    func circles(_ identifiers: [Int], reversed: Bool = false) -> [ComiketCircle] {
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

    func genres() -> [ComiketGenre] {
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

    func blocks() -> [ComiketBlock] {
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

    func dates() -> [ComiketDate] {
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

    func maps() -> [ComiketMap] {
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

    func events() -> [ComiketEvent] {
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

    func coverImage() -> UIImage? { commonImage(named: "0001") }
    func blockImage(_ blockID: Int) -> UIImage? { commonImage(named: "B\(blockID)") }
    func jikoCircleCutImage() -> UIImage? { commonImage(named: "JIKO") }

    func mapImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        return commonImage(named: "\(usingHighDefinition ? "LWMP" : "WMP")\(day)\(hall.rawValue)")
    }

    func genreImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        return commonImage(named: "\(usingHighDefinition ? "LWGR" : "WGR")\(day)\(hall.rawValue)")
    }

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
}
