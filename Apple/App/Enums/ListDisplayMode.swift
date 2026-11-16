import CoreGraphics

enum ListDisplayMode: Int, CaseIterable {
    case regular = 1
    case compact = 2

    var rowHeight: CGFloat {
        switch self {
        case .regular: return 120.0
        case .compact: return 60.0
        }
    }
}
