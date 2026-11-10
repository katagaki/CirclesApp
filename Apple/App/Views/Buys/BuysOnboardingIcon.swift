import SwiftUI

/// Hand-drawn icons for the 宝物 onboarding, in the style of the route mode icons.
struct BuysOnboardingIcon: View {

    enum Kind {
        case add
        case track
        case share
        case split
    }

    let kind: Kind
    var size: CGFloat = 36.0

    var body: some View {
        Canvas { context, canvasSize in
            let side = min(canvasSize.width, canvasSize.height)
            switch kind {
            case .add: drawAdd(in: &context, side: side)
            case .track: drawTrack(in: &context, side: side)
            case .share: drawShare(in: &context, side: side)
            case .split: drawSplit(in: &context, side: side)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    func circle(_ center: CGPoint, _ radius: CGFloat) -> (Path, CGRect) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2.0, height: radius * 2.0)
        return (Path(ellipseIn: rect), rect)
    }

    func mark(in context: inout GraphicsContext, _ units: [(CGFloat, CGFloat)], side: CGFloat) {
        let points = units.map { CGPoint(x: $0.0 * side, y: $0.1 * side) }
        IconDrawing.drawLine(in: &context, through: points, color: .white, width: side * 0.08)
    }

    /// A bag with a plus badge.
    func drawAdd(in context: inout GraphicsContext, side: CGFloat) {
        let bagRect = CGRect(x: 0.08 * side, y: 0.04 * side, width: 0.6 * side, height: 0.86 * side)
        IconDrawing.drawBag(in: &context, rect: bagRect,
                            body: IconDrawing.pink, handle: IconDrawing.deepPink)
        let (badge, rect) = circle(CGPoint(x: 0.73 * side, y: 0.73 * side), 0.23 * side)
        IconDrawing.fillOutlined(in: &context, badge, in: rect, top: IconDrawing.green, bottom: IconDrawing.deepGreen,
                                 lineWidth: side * 0.045)
        mark(in: &context, [(0.73, 0.62), (0.73, 0.84)], side: side)
        mark(in: &context, [(0.62, 0.73), (0.84, 0.73)], side: side)
    }

    /// Tap once for bought, twice for couldn't buy.
    func drawTrack(in context: inout GraphicsContext, side: CGFloat) {
        let (missed, missedRect) = circle(CGPoint(x: 0.33 * side, y: 0.33 * side), 0.27 * side)
        IconDrawing.fillOutlined(in: &context, missed, in: missedRect, top: IconDrawing.red,
                                 bottom: IconDrawing.deepRed, lineWidth: side * 0.045)
        mark(in: &context, [(0.24, 0.24), (0.42, 0.42)], side: side)
        mark(in: &context, [(0.42, 0.24), (0.24, 0.42)], side: side)
        let (bought, boughtRect) = circle(CGPoint(x: 0.62 * side, y: 0.62 * side), 0.33 * side)
        IconDrawing.fillOutlined(in: &context, bought, in: boughtRect, top: IconDrawing.green,
                                 bottom: IconDrawing.deepGreen, lineWidth: side * 0.045)
        mark(in: &context, [(0.48, 0.63), (0.58, 0.73), (0.77, 0.52)], side: side)
    }

    /// A QR code for friends to join with.
    func drawShare(in context: inout GraphicsContext, side: CGFloat) {
        let tileRect = CGRect(x: 0.08 * side, y: 0.08 * side, width: 0.84 * side, height: 0.84 * side)
        let tile = Path(roundedRect: tileRect, cornerRadius: 0.16 * side, style: .continuous)
        context.fill(tile, with: .color(.white))
        context.stroke(tile, with: .color(IconDrawing.outline), lineWidth: side * 0.045)
        let ink = Color.black
        for origin in [(0.2, 0.2), (0.56, 0.2), (0.2, 0.56)] {
            let outer = CGRect(x: origin.0 * side, y: origin.1 * side, width: 0.24 * side, height: 0.24 * side)
            context.stroke(Path(roundedRect: outer.insetBy(dx: 0.03 * side, dy: 0.03 * side),
                                cornerRadius: 0.04 * side), with: .color(ink), lineWidth: 0.06 * side)
            context.fill(Path(roundedRect: outer.insetBy(dx: 0.08 * side, dy: 0.08 * side),
                              cornerRadius: 0.02 * side), with: .color(IconDrawing.blue))
        }
        for module in [(0.56, 0.56), (0.7, 0.56), (0.63, 0.66), (0.56, 0.72), (0.72, 0.72)] {
            let rect = CGRect(x: module.0 * side, y: module.1 * side, width: 0.1 * side, height: 0.1 * side)
            context.fill(Path(roundedRect: rect, cornerRadius: 0.02 * side), with: .color(ink))
        }
    }

    /// Two friends sharing the list.
    func drawSplit(in context: inout GraphicsContext, side: CGFloat) {
        drawPerson(in: &context, rect: CGRect(x: 0.03 * side, y: 0.06 * side, width: 0.52 * side, height: 0.8 * side),
                   top: IconDrawing.purple, bottom: IconDrawing.deepPurple)
        drawPerson(in: &context, rect: CGRect(x: 0.42 * side, y: 0.16 * side, width: 0.55 * side, height: 0.8 * side),
                   top: IconDrawing.teal, bottom: IconDrawing.deepTeal)
    }

    func drawPerson(in context: inout GraphicsContext, rect: CGRect, top: Color, bottom: Color) {
        let lineWidth = rect.width * 0.08
        let bodyRect = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.5,
                              width: rect.width, height: rect.height * 0.5)
        let body = Path(roundedRect: bodyRect, cornerRadius: rect.width * 0.4, style: .continuous)
        IconDrawing.fillOutlined(in: &context, body, in: bodyRect, top: top, bottom: bottom, lineWidth: lineWidth)
        let (head, headRect) = circle(CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.27), rect.width * 0.27)
        IconDrawing.fillOutlined(in: &context, head, in: headRect, top: top, bottom: bottom, lineWidth: lineWidth)
    }
}
