import SwiftUI

struct CatalogView: View {

    @Environment(Harness.self) var harness
    var showsGenreChips: Bool = true
    @State var genre: String?

    var circles: [MockCircle] {
        harness.circlesForSelection.filter { circle in
            (genre == nil || circle.genre == genre)
                && (harness.searchText.isEmpty || circle.name.localizedCaseInsensitiveContains(harness.searchText)
                    || circle.author.localizedCaseInsensitiveContains(harness.searchText))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12.0) {
                if showsGenreChips {
                    GenreChips(selection: $genre)
                }
                CircleGrid(circles: circles)
                    .padding(.horizontal, 16.0)
            }
            .padding(.vertical, 8.0)
        }
    }
}
