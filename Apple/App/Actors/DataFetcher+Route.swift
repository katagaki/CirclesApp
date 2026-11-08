import Foundation
import SQLite

struct RouteCircle: Sendable {
    let circleID: Int
    let webCatalogID: Int
    let name: String
    let blockName: String
    let spaceNumber: Int
    let spaceNumberSuffix: Int

    var spaceName: String {
        let suffix = switch spaceNumberSuffix {
        case 0: "a"
        case 1: "b"
        case 2: "c"
        default: ""
        }
        return "\(blockName)\(String(format: "%02d", spaceNumber))\(suffix)"
    }
}

extension DataFetcher {

    func routeCircles(withWebCatalogIDs webCatalogIDs: [Int]) -> [Int: RouteCircle] {
        guard let database, !webCatalogIDs.isEmpty else { return [:] }
        do {
            let circlesTable = Table("ComiketCircleWC")
            let extendedTable = Table("ComiketCircleExtend")
            let blocksTable = Table("ComiketBlockWC")
            let colID = Expression<Int>("id")
            let colWebCatalogID = Expression<Int>("WCId")
            let colBlockID = Expression<Int>("blockId")
            let colSpaceNumber = Expression<Int>("spaceNo")
            let colSpaceNumberSuffix = Expression<Int>("spaceNoSub")
            let colCircleName = Expression<String>("circleName")
            let colBlockName = Expression<String>("name")

            let query = circlesTable
                .join(.inner, extendedTable, on: circlesTable[colID] == extendedTable[colID])
                .join(.leftOuter, blocksTable, on: circlesTable[colBlockID] == blocksTable[colID])
                .select(circlesTable[colID], extendedTable[colWebCatalogID], circlesTable[colCircleName],
                        circlesTable[colSpaceNumber], circlesTable[colSpaceNumberSuffix], blocksTable[colBlockName])
                .filter(webCatalogIDs.contains(extendedTable[colWebCatalogID]))
            return try database.prepare(query).reduce(into: [Int: RouteCircle]()) { result, row in
                let circle = RouteCircle(
                    circleID: row[circlesTable[colID]],
                    webCatalogID: row[extendedTable[colWebCatalogID]],
                    name: row[circlesTable[colCircleName]],
                    blockName: (try? row.get(blocksTable[colBlockName])) ?? "",
                    spaceNumber: row[circlesTable[colSpaceNumber]],
                    spaceNumberSuffix: row[circlesTable[colSpaceNumberSuffix]]
                )
                result[circle.webCatalogID] = circle
            }
        } catch {
            debugPrint(error.localizedDescription)
            return [:]
        }
    }
}
