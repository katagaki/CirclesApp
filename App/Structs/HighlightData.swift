import Foundation

struct HighlightData: Equatable {
    var sourceRect: CGRect
    var shouldBlink: Bool = false

    static func == (lhs: HighlightData, rhs: HighlightData) -> Bool {
        lhs.sourceRect == rhs.sourceRect && lhs.shouldBlink == rhs.shouldBlink
    }
}
