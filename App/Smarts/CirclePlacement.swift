import Foundation

/// A circle's place in the hall, as written by people rather than by the catalog.
///
/// Placements come from two places: the notice circle.ms sends every circle once the
/// layout is decided, which circles then paste into a post verbatim —
///
///     ◎貴方のサークル「スタジオ猫ぱんち」は、火曜日 東地区 “マ”ブロック－64b(東４ホール) に配置されました。
///
/// — and the shorthand circles write themselves, such as `火曜日 東マ64b` or `2日目 西れ-12ab`.
struct CirclePlacement: Equatable, Hashable, Sendable {

    /// The name of the circle, when the text says it (only the circle.ms notice does).
    let circleName: String?
    /// 0 for Sunday through 6 for Saturday.
    let weekday: Int?
    /// 1 for the first day of the event, 2 for the second, and so on.
    let dayNumber: Int?
    let blockName: String
    let spaceNumber: Int
    /// 0 for a, 1 for b. Nil when the circle has the whole space, or both halves of it.
    let spaceNumberSuffix: Int?

    /// Every placement in the text, in the order they appear, without duplicates.
    static func placements(in text: String) -> [CirclePlacement] {
        let normalized = normalize(text)
        var placements: [CirclePlacement] = []
        var claimedRanges: [Range<String.Index>] = []

        for match in normalized.matches(of: noticePattern) {
            claimedRanges.append(match.range)
            placements.append(CirclePlacement(
                circleName: String(match.output.name).trimmingCharacters(in: .whitespaces),
                weekday: weekdayIndex(match.output.weekday.map(String.init)),
                dayNumber: nil,
                blockName: String(match.output.block).trimmingCharacters(in: .whitespaces),
                spaceNumber: Int(match.output.space) ?? 0,
                spaceNumberSuffix: suffixIndex(match.output.suffix.map(String.init))
            ))
        }

        for match in normalized.matches(of: shorthandPattern)
        where !claimedRanges.contains(where: { $0.overlaps(match.range) }) {
            // Without a hall area and without a/b, a letter followed by a number is far
            // more likely to be something else ("C107", "A4") than a space.
            guard match.output.area != nil || match.output.suffix != nil,
                  let spaceNumber = Int(match.output.space), spaceNumber > 0 else { continue }
            placements.append(CirclePlacement(
                circleName: nil,
                weekday: weekdayIndex(match.output.weekday.map(String.init)),
                dayNumber: match.output.dayNumber.flatMap { Int($0) },
                blockName: String(match.output.block),
                spaceNumber: spaceNumber,
                spaceNumberSuffix: suffixIndex(match.output.suffix.map(String.init))
            ))
        }

        var seen = Set<CirclePlacement>()
        return placements.filter { seen.insert($0).inserted }
    }

    /// Block names as the catalog may store them: as written, and in the other width.
    func blockNameCandidates() -> [String] {
        let fullwidth = String(String.UnicodeScalarView(blockName.unicodeScalars.map {
            (0x21...0x7E).contains(Int($0.value))
                ? Unicode.Scalar(UInt32(Int($0.value) + 0xFEE0)) ?? $0
                : $0
        }))
        return Array(Set([blockName, blockName.uppercased(), blockName.lowercased(),
                          fullwidth, fullwidth.uppercased(), fullwidth.lowercased()]))
    }

    /// How the placement reads in the app, for example `火 マ64b`.
    var displayName: String {
        var parts: [String] = []
        if let weekday {
            parts.append(Self.weekdays[weekday])
        } else if let dayNumber {
            parts.append(String(localized: "Shared.\(dayNumber)th.Day"))
        }
        let suffix = switch spaceNumberSuffix {
        case 0: "a"
        case 1: "b"
        default: ""
        }
        parts.append("\(blockName)\(spaceNumber)\(suffix)")
        return parts.joined(separator: " ")
    }

    // MARK: Patterns

    private static let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    // swiftlint:disable line_length
    /// `貴方のサークル「〇〇」は、〇曜日 〇地区 “〇”ブロック－〇〇(〇〇ホール) に配置されました`
    nonisolated(unsafe) private static let noticePattern = #/サークル[「『](?<name>.+?)[」』]は[、,]?\s*(?:(?<weekday>[日月火水木金土])曜日?)?\s*(?:\S{1,2}?地区)?\s*["“”'‘’「『]?(?<block>[^\s"“”'‘’」』]{1,2}?)["“”'‘’」』]?\s*ブロック\s*[\-－ー―‐−]?\s*(?<space>\d{1,3})\s*(?<suffix>ab|[ab])?/#
        .ignoresCase()

    /// `火曜日 東マ64b`, `2日目 西れ-12ab`, `(土)南a-01a`
    nonisolated(unsafe) private static let shorthandPattern = #/(?:(?:(?<dayNumber>\d)\s*日目|[(（]?(?<weekday>[日月火水木金土])(?:曜日?)?[)）]?)\s*)?(?<area>[東西南北])?\s*(?<block>[\p{Katakana}\p{Hiragana}A-Za-z])\s*[\-－ー―‐−]?\s*(?<space>\d{1,2})(?!\d)\s*(?<suffix>(?:ab|[ab])(?![A-Za-z]))?/#
    // swiftlint:enable line_length

    private static func weekdayIndex(_ weekday: String?) -> Int? {
        guard let weekday else { return nil }
        return weekdays.firstIndex(of: weekday)
    }

    private static func suffixIndex(_ suffix: String?) -> Int? {
        switch suffix?.lowercased() {
        case "a": 0
        case "b": 1
        default: nil
        }
    }

    /// Folds full-width ASCII down to half-width, so `６４ｂ` reads as `64b`.
    static func normalize(_ text: String) -> String {
        String(String.UnicodeScalarView(text.unicodeScalars.map {
            (0xFF01...0xFF5E).contains(Int($0.value))
                ? Unicode.Scalar(UInt32(Int($0.value) - 0xFEE0)) ?? $0
                : $0
        }))
    }
}
