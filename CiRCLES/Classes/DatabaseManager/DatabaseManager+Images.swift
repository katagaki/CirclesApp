//
//  DatabaseManager+Images.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite
import UIKit

extension DatabaseManager {

    // MARK: Common Images

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

    func coverImage() -> UIImage? { image(named: "0001") }
    func blockImage(_ blockID: Int) -> UIImage? { image(named: "B\(blockID)") }
    func jikoCircleCutImage() -> UIImage? { image(named: "JIKO") }

    func mapImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        let mapImageNamePrefix = usingHighDefinition ? "LWMP" : "WMP"
        let mapImageName = "\(mapImageNamePrefix)\(day)\(hall.rawValue)"
        return image(named: mapImageName)
    }

    func genreImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        let genreImageNamePrefix = usingHighDefinition ? "LWGR" : "WGR"
        let genreImageName = "\(genreImageNamePrefix)\(day)\(hall.rawValue)"
        return image(named: genreImageName)
    }

    // MARK: Circle Images

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

    func circleImage(for id: Int) -> UIImage? {
        if let circleImageData = circleImages[id] {
            return UIImage(data: circleImageData)
        }
        return nil
    }

    // MARK: Shared

    func image(named imageName: String) -> UIImage? {
        if let imageData = commonImages[imageName] {
            return UIImage(data: imageData)
        }
        return nil
    }
}
