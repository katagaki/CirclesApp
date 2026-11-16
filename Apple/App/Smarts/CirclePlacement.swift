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
        unique(placementMatches(in: normalize(text)).map(\.placement))
    }

    /// Every placement in text read from an image, where OCR loses what the text was typed as.
    ///
    /// Look-alike kanji are read back as the block kana they most likely are (`力` as `カ`), and
    /// placements without a hall area or a/b, such as `マ-64`, count when the catalog has the block.
    static func placements(in text: String, knownBlocks: Set<String>) -> [CirclePlacement] {
        let corrected = correctingMisreads(in: normalize(text))
        let matches = placementMatches(in: corrected)
        var placements = matches.map(\.placement)
        let claimedRanges = matches.compactMap(\.range)

        // Without a day or a dash, `あと3日` would read as a placement.
        for match in scan(corrected, for: shorthandPattern, accepting: { match in
            let blockName = String(match.output.block)
            let hasDayPrefix = hasDay(match.output.dayNumber, match.output.weekday)
            let hasDash = match.output.dash != nil
            let end = corrected[match.range].lastIndex(where: { !$0.isWhitespace }).map(corrected.index(after:))
                ?? match.range.upperBound
            let next = end < corrected.endIndex ? corrected[end] : nil
            return (match.output.area != nil || hasDayPrefix || startsWord(match.range, in: corrected))
                && !claimedRanges.contains(where: { $0.overlaps(match.range) })
                && knownBlocks.contains(blockName.lowercased())
                && (Int(match.output.space) ?? 0) > 0
                && !breaksLine(between: match.output.block, and: match.output.space, dash: match.output.dash)
                && !isLatinBlockWithoutMarker(match.output.block, match.output.dash, hasDay: hasDayPrefix)
                && (hasDayPrefix || hasDash || !(next?.isLetter == true || next?.isNumber == true))
        }) {
            placements.append(CirclePlacement(
                circleName: nil,
                weekday: weekdayIndex(match.output.weekday.map(String.init)),
                dayNumber: match.output.dayNumber.flatMap { Int($0) },
                blockName: String(match.output.block),
                spaceNumber: Int(match.output.space) ?? 0,
                spaceNumberSuffix: suffixIndex(match.output.suffix.map(String.init))
            ))
        }
        return unique(placements)
    }

    private static func placementMatches(
        in normalized: String
    ) -> [(placement: CirclePlacement, range: Range<String.Index>?)] {
        var matches: [(placement: CirclePlacement, range: Range<String.Index>?)] = []

        // A notice wraps wherever the screen ends, often inside a word: `コミ` / `ックマーケット`.
        let unwrapped = normalized.replacingOccurrences(of: "\n", with: "")
        for match in unwrapped.matches(of: noticePattern) {
            matches.append((CirclePlacement(
                circleName: match.output.name.map { String($0).trimmingCharacters(in: .whitespaces) },
                weekday: weekdayIndex(match.output.weekday.map(String.init)),
                dayNumber: nil,
                blockName: String(match.output.block).trimmingCharacters(in: .whitespaces),
                spaceNumber: Int(match.output.space) ?? 0,
                spaceNumberSuffix: suffixIndex(match.output.suffix.map(String.init))
            ), nil))
        }

        for match in scan(normalized, for: shorthandPattern, accepting: { match in
            // Without a hall area and without a/b, a letter followed by a number is far
            // more likely to be something else ("C107", "A4") than a space.
            let hasArea = match.output.area != nil
            let hasDayPrefix = hasDay(match.output.dayNumber, match.output.weekday)
            return (hasArea || match.output.suffix != nil)
                && (Int(match.output.space) ?? 0) > 0
                && !breaksLine(between: match.output.block, and: match.output.space, dash: match.output.dash)
                && (hasArea || hasDayPrefix || startsWord(match.range, in: normalized))
                && (hasArea || !isLatinBlockWithoutMarker(match.output.block, match.output.dash, hasDay: hasDayPrefix))
        }) {
            matches.append((CirclePlacement(
                circleName: nil,
                weekday: weekdayIndex(match.output.weekday.map(String.init)),
                dayNumber: match.output.dayNumber.flatMap { Int($0) },
                blockName: String(match.output.block),
                spaceNumber: Int(match.output.space) ?? 0,
                spaceNumberSuffix: suffixIndex(match.output.suffix.map(String.init))
            ), match.range))
        }

        return matches
    }

    /// The matches the caller accepts, trying from every position in turn, so a match it
    /// turns down does not use up text a later one needs: `コミ1` would take the 1 of `1日目`.
    private static func scan<Output>(
        _ text: String, for pattern: Regex<Output>, accepting accept: (Regex<Output>.Match) -> Bool
    ) -> [Regex<Output>.Match] {
        var matches: [Regex<Output>.Match] = []
        var index = text.startIndex
        while index < text.endIndex {
            if !text[index].isWhitespace, let match = try? pattern.prefixMatch(in: text[index...]),
               !match.range.isEmpty, accept(match) {
                matches.append(match)
                index = match.range.upperBound
            } else {
                index = text.index(after: index)
            }
        }
        return matches
    }

    private static func unique(_ placements: [CirclePlacement]) -> [CirclePlacement] {
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

    // MARK: Misreads

    /// Kanji and symbols OCR reads in place of the block kana they look like.
    private static let blockLookalikes: [Character: Character] = [
        "力": "カ", "工": "エ", "夕": "タ", "卜": "ト", "二": "ニ",
        "八": "ハ", "口": "ロ", "千": "チ", "×": "メ"
    ]

    private static let dashes: Set<Character> = ["-", "－", "ー", "―", "‐", "−"]

    /// Puts back the block kana and digits OCR misread, where they sit next to a space number:
    /// `東力-O1` reads as `東カ-01`.
    static func correctingMisreads(in text: String) -> String {
        var characters = Array(text)
        for index in characters.indices {
            let previous = index > characters.startIndex ? characters[index - 1] : nil
            if let kana = blockLookalikes[characters[index]],
               let next = characters[(index + 1)...].first(where: { !$0.isWhitespace && !dashes.contains($0) }),
               next.isASCII && next.isNumber {
                characters[index] = kana
            } else if let digit = digitLookalike(characters[index]) {
                let next = index + 1 < characters.endIndex ? characters[index + 1] : nil
                let followsDigit = previous?.isASCII == true && previous?.isNumber == true
                let followsDash = previous.map { dashes.contains($0) } ?? false
                let precedesDigit = next?.isASCII == true && next?.isNumber == true
                if followsDigit || (followsDash && precedesDigit) {
                    characters[index] = digit
                }
            }
        }
        return String(characters)
    }

    private static func digitLookalike(_ character: Character) -> Character? {
        switch character {
        case "O", "o": "0"
        case "I", "l", "|": "1"
        default: nil
        }
    }

    /// Whether a match that starts with its block letter starts a word rather than ending one,
    /// as `ク-15b` ends `ブロック-15b`. Hiragana may come before it, since particles do: `でナ-37ab`.
    private static func startsWord(_ range: Range<String.Index>, in text: String) -> Bool {
        guard range.lowerBound > text.startIndex else { return true }
        let previous = text[text.index(before: range.lowerBound)]
        let isHiragana = previous.unicodeScalars.allSatisfy { (0x3041...0x309F).contains(Int($0.value)) }
        return !previous.isLetter || isHiragana
    }

    /// Whether a line ends between a block and its number with no dash joining them, as when
    /// `お願いします` ends one line and `12:34` starts the next. A wrapped `ナ` / `ー37ab` counts.
    private static func breaksLine(between block: Substring, and space: Substring, dash: Substring?) -> Bool {
        dash == nil && block.base[block.endIndex..<space.startIndex].contains("\n")
    }

    private static func hasDay(_ dayNumber: Substring?, _ weekday: Substring?) -> Bool {
        dayNumber != nil || weekday != nil
    }

    /// A Latin letter and a number with nothing marking them as a space, such as `A4` or `C99`,
    /// is too often something else.
    private static func isLatinBlockWithoutMarker(_ block: Substring, _ dash: Substring?, hasDay: Bool) -> Bool {
        block.first?.isASCII == true && dash == nil && !hasDay
    }

    // MARK: Patterns

    private static let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    /// `あなたのサークル「〇〇」は、コミックマーケット〇〇で「〇曜日 〇地区 “〇”ブロック－〇〇 (〇〇ホール)」に配置されました`,
    /// and the older `貴方のサークル「〇〇」は、〇曜日 …`, with or without the circle's name.
    nonisolated(unsafe) private static let noticePattern = #/サークル(?:[「『](?<name>[^」』]+?)[」』])?は[、,]?\s*(?:コミックマーケット\s*\d+\s*で\s*)?[「『]?\s*(?:(?<weekday>[日月火水木金土])曜日?)?\s*(?:\S{1,2}?地区)?\s*["“”'‘’「『]?(?<block>[^\s"“”'‘’」』]{1,2}?)["“”'‘’」』]?\s*ブロック\s*[\-－ー―‐−]?\s*(?<space>\d{1,3})\s*(?<suffix>ab|[ab])?/#
        .ignoresCase()

    /// `火曜日 東マ64b`, `2日目 西れ-12ab`, `(土)南a-01a`, `東2ソ23ab`, `東7 “F”44a`, `南1・m15ab`
    nonisolated(unsafe) private static let shorthandPattern = #/(?:(?:(?<dayNumber>\d)\s*日目|[(（]?(?<weekday>[日月火水木金土])(?!目)(?:曜日?)?[)）]?)\s*)?(?:(?<area>[東西南北])\s*\d?\s*[\-－ー―‐−・]?\s*)?["“”'‘’]?(?<block>[\p{Katakana}\p{Hiragana}A-Za-z])["“”'‘’]?\s*(?<dash>[\-－ー―‐−])?\s*(?<space>\d{1,2})(?!\d)\s*(?<suffix>(?:ab|[ab])(?![A-Za-z]))?/#

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
