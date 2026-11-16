import Foundation
import SQLite

extension DataFetcher {

    /// Circles in text read from an image, such as a screenshot of a post on X, best match first.
    ///
    /// A circle the text both places and names comes first, then circles it only places, then
    /// circles it only names, those named more often and in larger text ahead of the rest.
    func circles(seenIn lines: [RecognizedLine]) -> [Int] {
        var scores: [Int: Double] = [:]
        var order: [Int] = []
        let add: (Int, Double) -> Void = { identifier, score in
            if scores[identifier] == nil {
                order.append(identifier)
            }
            scores[identifier, default: 0] += score
        }

        var placed = Set<Int>()
        for placement in placements(seenIn: lines) {
            for identifier in circles(at: placement) where placed.insert(identifier).inserted {
                add(identifier, Self.placementScore)
            }
        }
        for (identifier, score) in nameScores(seenIn: lines) {
            add(identifier, score)
        }

        // Once the text places a circle, a weak name match is more likely noise than a lead.
        let minimumNameScore = placed.isEmpty ? 0 : Self.minimumNameScore
        let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        return order
            .filter { placed.contains($0) || scores[$0, default: 0] >= minimumNameScore }
            .sorted { lhs, rhs in
                let lhsScore = scores[lhs, default: 0]
                let rhsScore = scores[rhs, default: 0]
                guard lhsScore == rhsScore else { return lhsScore > rhsScore }
                return position[lhs, default: 0] < position[rhs, default: 0]
            }
    }

    /// The catalog's block names, half-width and lowercased.
    func blockNames() -> Set<String> {
        guard let database else { return [] }
        let colName = Expression<String>("name")
        guard let rows = try? database.prepare(Table("ComiketBlockWC").select(colName)) else { return [] }
        return Set(rows.map { CirclePlacement.normalize($0[colName]).lowercased() })
    }

    // MARK: Scoring

    /// Outweighs any number of name matches, so a placement always ranks first.
    private static let placementScore = 1000.0
    /// What a name-only match needs once the text places a circle: more than one line of
    /// small text, such as a passing mention inside a post.
    private static let minimumNameScore = 1.5

    private func placements(seenIn lines: [RecognizedLine]) -> [CirclePlacement] {
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
        var seen = Set<CirclePlacement>()
        return placements.filter { seen.insert($0).inserted }
    }

    /// How strongly the lines name each circle, by its circle name or its pen name.
    ///
    /// Each line naming a circle adds 1, and up to 1 more the larger its text, so a display
    /// name above a post counts for more than a mention in it.
    private func nameScores(seenIn lines: [RecognizedLine]) -> [Int: Double] {
        guard let database, !lines.isEmpty else { return [:] }
        let foldedLines = lines.map { (text: Self.foldedName($0.text), weight: 1 + $0.relativeHeight) }
        let allText = foldedLines.map(\.text).joined(separator: "\n")

        let colID = Expression<Int>("id")
        let colCircleName = Expression<String>("circleName")
        let colPenName = Expression<String>("penName")
        guard let rows = try? database.prepare(
            Table("ComiketCircleWC").select(colID, colCircleName, colPenName)
        ) else { return [:] }

        var scores: [Int: Double] = [:]
        for row in rows {
            var score = 0.0
            for (name, factor) in [(row[colCircleName], 1.0), (row[colPenName], 0.75)] {
                let name = Self.foldedName(name)
                guard Self.isDistinctive(name), allText.contains(name) else { continue }
                for line in foldedLines where Self.line(line.text, names: name) {
                    score += line.weight * factor
                }
            }
            if score > 0 {
                scores[row[colID], default: 0] += score
            }
        }
        return scores
    }

    /// Words every screenshot of a placement notice or of X has, which some names are part of.
    private static let commonText = foldedName(
        "あなたのサークル「」は、コミックマーケットで「曜日地区ブロックホール」に配置されました"
        + "コミケWebカタログにてサークル情報ページ公開中ですよろしくお願いします"
        + "フォローポストする返信件の表示関連性が高い引用リポストいいねブックマーク"
    )

    /// Whether a name is long enough that finding it in a line is unlikely to be chance:
    /// `ました` and `サーク` are in almost every post.
    private static func isDistinctive(_ name: String) -> Bool {
        let isLatin = name.allSatisfy { $0.isASCII }
        let isKana = name.unicodeScalars.allSatisfy { (0x3041...0x30FF).contains(Int($0.value)) }
        return name.count >= (isLatin || isKana ? 4 : 3)
            && name.contains(where: { $0.isLetter })
            && !commonText.contains(name)
    }

    /// Whether a line names the circle: says the name, and for a name in Latin letters, not as
    /// part of a longer word.
    private static func line(_ line: String, names name: String) -> Bool {
        guard name.allSatisfy({ $0.isASCII }) else { return line.contains(name) }
        var searchRange = line.startIndex..<line.endIndex
        while let range = line.range(of: name, range: searchRange) {
            let before = range.lowerBound > line.startIndex ? line[line.index(before: range.lowerBound)] : nil
            let after = range.upperBound < line.endIndex ? line[range.upperBound] : nil
            let isWordCharacter: (Character?) -> Bool = {
                $0.map { $0.isASCII && ($0.isLetter || $0.isNumber) } ?? false
            }
            if !isWordCharacter(before) && !isWordCharacter(after) {
                return true
            }
            searchRange = range.upperBound..<line.endIndex
        }
        return false
    }
}
