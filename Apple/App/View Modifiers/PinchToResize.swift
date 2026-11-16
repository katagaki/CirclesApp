import SwiftUI

/// Scales a scroll view smoothly under a pinch and snaps its layout between discrete levels,
/// keeping the item under the fingers in place as the layout changes.
struct PinchToResizeModifier<Level: Hashable>: ViewModifier {

    @Binding var level: Level
    var levels: [Level]
    var itemHeight: (Level, CGFloat) -> CGFloat

    @State private var position = ScrollPosition()
    @State private var tracker = PinchItemTracker()
    @State private var startLevel: Level?
    @State private var anchor: UnitPoint = .center
    @State private var liveScale: CGFloat = 1.0
    @State private var levelScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .environment(\.pinchItemTracker, tracker)
            .scrollPosition($position)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { tracker.viewportSize = $0 }
            .simultaneousGesture(
                MagnifyGesture(minimumScaleDelta: 0.0)
                    .onChanged(pinchChanged)
                    .onEnded { _ in pinchEnded() }
            )
            .scaleEffect(levelScale, anchor: anchor)
            .scaleEffect(liveScale, anchor: anchor)
            .clipShape(HorizontalClipShape(isActive: startLevel != nil))
    }

    func pinchChanged(_ value: MagnifyGesture.Value) {
        let width = tracker.viewportSize.width
        guard width > 0.0 else { return }
        if startLevel == nil {
            startLevel = level
            anchor = value.startAnchor
            tracker.anchorLocation = value.startLocation
            tracker.anchorItem = tracker.item(at: value.startLocation)
        }
        guard let startLevel else { return }

        let startHeight = itemHeight(startLevel, width)
        let heights = levels.map { itemHeight($0, width) }
        guard let smallest = heights.min(), let largest = heights.max() else { return }
        var height = startHeight * value.magnification
        if height > largest {
            height = largest * pow(height / largest, 0.25)
        } else if height < smallest {
            height = smallest * pow(height / smallest, 0.25)
        }
        tracker.pinchHeight = height

        let fitting = levels
            .filter { itemHeight($0, width) <= height }
            .max(by: { itemHeight($0, width) < itemHeight($1, width) })
            ?? levels.min(by: { itemHeight($0, width) < itemHeight($1, width) })
        if let fitting, fitting != level {
            relayout(to: fitting, width: width, startHeight: startHeight)
        }
        liveScale = height / startHeight
    }

    func pinchEnded() {
        let width = tracker.viewportSize.width
        if let startLevel, width > 0.0 {
            let distance = { (level: Level) in abs(log(tracker.pinchHeight / itemHeight(level, width))) }
            if let nearest = levels.min(by: { distance($0) < distance($1) }), nearest != level {
                relayout(to: nearest, width: width, startHeight: itemHeight(startLevel, width))
            }
        }
        startLevel = nil
        withAnimation(.smooth(duration: 0.3)) {
            liveScale = 1.0
            levelScale = 1.0
        }
    }

    func relayout(to newLevel: Level, width: CGFloat, startHeight: CGFloat) {
        let newHeight = itemHeight(newLevel, width)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            level = newLevel
            levelScale = startHeight / newHeight
        }
        if let anchorItem = tracker.anchorItem {
            let viewportHeight = tracker.viewportSize.height
            let newTop = tracker.anchorLocation.y - anchorItem.fraction * newHeight
            let anchorY = viewportHeight == newHeight ? 0.0 : newTop / (viewportHeight - newHeight)
            let target = UnitPoint(x: 0.5, y: anchorY)
            // HACK: Scrolling in the same update as the relayout leaves the lazy grid blank for a moment
            DispatchQueue.main.async {
                position.scrollTo(id: anchorItem.id, anchor: target)
            }
        }
    }
}

extension View {
    func pinchToResize<Level: Hashable>(
        _ level: Binding<Level>,
        levels: [Level],
        itemHeight: @escaping (Level, CGFloat) -> CGFloat
    ) -> some View {
        modifier(PinchToResizeModifier(level: level, levels: levels, itemHeight: itemHeight))
    }
}
