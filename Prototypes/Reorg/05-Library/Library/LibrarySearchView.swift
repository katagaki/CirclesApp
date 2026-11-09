import SwiftUI

struct LibrarySearchView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section {
                SearchField()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            if harness.searchText.isEmpty {
                Section("Try") {
                    ForEach(["Tech", "東A", "Music"], id: \.self) { suggestion in
                        Button(suggestion, systemImage: "magnifyingglass") {
                            harness.searchText = suggestion
                        }
                    }
                }
            } else {
                Section("\(harness.librarySearchResults.count) Results") {
                    ForEach(harness.librarySearchResults) { circle in
                        NavigationLink(value: circle) {
                            CircleRow(circle: circle)
                        }
                    }
                }
            }
        }
    }
}
