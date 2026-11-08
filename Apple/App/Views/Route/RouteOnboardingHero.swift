import SwiftUI

/// A small hall drawn the way the catalog draws one: islands of numbered spaces split by a
/// cross aisle with green block letters, wall circles along the wall, and the route
/// walking in from the door, around a closed aisle, to three favourites.
struct RouteOnboardingHero: View {

    @State var progress: CGFloat = 0.0

    static let width: CGFloat = 100.0
    static let height: CGFloat = 62.0
    static let cell: CGFloat = 2.6
    static let islandColumns: [CGFloat] = [13.0, 26.0, 39.0, 60.0, 73.0]
    static let letters = ["Ｆ", "Ｅ", "Ｄ", "Ｃ", "Ｂ"]
    static let upperTop: CGFloat = 14.0
    static let lowerTop: CGFloat = 39.0
    static let rows = 6

    let route: [CGPoint] = [
        CGPoint(x: 3.0, y: 50.5), CGPoint(x: 8.0, y: 50.5), CGPoint(x: 8.0, y: 34.3),
        CGPoint(x: 22.1, y: 34.3), CGPoint(x: 22.1, y: 10.3), CGPoint(x: 52.1, y: 10.3),
        CGPoint(x: 52.1, y: 57.3), CGPoint(x: 81.0, y: 57.3), CGPoint(x: 81.0, y: 45.0)
    ]

    let stops: [(CGPoint, Color)] = [
        (CGPoint(x: 22.1, y: 21.0), Color.accentColor),
        (CGPoint(x: 52.1, y: 47.0), Color.accentColor),
        (CGPoint(x: 81.0, y: 45.0), Color.accentColor)
    ]

    let closure = CGPoint(x: 35.1, y: 34.3)

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Self.width
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    drawHall(in: &context, scale: scale)
                }
                Path { path in
                    path.addLines(route.map { point(for: $0, scale: scale) })
                }
                .trim(from: 0.0, to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round, lineJoin: .round))
                Canvas { context, _ in
                    drawLetters(in: &context, scale: scale)
                }
                Capsule()
                    .fill(Color.primary)
                    .frame(width: 1.0 * scale, height: 6.0 * scale)
                    .position(point(for: closure, scale: scale))
                badge(systemImage: "nosign", fill: .primary, scale: scale)
                    .position(point(for: CGPoint(x: closure.x, y: closure.y - 4.2), scale: scale))
                ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                    Text("\(index + 1)")
                        .font(.system(size: 2.6 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 4.4 * scale, height: 4.4 * scale)
                        .background(Circle().fill(stop.1))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 0.5 * scale))
                        .shadow(color: .black.opacity(0.2), radius: 0.4 * scale)
                        .position(point(for: stop.0, scale: scale))
                }
                badge(systemImage: "figure.walk", fill: .accentColor, scale: scale)
                    .position(point(for: route[0], scale: scale))
            }
        }
        .aspectRatio(Self.width / Self.height, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 20.0))
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0)) {
                progress = 1.0
            }
        }
    }

    func point(for unit: CGPoint, scale: CGFloat) -> CGPoint {
        CGPoint(x: unit.x * scale, y: unit.y * scale)
    }

    func badge(systemImage: String, fill: Color, scale: CGFloat) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 2.4 * scale, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 4.4 * scale, height: 4.4 * scale)
            .background(Circle().fill(fill))
            .overlay(Circle().strokeBorder(.white, lineWidth: 0.5 * scale))
            .shadow(color: .black.opacity(0.2), radius: 0.4 * scale)
    }

    func drawLetters(in context: inout GraphicsContext, scale: CGFloat) {
        let letterColor = Color(red: 0.49, green: 0.72, blue: 0.3)
        for (index, column) in Self.islandColumns.enumerated() {
            let letter = Text(Self.letters[index])
                .font(.system(size: 4.2 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(letterColor)
            context.draw(letter, at: point(for: CGPoint(x: column + Self.cell, y: 34.3), scale: scale))
        }
    }

    func drawHall(in context: inout GraphicsContext, scale: CGFloat) {
        let floor = CGRect(x: 0, y: 0, width: Self.width * scale, height: Self.height * scale)
        context.fill(Path(floor), with: .color(Color(uiColor: .systemBackground)))

        let line = Color(uiColor: .label)
        let thin = 0.18 * scale

        context.fill(
            Path(CGRect(x: 0, y: 22.0 * scale, width: 2.4 * scale, height: 12.0 * scale)),
            with: .color(Color(uiColor: .systemGray4))
        )

        var wall = Path()
        wall.move(to: point(for: CGPoint(x: 3.0, y: 46.0), scale: scale))
        wall.addLine(to: point(for: CGPoint(x: 3.0, y: 3.0), scale: scale))
        wall.addLine(to: point(for: CGPoint(x: 97.0, y: 3.0), scale: scale))
        wall.addLine(to: point(for: CGPoint(x: 97.0, y: 60.0), scale: scale))
        wall.addLine(to: point(for: CGPoint(x: 3.0, y: 60.0), scale: scale))
        wall.addLine(to: point(for: CGPoint(x: 3.0, y: 55.0), scale: scale))
        context.stroke(wall, with: .color(Color(uiColor: .systemGray)), lineWidth: 0.9 * scale)

        for start in [12.0, 62.0] {
            for index in 0..<8 {
                let rect = CGRect(x: (CGFloat(start) + CGFloat(index) * Self.cell) * scale, y: 3.9 * scale,
                                  width: Self.cell * scale, height: Self.cell * scale)
                context.stroke(Path(rect), with: .color(line), lineWidth: thin)
            }
        }

        for column in Self.islandColumns {
            for top in [Self.upperTop, Self.lowerTop] {
                for row in 0..<Self.rows {
                    for side in 0..<2 {
                        let rect = CGRect(
                            x: (column + CGFloat(side) * Self.cell) * scale,
                            y: (top + CGFloat(row) * Self.cell) * scale,
                            width: Self.cell * scale, height: Self.cell * scale
                        )
                        context.stroke(Path(rect), with: .color(line), lineWidth: thin)
                    }
                }
            }
        }
    }
}
