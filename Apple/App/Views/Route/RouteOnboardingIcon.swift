import SwiftUI

/// Hand-drawn icons for the ナビ onboarding, in the style of the route mode icons.
struct RouteOnboardingIcon: View {

    enum Kind {
        case modes
        case origin
        case steps
        case detour
    }

    let kind: Kind
    var size: CGFloat = 36.0

    var body: some View {
        Canvas { context, canvasSize in
            let side = min(canvasSize.width, canvasSize.height)
            switch kind {
            case .modes: drawModes(in: &context, side: side)
            case .origin: drawOrigin(in: &context, side: side)
            case .steps: drawSteps(in: &context, side: side)
            case .detour: drawDetour(in: &context, side: side)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    func points(_ units: [(CGFloat, CGFloat)], side: CGFloat) -> [CGPoint] {
        units.map { CGPoint(x: $0.0 * side, y: $0.1 * side) }
    }

    /// One start, two ways: a single blue line, or one colour after another.
    func drawModes(in context: inout GraphicsContext, side: CGFloat) {
        let width = side * 0.11
        let blue = points([(0.14, 0.86), (0.14, 0.16), (0.84, 0.16)], side: side)
        let orange = points([(0.14, 0.86), (0.5, 0.86), (0.5, 0.5)], side: side)
        let pink = points([(0.5, 0.5), (0.84, 0.5)], side: side)
        IconDrawing.drawLine(in: &context, through: blue, color: IconDrawing.blue, width: width)
        IconDrawing.drawLine(in: &context, through: orange, color: IconDrawing.orange, width: width)
        IconDrawing.drawLine(in: &context, through: pink, color: IconDrawing.pink, width: width)
        IconDrawing.drawDot(in: &context, at: blue[0], radius: 0.09 * side, color: IconDrawing.green)
        IconDrawing.drawDot(in: &context, at: blue[2], radius: 0.09 * side, color: IconDrawing.red)
        IconDrawing.drawDot(in: &context, at: orange[2], radius: 0.09 * side, color: IconDrawing.orange)
        IconDrawing.drawDot(in: &context, at: pink[1], radius: 0.09 * side, color: IconDrawing.pink)
    }

    /// The current location dot, with the rings a long press leaves behind.
    func drawOrigin(in context: inout GraphicsContext, side: CGFloat) {
        let center = CGPoint(x: side * 0.5, y: side * 0.5)
        for (radius, opacity) in [(0.46, 0.18), (0.32, 0.32)] {
            let ring = CGRect(x: center.x - radius * side, y: center.y - radius * side,
                              width: radius * side * 2.0, height: radius * side * 2.0)
            context.fill(Path(ellipseIn: ring), with: .color(IconDrawing.blue.opacity(opacity)))
        }
        IconDrawing.drawDot(in: &context, at: center, radius: 0.17 * side, color: IconDrawing.blue)
    }

    /// Stops already passed, and the button that moves on to the next one.
    func drawSteps(in context: inout GraphicsContext, side: CGFloat) {
        let line = points([(0.12, 0.5), (0.62, 0.5)], side: side)
        IconDrawing.drawLine(in: &context, through: line, color: .gray.opacity(0.6), width: side * 0.08)
        IconDrawing.drawDot(in: &context, at: line[0], radius: 0.08 * side, color: .gray)
        IconDrawing.drawDot(in: &context, at: CGPoint(x: side * 0.37, y: side * 0.5),
                            radius: 0.08 * side, color: .gray)
        let button = Path(ellipseIn: CGRect(x: side * 0.46, y: side * 0.26, width: side * 0.48, height: side * 0.48))
        context.fill(button, with: .color(IconDrawing.green))
        context.stroke(button, with: .color(IconDrawing.outline), lineWidth: side * 0.04)
        let chevron = points([(0.66, 0.38), (0.77, 0.5), (0.66, 0.62)], side: side)
        IconDrawing.drawLine(in: &context, through: chevron, color: .white, width: side * 0.08)
    }

    /// A closed aisle on the straight way, and the route bending around it.
    func drawDetour(in context: inout GraphicsContext, side: CGFloat) {
        let straight = points([(0.14, 0.76), (0.86, 0.76)], side: side)
        IconDrawing.drawLine(in: &context, through: straight, color: .gray.opacity(0.4), width: side * 0.08)
        let around = points([(0.14, 0.76), (0.3, 0.76), (0.3, 0.24), (0.7, 0.24), (0.7, 0.76), (0.86, 0.76)],
                            side: side)
        IconDrawing.drawLine(in: &context, through: around, color: IconDrawing.blue, width: side * 0.11)
        let barrier = CGRect(x: side * 0.44, y: side * 0.56, width: side * 0.12, height: side * 0.4)
        let bar = Path(roundedRect: barrier, cornerRadius: side * 0.06, style: .continuous)
        context.fill(bar, with: .color(IconDrawing.red))
        context.stroke(bar, with: .color(IconDrawing.outline), lineWidth: side * 0.04)
        IconDrawing.drawDot(in: &context, at: around[0], radius: 0.09 * side, color: IconDrawing.green)
        IconDrawing.drawDot(in: &context, at: around[5], radius: 0.09 * side, color: IconDrawing.red)
    }
}
