import SwiftUI

extension View {
    func libraryDestinations() -> some View {
        self
            .featureDestinations()
            .navigationDestination(for: LibraryItem.self) { item in
                LibraryContent(item: item)
            }
            .navigationDestination(for: LibraryGenre.self) { genre in
                LibraryGenreView(genre: genre)
            }
    }
}
