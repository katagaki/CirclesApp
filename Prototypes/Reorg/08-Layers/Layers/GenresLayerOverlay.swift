import SwiftUI

struct GenresLayerOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(harness.hall.blocks.indices), id: \.self) { index in
                let genre = LayerGenre.genre(forBlock: index, in: harness.hall)
                let column = layout.columnRect(index)
                Rectangle()
                    .fill(LayerGenre.color(for: genre).opacity(0.45))
                    .frame(width: column.width + 4.0, height: column.height + 4.0)
                    .position(x: column.midX, y: column.midY)
                Text(String(genre.prefix(1)))
                    .font(.system(size: 10.0, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 16.0, height: 16.0)
                    .background(LayerGenre.color(for: genre), in: .circle)
                    .position(x: column.midX, y: column.maxY + 12.0)
            }
        }
    }
}
