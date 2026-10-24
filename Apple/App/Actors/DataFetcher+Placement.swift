import Foundation
import SQLite

extension DataFetcher {

    /// Circles at the given placement, the circle named in it first when the text named one.
    func circles(at placement: CirclePlacement) -> [Int] {
        guard let database else { return [] }
        do {
            let blockTable = Table("ComiketBlockWC")
            let colBlockTableID = Expression<Int>("id")
            let colBlockName = Expression<String>("name")
            let blockIDs = try database.prepare(
                blockTable.select(colBlockTableID)
                    .filter(placement.blockNameCandidates().contains(colBlockName))
            ).map { $0[colBlockTableID] }

            var identifiers: [Int] = []
            if !blockIDs.isEmpty {
                let table = Table("ComiketCircleWC")
                let colID = Expression<Int>("id")
                let colBlockID = Expression<Int>("blockId")
                let colSpaceNumber = Expression<Int>("spaceNo")
                let colSpaceNumberSuffix = Expression<Int>("spaceNoSub")
                let colDay = Expression<Int>("day")
                let colCircleName = Expression<String>("circleName")

                var query = table.select(colID, colSpaceNumberSuffix, colCircleName).filter(
                    blockIDs.contains(colBlockID) && colSpaceNumber == placement.spaceNumber
                )
                if let spaceNumberSuffix = placement.spaceNumberSuffix {
                    query = query.filter(colSpaceNumberSuffix == spaceNumberSuffix)
                }
                if let dayID = dayID(for: placement, in: database) {
                    query = query.filter(colDay == dayID)
                }

                let rows = try database.prepare(query)
                    .sorted(by: { $0[colSpaceNumberSuffix] < $1[colSpaceNumberSuffix] })
                let named = rows.filter { row in
                    guard let circleName = placement.circleName else { return false }
                    return Self.namesMatch(row[colCircleName], circleName)
                }
                identifiers = (named + rows).map { $0[colID] }
            }

            // The space can be misread or mistyped, but a name the notice spelled out in full
            // is almost always right, so fall back to it.
            if identifiers.isEmpty, let circleName = placement.circleName {
                identifiers = circles(containing: circleName)
            }

            var seen = Set<Int>()
            return identifiers.filter { seen.insert($0).inserted }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    /// Every circle mentioned in the text, by placement, or by name when the text is short
    /// enough to be one.
    func circles(mentionedIn text: String) -> [Int] {
        let placements = CirclePlacement.placements(in: text)
        if placements.isEmpty {
            let term = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard term.count >= 2, term.count <= 40, !term.contains("\n") else { return [] }
            return circles(containing: term)
        }
        var seen = Set<Int>()
        return placements.flatMap { circles(at: $0) }.filter { seen.insert($0).inserted }
    }

    /// Enough of each circle to describe it outside the app, in the order asked for.
    func circleSummaries(_ identifiers: [Int]) -> [CircleSummary] {
        guard let database, !identifiers.isEmpty else { return [] }
        do {
            let circlesTable = Table("ComiketCircleWC")
            let blocksTable = Table("ComiketBlockWC")
            let colID = Expression<Int>("id")
            let colBlockID = Expression<Int>("blockId")
            let colDay = Expression<Int>("day")
            let colSpaceNumber = Expression<Int>("spaceNo")
            let colSpaceNumberSuffix = Expression<Int>("spaceNoSub")
            let colCircleName = Expression<String>("circleName")
            let colPenName = Expression<String>("penName")
            let colBlockName = Expression<String>("name")

            let query = circlesTable
                .join(.leftOuter, blocksTable, on: circlesTable[colBlockID] == blocksTable[colID])
                .select(circlesTable[colID], circlesTable[colDay], circlesTable[colSpaceNumber],
                        circlesTable[colSpaceNumberSuffix], circlesTable[colCircleName],
                        circlesTable[colPenName], blocksTable[colBlockName])
                .filter(identifiers.contains(circlesTable[colID]))
            let summaries = try database.prepare(query).map { row in
                CircleSummary(
                    id: row[circlesTable[colID]],
                    name: row[circlesTable[colCircleName]],
                    penName: row[circlesTable[colPenName]],
                    day: row[circlesTable[colDay]],
                    blockName: (try? row.get(blocksTable[colBlockName])) ?? "",
                    spaceNumber: row[circlesTable[colSpaceNumber]],
                    spaceNumberSuffix: row[circlesTable[colSpaceNumberSuffix]]
                )
            }
            let byID = Dictionary(summaries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            return identifiers.compactMap { byID[$0] }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    private func dayID(for placement: CirclePlacement, in database: Connection) -> Int? {
        let table = Table("ComiketDateWC")
        let colID = Expression<Int>("id")
        let colYear = Expression<Int>("year")
        let colMonth = Expression<Int>("month")
        let colDay = Expression<Int>("day")
        guard let rows = try? Array(database.prepare(table.order(colID.asc))) else { return nil }
        if let dayNumber = placement.dayNumber {
            return rows.indices.contains(dayNumber - 1) ? rows[dayNumber - 1][colID] : nil
        }
        guard let weekday = placement.weekday else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return rows.first(where: { row in
            let components = DateComponents(year: row[colYear], month: row[colMonth], day: row[colDay])
            guard let date = calendar.date(from: components) else { return false }
            return calendar.component(.weekday, from: date) - 1 == weekday
        })?[colID]
    }

    private static func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        let fold: (String) -> String = {
            CirclePlacement.normalize($0)
                .folding(options: [.caseInsensitive, .widthInsensitive], locale: nil)
                .filter { !$0.isWhitespace }
        }
        let lhs = fold(lhs)
        let rhs = fold(rhs)
        return !lhs.isEmpty && !rhs.isEmpty && (lhs.contains(rhs) || rhs.contains(lhs))
    }
}

struct CircleSummary: Sendable, Hashable {
    let id: Int
    let name: String
    let penName: String
    let day: Int
    let blockName: String
    let spaceNumber: Int
    let spaceNumberSuffix: Int

    var spaceName: String {
        let suffix = switch spaceNumberSuffix {
        case 0: "a"
        case 1: "b"
        default: ""
        }
        return "\(blockName)\(String(format: "%02d", spaceNumber))\(suffix)"
    }
}
