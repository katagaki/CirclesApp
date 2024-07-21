//
//  DatabaseManager+ImageDB.swift
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
            do {
                debugPrint("Loading common images")
                let table = Table("ComiketCommonImage")
                let colName = Expression<String>("name")
                let colImage = Expression<Data>("image")
                self.commonImages.removeAll()
                for row in try imageDatabase.prepare(table) {
                    self.commonImages[row[colName]] = UIImage(data: row[colImage])
                }
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
        var mapImageName = "\(mapImageNamePrefix)\(day)\(hall.rawValue)"
        return image(named: mapImageName)
    }

    func genreImage(for hall: ComiketHall, on day: Int, usingHighDefinition: Bool) -> UIImage? {
        let genreImageNamePrefix = usingHighDefinition ? "LWGR" : "WGR"
        var genreImageName = "\(genreImageNamePrefix)\(day)\(hall.rawValue)"
        return image(named: genreImageName)
    }

    // MARK: Circle Images

    func loadCircleImages(forcefully: Bool = false) {
        if forcefully || self.circleImages.count == 0 {
            if let imageDatabase {
                do {
                    debugPrint("Loading circle images")
                    let table = Table("ComiketCircleImage")
                    let colID = Expression<Int>("id")
                    // let colWebCatalogID = Expression<String>("WCId")
                    let colCutImage = Expression<Data>("cutImage")
                    self.circleImages.removeAll()
                    for row in try imageDatabase.prepare(table) {
                        self.circleImages[row[colID]] = UIImage(data: row[colCutImage])
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
        } else {
            debugPrint("Circle images loaded from cache")
        }
    }

    func circleImage(for id: Int) -> UIImage? { return circleImages[id] }

    // MARK: Shared

    func image(named imageName: String) -> UIImage? {
        if let image = commonImages[imageName] {
            return image
        }
        return nil
    }
}
