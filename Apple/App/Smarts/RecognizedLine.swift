import CoreGraphics
import Foundation

/// A line of text read from an image, in reading order.
struct RecognizedLine: Sendable, Hashable {

    /// The line as it most likely reads.
    let text: String
    /// The same line with one of its fragments read another way, for when the most likely
    /// reading finds nothing.
    let alternatives: [String]
    /// The line's height against the tallest line in the image, from 0 to 1.
    let relativeHeight: Double

    /// A piece of text OCR found, with its readings from most to least likely.
    struct Fragment: Sendable {
        let candidates: [String]
        /// In normalized image coordinates, with the origin at the bottom left.
        let frame: CGRect
    }

    /// Lines from top to bottom, each made of the fragments that sit side by side on it,
    /// left to right.
    ///
    /// OCR returns fragments in no particular order, which can put `東マ` and `64b` far apart
    /// when they are written next to each other.
    static func lines(from fragments: [Fragment]) -> [RecognizedLine] {
        var rows: [[Fragment]] = []
        for fragment in fragments.filter({ !$0.candidates.isEmpty }).sorted(by: { $0.frame.midY > $1.frame.midY }) {
            if let last = rows.indices.last, rows[last].contains(where: { sharesRow($0.frame, fragment.frame) }) {
                rows[last].append(fragment)
            } else {
                rows.append([fragment])
            }
        }

        let heights = rows.map { $0.map(\.frame.height).max() ?? 0 }
        let tallest = heights.max() ?? 0
        return zip(rows, heights).map { row, height in
            let row = row.sorted { $0.frame.minX < $1.frame.minX }
            let readings = row.map(\.candidates)
            let text = readings.map { $0[0] }.joined(separator: " ")
            var alternatives: [String] = []
            for (index, candidates) in readings.enumerated() {
                for candidate in candidates.dropFirst() {
                    var parts = readings.map { $0[0] }
                    parts[index] = candidate
                    let alternative = parts.joined(separator: " ")
                    if alternative != text && !alternatives.contains(alternative) {
                        alternatives.append(alternative)
                    }
                }
            }
            return RecognizedLine(
                text: text,
                alternatives: alternatives,
                relativeHeight: tallest > 0 ? Double(height / tallest) : 0
            )
        }
    }

    private static func sharesRow(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let overlap = min(lhs.maxY, rhs.maxY) - max(lhs.minY, rhs.minY)
        return overlap > 0.5 * min(lhs.height, rhs.height)
    }
}
