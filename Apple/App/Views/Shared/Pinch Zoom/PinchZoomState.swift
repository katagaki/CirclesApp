import SwiftUI

protocol PinchZoomSession {
    func contentBottom(progress: CGFloat, focusY: CGFloat) -> CGFloat
}

@Observable
@MainActor
final class PinchZoomState<Session: PinchZoomSession> {
    var session: Session?
    var progress: CGFloat = 0.0
    var focusY: CGFloat = 0.0
    var isSettling = false
}

extension CGFloat {
    func rubberBanded(between lower: CGFloat, and upper: CGFloat, unit: CGFloat = 1.0) -> CGFloat {
        if self < lower {
            let excess = (lower - self) / unit
            return lower - excess / (1.0 + excess * 2.0) * unit
        } else if self > upper {
            let excess = (self - upper) / unit
            return upper + excess / (1.0 + excess * 2.0) * unit
        }
        return self
    }

    var smoothstepped: CGFloat {
        self * self * (3.0 - 2.0 * self)
    }
}
