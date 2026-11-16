import SwiftUI

/// Holds the on-screen frames of a pinchable scroll view's items without triggering view updates.
final class PinchItemTracker {

    struct Item {
        var id: Int
        var fraction: CGFloat
    }

    var viewportSize: CGSize = .zero
    var anchorLocation: CGPoint = .zero
    var anchorItem: Item?
    var pinchHeight: CGFloat = 0.0
    var frames: [Int: CGRect] = [:]

    func item(at point: CGPoint) -> Item? {
        let distance = { (frame: CGRect) -> CGFloat in
            let deltaX = max(frame.minX - point.x, 0.0, point.x - frame.maxX)
            let deltaY = max(frame.minY - point.y, 0.0, point.y - frame.maxY)
            return deltaX * deltaX + deltaY * deltaY
        }
        guard let (id, frame) = frames.min(by: { distance($0.value) < distance($1.value) }),
              frame.height > 0.0 else { return nil }
        let fraction = min(max((point.y - frame.minY) / frame.height, 0.0), 1.0)
        return Item(id: id, fraction: fraction)
    }
}

extension EnvironmentValues {
    @Entry var pinchItemTracker: PinchItemTracker?
}
