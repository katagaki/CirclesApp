import Foundation
import SQLite

extension DataFetcher {

    /// Circles in text read from an image, such as a screenshot of a post on X.
    func circles(seenIn lines: [RecognizedLine]) -> [Int] {
        let knownBlocks = blockNames()
        let found: (String) -> [CirclePlacement] = {
            CirclePlacement.placements(in: $0, knownBlocks: knownBlocks)
        }
        var placements = found(lines.map(\.text).joined(separator: "\n"))
        for line in lines where found(line.text).isEmpty {
            for alternative in line.alternatives {
                placements.append(contentsOf: found(alternative))
            }
        }
        var seenPlacements = Set<CirclePlacement>()
        var seen = Set<Int>()
        return placements
            .filter { seenPlacements.insert($0).inserted }
            .flatMap { circles(at: $0) }
            .filter { seen.insert($0).inserted }
    }

    /// The catalog's block names, half-width and lowercased.
    func blockNames() -> Set<String> {
        guard let database else { return [] }
        let colName = Expression<String>("name")
        guard let rows = try? database.prepare(Table("ComiketBlockWC").select(colName)) else { return [] }
        return Set(rows.map { CirclePlacement.normalize($0[colName]).lowercased() })
    }
}
