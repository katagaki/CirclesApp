import SwiftUI

struct ToolbeltLayerOverlay: View {

    @Environment(Harness.self) var harness
    @Environment(\.colorScheme) var colorScheme
    let layers: ToolbeltLayers

    var body: some View {
        Canvas { context, size in
            let layout = HallMapLayout(hall: harness.hall, size: size)
            let dark = colorScheme == .dark
            let hallFill = dark ? Color(white: 0.17) : Color.white
            let deskFill = dark ? Color(white: 0.26) : Color(white: 0.88)
            for circle in MockData.circles where circle.hall == harness.hall {
                let rect = layout.slotRect(block: circle.blockIndex, slot: circle.slotIndex)
                let favorite = harness.favorites[circle.id]
                context.fill(Path(rect.insetBy(dx: -1.0, dy: -0.5)), with: .color(hallFill))
                context.fill(Path(rect), with: .color(deskFill))
                if layers.showsGenres, let index = MockData.genres.firstIndex(of: circle.genre) {
                    let genreColor = ToolbeltGenreColor.color(for: index)
                    context.fill(Path(rect), with: .color(genreColor))
                }
                if layers.showsFavorites, let favorite {
                    if layers.showsGenres {
                        context.stroke(Path(rect.insetBy(dx: -1.0, dy: -1.0)), with: .color(favorite.color), lineWidth: 2.0)
                    } else {
                        context.fill(Path(rect.insetBy(dx: -1.0, dy: -0.5)), with: .color(favorite.color))
                    }
                }
                if layers.showsVisited, harness.visited.contains(circle.id) {
                    context.fill(Path(rect), with: .color(.black.opacity(0.35)))
                }
            }
        }
    }
}
