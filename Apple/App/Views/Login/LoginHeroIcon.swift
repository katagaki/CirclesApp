import SwiftUI

/// Hand-drawn icons for the features listed on the login screen.
struct LoginHeroIcon: View {

    enum Kind {
        case map
        case circles
        case favorites
        case buys
    }

    let kind: Kind
    var size: CGFloat = 56.0

    var body: some View {
        Canvas { context, canvasSize in
            let side = min(canvasSize.width, canvasSize.height)
            switch kind {
            case .map: drawMap(in: &context, side: side)
            case .circles: drawCircles(in: &context, side: side)
            case .favorites: drawFavorites(in: &context, side: side)
            case .buys: drawBuys(in: &context, side: side)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// A folded map of the 東, 西 and 南 halls.
    func drawMap(in context: inout GraphicsContext, side: CGFloat) {
        let edges: [CGFloat] = [0.05, 0.35, 0.65, 0.95]
        let tops: [CGFloat] = [0.16, 0.04, 0.16, 0.04]
        let height: CGFloat = 0.8
        let lineWidth = side * 0.04
        let panels: [(String, Color, Color)] = [
            ("東", IconDrawing.red, IconDrawing.deepRed),
            ("西", IconDrawing.deepBlue, IconDrawing.blue),
            ("南", IconDrawing.green, IconDrawing.deepGreen)
        ]
        let topEdge = edges.indices.map { CGPoint(x: edges[$0] * side, y: tops[$0] * side) }
        let bottomEdge = edges.indices.reversed()
            .map { CGPoint(x: edges[$0] * side, y: (tops[$0] + height) * side) }
        let corner = side * 0.09
        let map = roundedPolygon(topEdge + bottomEdge, radii: [corner, 0.0, 0.0, corner, corner, 0.0, 0.0, corner])
        var inside = context
        inside.clip(to: map)
        for (index, panel) in panels.enumerated() {
            let column = CGRect(x: edges[index] * side, y: 0.0,
                                width: (edges[index + 1] - edges[index]) * side, height: side)
            inside.fill(Path(column), with: .linearGradient(
                Gradient(colors: [panel.1, panel.2]),
                startPoint: CGPoint(x: column.midX, y: 0.0),
                endPoint: CGPoint(x: column.midX, y: side)
            ))
            let label = Text(panel.0)
                .font(.system(size: side * 0.22, weight: .heavy))
                .foregroundColor(.white)
            let stagger = (CGFloat(index) - 1.0) * 0.22
            let center = CGPoint(x: (edges[index] + edges[index + 1]) / 2.0 * side,
                                 y: ((tops[index] + tops[index + 1]) / 2.0 + height / 2.0 + stagger) * side)
            let slope = (tops[index + 1] - tops[index]) / (edges[index + 1] - edges[index])
            var sheared = inside
            sheared.translateBy(x: center.x, y: center.y)
            sheared.concatenate(CGAffineTransform(a: 1.0, b: slope, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0))
            sheared.draw(label, at: .zero)
        }
        for edge in edges.dropFirst().dropLast() {
            let crease = [CGPoint(x: edge * side, y: 0.0), CGPoint(x: edge * side, y: side)]
            inside.stroke(IconDrawing.polyline(crease), with: .color(IconDrawing.outline), lineWidth: lineWidth)
        }
        context.stroke(map, with: .color(IconDrawing.outline),
                       style: StrokeStyle(lineWidth: lineWidth, lineJoin: .miter))
    }

    /// A grid of circle cuts, one per favourite colour.
    func drawCircles(in context: inout GraphicsContext, side: CGFloat) {
        let colors: [(Color, Color)] = [
            (IconDrawing.red, IconDrawing.deepRed), (IconDrawing.orange, IconDrawing.deepOrange),
            (IconDrawing.yellow, IconDrawing.deepYellow), (IconDrawing.green, IconDrawing.deepGreen),
            (IconDrawing.cyan, IconDrawing.deepCyan), (IconDrawing.blue, IconDrawing.deepBlue),
            (IconDrawing.purple, IconDrawing.deepPurple), (IconDrawing.pink, IconDrawing.deepPink),
            (IconDrawing.gray, IconDrawing.deepGray)
        ]
        let cell: CGFloat = 0.26
        let gap: CGFloat = 0.07
        let start = (1.0 - cell * 3.0 - gap * 2.0) / 2.0
        for (index, color) in colors.enumerated() {
            let rect = CGRect(x: (start + CGFloat(index % 3) * (cell + gap)) * side,
                              y: (start + CGFloat(index / 3) * (cell + gap)) * side,
                              width: cell * side, height: cell * side)
            let path = Path(roundedRect: rect, cornerRadius: 0.07 * side, style: .continuous)
            IconDrawing.fillOutlined(in: &context, path, in: rect, top: color.0, bottom: color.1,
                                     lineWidth: side * 0.035)
        }
    }

    /// A starred circle in front of the rest.
    func drawFavorites(in context: inout GraphicsContext, side: CGFloat) {
        var back = context
        back.translateBy(x: side * 0.38, y: side * 0.36)
        back.rotate(by: .degrees(-10.0))
        let backRect = CGRect(x: -0.3 * side, y: -0.28 * side, width: 0.6 * side, height: 0.56 * side)
        let backPath = Path(roundedRect: backRect, cornerRadius: 0.1 * side, style: .continuous)
        IconDrawing.fillOutlined(in: &back, backPath, in: backRect,
                                 top: IconDrawing.green, bottom: IconDrawing.deepGreen,
                                 lineWidth: side * 0.04)
        let frontRect = CGRect(x: 0.3 * side, y: 0.3 * side, width: 0.64 * side, height: 0.64 * side)
        IconDrawing.fillOutlined(in: &context,
                                 Path(roundedRect: frontRect, cornerRadius: 0.12 * side, style: .continuous),
                                 in: frontRect, top: IconDrawing.red, bottom: IconDrawing.deepRed,
                                 lineWidth: side * 0.04)
        let star = starPath(center: CGPoint(x: frontRect.midX, y: frontRect.midY + 0.01 * side), radius: 0.22 * side)
        context.fill(star, with: .color(.white))
        context.stroke(star, with: .color(.white), style: StrokeStyle(lineWidth: side * 0.025, lineJoin: .round))
    }

    /// A bag for your list, with another behind it.
    func drawBuys(in context: inout GraphicsContext, side: CGFloat) {
        var back = context
        back.translateBy(x: side * 0.63, y: side * 0.48)
        back.rotate(by: .degrees(12.0))
        let backRect = CGRect(x: -0.25 * side, y: -0.38 * side, width: 0.5 * side, height: 0.76 * side)
        IconDrawing.drawBag(in: &back, rect: backRect,
                            body: IconDrawing.green, handle: IconDrawing.deepGreen)
        var front = context
        front.translateBy(x: side * 0.38, y: side * 0.54)
        front.rotate(by: .degrees(-8.0))
        let frontRect = CGRect(x: -0.27 * side, y: -0.42 * side, width: 0.54 * side, height: 0.82 * side)
        IconDrawing.drawBag(in: &front, rect: frontRect,
                            body: IconDrawing.orange, handle: IconDrawing.deepOrange)
    }

    func roundedPolygon(_ corners: [CGPoint], radii: [CGFloat]) -> Path {
        var path = Path()
        guard let first = corners.first, let last = corners.last else { return path }
        path.move(to: CGPoint(x: (first.x + last.x) / 2.0, y: (first.y + last.y) / 2.0))
        for index in corners.indices {
            path.addArc(tangent1End: corners[index], tangent2End: corners[(index + 1) % corners.count],
                        radius: radii[index])
        }
        path.closeSubpath()
        return path
    }

    func starPath(center: CGPoint, radius: CGFloat) -> Path {
        let points = (0..<10).map { index -> CGPoint in
            let angle = Double(index) * .pi / 5.0 - .pi / 2.0
            let distance = index.isMultiple(of: 2) ? radius : radius * 0.45
            return CGPoint(x: center.x + CGFloat(cos(angle)) * distance, y: center.y + CGFloat(sin(angle)) * distance)
        }
        var path = IconDrawing.polyline(points)
        path.closeSubpath()
        return path
    }
}
