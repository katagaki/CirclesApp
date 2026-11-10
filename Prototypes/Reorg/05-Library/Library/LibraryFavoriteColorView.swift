import SwiftUI

struct LibraryFavoriteColorView: View {

    @Environment(Harness.self) var harness
    let color: FavoriteColor

    var body: some View {
        ScrollView {
            CircleGrid(circles: harness.favoriteCircles.filter { harness.favorites[$0.id] == color })
                .padding(16.0)
        }
    }
}
