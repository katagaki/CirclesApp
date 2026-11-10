import SwiftUI

struct LibraryGenresView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List(MockData.genres, id: \.self) { genre in
            NavigationLink(value: LibraryGenre(name: genre)) {
                LabeledContent(genre, value: "\(harness.circlesForSelection.filter { $0.genre == genre }.count)")
            }
        }
    }
}
