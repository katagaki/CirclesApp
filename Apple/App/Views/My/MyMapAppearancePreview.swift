import SwiftUI

struct MyMapAppearancePreview: View {

    @Environment(\.colorScheme) var colorScheme

    var showsGenreOverlay: Bool
    var usesDarkModeMap: Bool
    var usesHighResolutionMap: Bool

    let islandCount: Int = 8
    let spacesPerIsland: Int = 5
    let genreColors: [Color] = [.pink, .orange, .green, .blue, .purple]

    var isDark: Bool {
        colorScheme == .dark && usesDarkModeMap
    }

    var body: some View {
        Canvas { context, size in
            let accent = GraphicsContext.Shading.color(.accentColor.opacity(0.55))
            let hall = CGRect(origin: .zero, size: size).insetBy(dx: 8.0, dy: 8.0)
            context.stroke(
                Path(roundedRect: hall, cornerRadius: 4.0),
                with: .color(.accentColor.opacity(0.8)),
                lineWidth: 1.5
            )

            let wallInset: CGFloat = 4.0
            let wallHeight: CGFloat = 6.0
            let wallCount = 18
            let wallArea = hall.insetBy(dx: wallInset * 3, dy: wallInset)
            let wallWidth = wallArea.width / CGFloat(wallCount)
            for index in 0..<wallCount {
                for originY in [wallArea.minY, wallArea.maxY - wallHeight] {
                    let space = CGRect(
                        x: wallArea.minX + CGFloat(index) * wallWidth,
                        y: originY,
                        width: wallWidth,
                        height: wallHeight
                    ).insetBy(dx: 0.5, dy: 0.5)
                    context.fill(Path(space), with: accent)
                }
            }

            let islandArea = hall.insetBy(dx: 18.0, dy: wallInset + wallHeight + 8.0)
            let aisle: CGFloat = 8.0
            let islandWidth = islandArea.width / (CGFloat(islandCount) * 1.8 - 0.8)
            let islandHeight = (islandArea.height - aisle) / 2.0
            for column in 0..<islandCount {
                let originX = islandArea.minX + CGFloat(column) * islandWidth * 1.8
                for row in 0..<2 {
                    let island = CGRect(
                        x: originX,
                        y: islandArea.minY + CGFloat(row) * (islandHeight + aisle),
                        width: islandWidth,
                        height: islandHeight
                    )
                    drawIsland(island, in: &context, shading: accent)
                    if showsGenreOverlay {
                        let genre = genreColors[(column / 2 + row * 2) % genreColors.count]
                        context.fill(
                            Path(island.insetBy(dx: -2.0, dy: -2.0)),
                            with: .color(genre.opacity(0.45))
                        )
                    }
                }
            }
        }
        .blur(radius: usesHighResolutionMap ? 0.0 : 0.8)
        .background(isDark ? Color.black : Color.white)
        .clipShape(.rect(cornerRadius: 12.0))
        .overlay {
            RoundedRectangle(cornerRadius: 12.0)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1 / 3)
        }
        .frame(height: 120.0)
        .accessibilityHidden(true)
    }

    func drawIsland(_ island: CGRect, in context: inout GraphicsContext, shading: GraphicsContext.Shading) {
        let spaceWidth = island.width / 2.0
        let spaceHeight = island.height / CGFloat(spacesPerIsland)
        for side in 0..<2 {
            for index in 0..<spacesPerIsland {
                let space = CGRect(
                    x: island.minX + CGFloat(side) * spaceWidth,
                    y: island.minY + CGFloat(index) * spaceHeight,
                    width: spaceWidth,
                    height: spaceHeight
                ).insetBy(dx: 0.5, dy: 0.5)
                context.fill(Path(space), with: shading)
            }
        }
    }
}
