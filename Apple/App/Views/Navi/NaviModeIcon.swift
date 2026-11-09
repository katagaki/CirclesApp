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
        let route = polyline(points)
        context.stroke(route, with: .color(Self.blue),
                       style: StrokeStyle(lineWidth: side * 0.11, lineCap: .round, lineJoin: .round))
        drawDot(in: &context, at: points[0], radius: 0.09 * side, color: Self.green)
        drawDot(in: &context, at: points[points.count - 1], radius: 0.1 * side, color: Self.red)
    }

    /// Up, right, down, right, then up, one favourite colour after another.
    func drawColors(in context: inout GraphicsContext, side: CGFloat) {
        let legs: [([(CGFloat, CGFloat)], Color)] = [
            ([(0.14, 0.86), (0.14, 0.18), (0.44, 0.18)], Self.orange),
            ([(0.44, 0.18), (0.44, 0.82), (0.76, 0.82)], Self.pink),
            ([(0.76, 0.82), (0.76, 0.18)], Self.cyan)
        ]
        for (leg, color) in legs {
            let points = leg.map { CGPoint(x: $0.0 * side, y: $0.1 * side) }
            context.stroke(polyline(points), with: .color(color),
                           style: StrokeStyle(lineWidth: side * 0.11, lineCap: .round, lineJoin: .round))
        }
        drawDot(in: &context, at: CGPoint(x: 0.14 * side, y: 0.86 * side), radius: 0.08 * side, color: Self.green)
        for (leg, color) in legs {
            guard let end = leg.last else { continue }
            drawDot(in: &context, at: CGPoint(x: end.0 * side, y: end.1 * side), radius: 0.1 * side, color: color)
        }
    }

    func drawOwnBuys(in context: inout GraphicsContext, side: CGFloat) {
        drawBag(in: &context, rect: CGRect(x: 0.19 * side, y: 0.06 * side, width: 0.62 * side, height: 0.88 * side),
                body: Self.pink, handle: Self.deepPink)
    }

    func drawSharedBuys(in context: inout GraphicsContext, side: CGFloat) {
        drawBag(in: &context, rect: CGRect(x: 0.42 * side, y: 0.04 * side, width: 0.5 * side, height: 0.7 * side),
                body: Self.purple, handle: Self.deepPurple)
        drawBag(in: &context, rect: CGRect(x: 0.08 * side, y: 0.26 * side, width: 0.5 * side, height: 0.7 * side),
                body: Self.teal, handle: Self.deepTeal)
    }

    // MARK: Pieces

    /// A shopping bag filling `rect`: a tall body, with a handle rising out from behind it.
    func drawBag(in context: inout GraphicsContext, rect: CGRect, body: Color, handle: Color) {
        let outline = rect.width * 0.045
        let band = rect.width * 0.11
        let handleRect = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + band / 2.0,
                                width: rect.width * 0.6, height: rect.height * 0.5)
        let handlePath = Path(roundedRect: handleRect, cornerRadius: rect.width * 0.2, style: .continuous)
        context.stroke(handlePath, with: .color(handle), lineWidth: band)
        let bodyRect = CGRect(x: rect.minX + outline / 2.0, y: rect.minY + rect.height * 0.22,
                              width: rect.width - outline, height: rect.height * 0.78 - outline / 2.0)
        let bag = Path(roundedRect: bodyRect, cornerRadius: rect.width * 0.13, style: .continuous)
        context.fill(bag, with: .linearGradient(
            Gradient(colors: [body, handle]),
            startPoint: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
            endPoint: CGPoint(x: bodyRect.midX, y: bodyRect.maxY)
        ))
        context.stroke(bag, with: .color(.white), lineWidth: outline)
    }

    func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        return path
    }

    func drawDot(in context: inout GraphicsContext, at center: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2.0, height: radius * 2.0)
        let dot = Path(ellipseIn: rect)
        context.fill(dot, with: .color(color))
        context.stroke(dot, with: .color(.white), lineWidth: radius * 0.45)
    }

    // MARK: Colors

    static let blue = Color(red: 0.25, green: 0.52, blue: 0.98)
    static let green = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let red = Color(red: 0.96, green: 0.27, blue: 0.27)
    static let orange = Color(red: 1.0, green: 0.58, blue: 0.29)
    static let pink = Color(red: 0.98, green: 0.36, blue: 0.6)
    static let deepPink = Color(red: 0.78, green: 0.15, blue: 0.42)
    static let cyan = Color(red: 0.0, green: 0.71, blue: 1.0)
    static let purple = Color(red: 0.64, green: 0.4, blue: 0.95)
    static let deepPurple = Color(red: 0.45, green: 0.24, blue: 0.75)
    static let teal = Color(red: 0.1, green: 0.74, blue: 0.7)
    static let deepTeal = Color(red: 0.04, green: 0.52, blue: 0.5)
}
