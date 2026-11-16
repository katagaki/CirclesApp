import SwiftUI

struct HorizontalClipShape: Shape {
    var isActive: Bool

    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: isActive ? 0.0 : -10000.0, dy: -10000.0))
    }
}
