import SwiftUI

/// Hand-drawn, full-colour icons for the ways a route can be planned.
struct NaviModeIcon: View {

    enum Kind {
        case automatic
        case colors
        case ownBuys
        case sharedBuys
    }

    @Environment(\.isEnabled) var isEnabled

    let kind: Kind
    var size: CGFloat = 40.0

    var body: some View {
        Canvas { context, canvasSize in
            let side = min(canvasSize.width, canvasSize.height)
            switch kind {
            case .automatic: drawRoute(in: &context, side: side)
            case .colors: drawColors(in: &context, side: side)
            case .ownBuys: drawOwnBuys(in: &context, side: side)
            case .sharedBuys: drawSharedBuys(in: &context, side: side)
            }
        }
        .frame(width: size, height: size)
        .saturation(isEnabled ? 1.0 : 0.0)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityHidden(true)
    }

    // MARK: Drawings

    /// Up, right, up, right, then down: the shortest way through every stop.
    func drawRoute(in context: inout GraphicsContext, side: CGFloat) {
        let points = [(0.14, 0.86), (0.14, 0.54), (0.44, 0.54), (0.44, 0.2), (0.8, 0.2), (0.8, 0.58)]
            .map { CGPoint(x: $0.0 * side, y: $0.1 * side) }
        IconDrawing.drawLine(in: &context, through: points, color: IconDrawing.blue, width: side * 0.11)
        IconDrawing.drawDot(in: &context, at: points[0], radius: 0.09 * side, color: IconDrawing.green)
        IconDrawing.drawDot(in: &context, at: points[points.count - 1], radius: 0.1 * side, color: IconDrawing.red)
    }

    /// Up, right, down, right, then up, one favourite colour after another.
    func drawColors(in context: inout GraphicsContext, side: CGFloat) {
        let legs: [([(CGFloat, CGFloat)], Color)] = [
            ([(0.14, 0.86), (0.14, 0.18), (0.44, 0.18)], IconDrawing.orange),
            ([(0.44, 0.18), (0.44, 0.82), (0.76, 0.82)], IconDrawing.pink),
            ([(0.76, 0.82), (0.76, 0.18)], IconDrawing.cyan)
        ]
        for (leg, color) in legs {
            let points = leg.map { CGPoint(x: $0.0 * side, y: $0.1 * side) }
            IconDrawing.drawLine(in: &context, through: points, color: color, width: side * 0.11)
        }
        IconDrawing.drawDot(in: &context, at: CGPoint(x: 0.14 * side, y: 0.86 * side),
                            radius: 0.08 * side, color: IconDrawing.green)
        for (leg, color) in legs {
            guard let end = leg.last else { continue }
            IconDrawing.drawDot(in: &context, at: CGPoint(x: end.0 * side, y: end.1 * side),
                                radius: 0.1 * side, color: color)
        }
    }

    func drawOwnBuys(in context: inout GraphicsContext, side: CGFloat) {
        let rect = CGRect(x: 0.19 * side, y: 0.06 * side, width: 0.62 * side, height: 0.88 * side)
        IconDrawing.drawBag(in: &context, rect: rect,
                body: IconDrawing.pink, handle: IconDrawing.deepPink)
    }

    func drawSharedBuys(in context: inout GraphicsContext, side: CGFloat) {
        let back = CGRect(x: 0.42 * side, y: 0.04 * side, width: 0.5 * side, height: 0.7 * side)
        let front = CGRect(x: 0.08 * side, y: 0.26 * side, width: 0.5 * side, height: 0.7 * side)
        IconDrawing.drawBag(in: &context, rect: back,
                body: IconDrawing.purple, handle: IconDrawing.deepPurple)
        IconDrawing.drawBag(in: &context, rect: front,
                body: IconDrawing.teal, handle: IconDrawing.deepTeal)
    }
}
