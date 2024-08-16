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

    func loadCommonImages() async {
        if let imageDatabase {
            debugPrint("Loading common images")
            self.commonImages.removeAll()
            self.commonImages = await withTaskGroup(of: (String, Data).self, returning: [String: Data].self) { group in
                let table = Table("ComiketCommonImage")
                let colName = Expression<String>("name")
                let colImage = Expression<Data>("image")

                var commonImages: [String: Data] = [:]
                do {
                    for row in try imageDatabase.prepare(table) {
                        group.addTask {
                            return (row[colName], row[colImage])
                        }
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                }
                for await result in group {
                    commonImages[result.0] = result.1
                }
                return commonImages
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

    func loadCircleImages(forcefully: Bool = false) async {
        if forcefully || self.circleImages.count == 0 {
            if let imageDatabase {
                debugPrint("Loading circle images")
                self.circleImages.removeAll()
                self.circleImages = await withTaskGroup(of: (Int, Data).self, returning: [Int: Data].self) { group in
                    let table = Table("ComiketCircleImage")
                    let colID = Expression<Int>("id")
                    let colCutImage = Expression<Data>("cutImage")

                    var circleImages: [Int: Data] = [:]
                    do {
                        for row in try imageDatabase.prepare(table) {
                            group.addTask {
                                return (row[colID], row[colCutImage])
                            }
                        }
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                    for await result in group {
                        circleImages[result.0] = result.1
                    }
                    return circleImages
                }
            }
        } else {
            debugPrint("Circle images loaded from cache")
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
