import Foundation

extension DataFetcher {

    /// Circles in text read from an image, such as a screenshot of a post on X.
    func circles(seenIn lines: [RecognizedLine]) -> [Int] {
        var placements = CirclePlacement.placements(in: lines.map(\.text).joined(separator: "\n"))
        for line in lines where CirclePlacement.placements(in: line.text).isEmpty {
            for alternative in line.alternatives {
                placements.append(contentsOf: CirclePlacement.placements(in: alternative))
            }
        }
        var seenPlacements = Set<CirclePlacement>()
        var seen = Set<Int>()
        return placements
            .filter { seenPlacements.insert($0).inserted }
            .flatMap { circles(at: $0) }
            .filter { seen.insert($0).inserted }
    }
}
