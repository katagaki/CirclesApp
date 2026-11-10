import SwiftUI

struct LibrarySidebar: View {

    @Environment(Harness.self) var harness
    var isCompact: Bool = false
    var selection: LibraryItem?
    var onSelect: ((LibraryItem) -> Void)?

    var showsInlineResults: Bool {
        onSelect == nil && !harness.searchText.isEmpty
    }

    var favoriteColors: [FavoriteColor] {
        FavoriteColor.allCases.filter { color in harness.favorites.values.contains(color) }
    }

    var body: some View {
        List {
            if harness.isGuest {
                Section {
                    GuestBanner()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }
            if showsInlineResults {
                Section("\(harness.librarySearchResults.count) Results") {
                    ForEach(harness.librarySearchResults) { circle in
                        NavigationLink(value: circle) {
                            CircleRow(circle: circle)
                        }
                    }
                }
            } else if isCompact {
                Section {
                    ForEach(LibraryItem.compact) { row($0) }
                }
            } else {
                Section("Browse") {
                    ForEach(LibraryItem.browse) { row($0) }
                }
                Section("My Lists") {
                    row(.favorites)
                    ForEach(favoriteColors) { row(.favoriteColor($0)) }
                    row(.buys)
                    row(.sharedBuys)
                }
                Section("At the Event") {
                    ForEach(LibraryItem.atTheEvent) { row($0) }
                }
                Section("You") {
                    ForEach(LibraryItem.you) { row($0) }
                }
            }
        }
    }

    @ViewBuilder
    func row(_ item: LibraryItem) -> some View {
        if let onSelect {
            Button {
                onSelect(item)
            } label: {
                LibraryRow(item: item)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .listRowBackground(selection == item ? Color.accentColor.opacity(0.18) : nil)
        } else {
            NavigationLink(value: item) {
                LibraryRow(item: item)
            }
        }
    }
}
