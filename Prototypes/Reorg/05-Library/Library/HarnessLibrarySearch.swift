import Foundation

extension Harness {
    var librarySearchResults: [MockCircle] {
        MockData.circles.filter { circle in
            [circle.name, circle.author, circle.genre, circle.spaceName]
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
