import SwiftUI

struct LayersGenreList: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            ForEach(MockData.genres, id: \.self) { genre in
                let circles = harness.circlesForSelection.filter { $0.genre == genre }
                if !circles.isEmpty {
                    Section {
                        ForEach(circles) { circle in
                            NavigationLink(value: circle) {
                                CircleRow(circle: circle)
                            }
                        }
                    } header: {
                        HStack(spacing: 6.0) {
                            Circle().fill(LayerGenre.color(for: genre)).frame(width: 10.0, height: 10.0)
                            Text(genre)
                            Text("\(circles.count)").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
