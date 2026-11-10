import SwiftUI

struct MyMapAppearancePreview: View {

    @Environment(\.colorScheme) var colorScheme

    var showsGenreOverlay: Bool
    var usesDarkModeMap: Bool
    var usesHighResolutionMap: Bool

    let spacesPerIsland: Int = 5
    let genreColors: [Color] = [.pink, .orange, .green, .blue, .purple]
    let genreSpans: [Int] = [3, 2, 3, 1]

    var isDark: Bool {
        colorScheme == .dark && usesDarkModeMap
    }

    var body: some View {
        Canvas { context, size in
            let accent = GraphicsContext.Shading.color(.accentColor.opacity(0.55))
            let hall = CGRect(origin: .zero, size: size).insetBy(dx: 8.0, dy: 8.0)

            let islandArea = hall.insetBy(dx: 18.0, dy: 14.0)
            let aisle: CGFloat = 8.0
            let islandHeight = (islandArea.height - aisle) / 2.0
            let islandWidth = islandHeight / CGFloat(spacesPerIsland) * 2.0
            let islandCount = max(2, Int((islandArea.width + islandWidth) / (islandWidth * 2.2)))
            let islandGap = (islandArea.width - CGFloat(islandCount) * islandWidth) / CGFloat(islandCount - 1)
            var islands: [CGRect] = []
            for column in 0..<islandCount {
                let originX = islandArea.minX + CGFloat(column) * (islandWidth + islandGap)
                for row in 0..<2 {
                    let island = CGRect(
                        x: originX,
                        y: islandArea.minY + CGFloat(row) * (islandHeight + aisle),
                        width: islandWidth,
                        height: islandHeight
                    )
                    drawIsland(island, in: &context, shading: accent)
                    islands.append(island)
                }
            }
            if showsGenreOverlay {
                drawGenres(over: islands, in: &context)
            }
        }
        .blur(radius: usesHighResolutionMap ? 0.0 : 0.8)
        .background(isDark ? Color.clear : Color.white)
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

    func drawGenres(over islands: [CGRect], in context: inout GraphicsContext) {
        var genre = 0
        for row in 0..<2 {
            let rowIslands = islands.enumerated().filter { $0.offset % 2 == row }.map(\.element)
            var column = 0
            var lengthIndex = row
            while column < rowIslands.count {
                let length = min(genreSpans[lengthIndex % genreSpans.count], rowIslands.count - column)
                let first = rowIslands[column]
                let last = rowIslands[column + length - 1]
                let region = first.union(last).insetBy(dx: -2.0, dy: -2.0)
                context.fill(
                    Path(roundedRect: region, cornerRadius: 2.0),
                    with: .color(genreColors[genre % genreColors.count].opacity(0.45))
                )
                column += length
                lengthIndex += 1
                genre += 1
            }
        }
    }
}
