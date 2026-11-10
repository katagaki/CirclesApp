import SwiftUI

struct LibraryGenreView: View {

    @Environment(Harness.self) var harness
    let genre: LibraryGenre

    var body: some View {
        ScrollView {
            CircleGrid(circles: harness.circlesForSelection.filter { $0.genre == genre.name })
                .padding(16.0)
        }
        .navigationTitle(genre.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
