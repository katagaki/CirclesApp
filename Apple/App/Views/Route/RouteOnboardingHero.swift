import SwiftUI

/// A miniature hall: three rows of islands, a closed aisle, and a route that draws itself
/// around the closure from the visitor to three favourites.
struct RouteOnboardingHero: View {

    @State var progress: CGFloat = 0.0

    let islands: [CGRect] = (0..<3).flatMap { row in
        (0..<5).map { column in
            CGRect(x: 0.08 + CGFloat(column) * 0.18, y: 0.1 + CGFloat(row) * 0.3, width: 0.1, height: 0.2)
        }
    }

    let route: [CGPoint] = [
        CGPoint(x: 0.035, y: 0.88), CGPoint(x: 0.035, y: 0.35), CGPoint(x: 0.21, y: 0.35),
        CGPoint(x: 0.21, y: 0.65), CGPoint(x: 0.57, y: 0.65), CGPoint(x: 0.57, y: 0.05),
        CGPoint(x: 0.93, y: 0.05), CGPoint(x: 0.93, y: 0.62)
    ]

    let stops: [(CGPoint, Color)] = [
        (CGPoint(x: 0.21, y: 0.5), .orange),
        (CGPoint(x: 0.57, y: 0.2), .pink),
        (CGPoint(x: 0.93, y: 0.62), .green)
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 24.0)
                    .fill(.background.secondary)
                ForEach(Array(islands.enumerated()), id: \.offset) { _, island in
                    RoundedRectangle(cornerRadius: 4.0)
                        .strokeBorder(.secondary.opacity(0.5), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(.background))
                        .frame(width: island.width * size.width, height: island.height * size.height)
                        .position(x: island.midX * size.width, y: island.midY * size.height)
                }
                Path { path in
                    path.addLines(route.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) })
                }
                .trim(from: 0.0, to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                Image(systemName: "nosign")
                    .font(.system(size: 18.0, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28.0, height: 28.0)
                    .background(Circle().fill(.red))
                    .position(x: 0.39 * size.width, y: 0.35 * size.height)
                ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                    Text("\(index + 1)")
                        .font(.system(size: 13.0, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 24.0, height: 24.0)
                        .background(Circle().fill(stop.1))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2.0))
                        .position(x: stop.0.x * size.width, y: stop.0.y * size.height)
                }
                Image(systemName: "figure.walk")
                    .font(.system(size: 13.0, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26.0, height: 26.0)
                    .background(Circle().fill(.green))
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.0))
                    .position(x: 0.035 * size.width, y: 0.88 * size.height)
            }
            .clipShape(.rect(cornerRadius: 24.0))
        }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: false)) {
                progress = 1.0
            }
        }
    }
}
