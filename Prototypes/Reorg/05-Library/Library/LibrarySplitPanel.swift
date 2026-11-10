import SwiftUI

struct LibrarySplitPanel: View {

    @Environment(Harness.self) var harness
    @State var selection: LibraryItem = .allCircles
    @State var path = NavigationPath()

    var body: some View {
        HStack(spacing: 0.0) {
            LibrarySidebar(selection: selection) { item in
                selection = item
                path = NavigationPath()
            }
            .safeAreaPadding(.top, 8.0)
            .frame(width: 236.0)
            Divider()
            NavigationStack(path: $path) {
                LibraryContent(item: selection)
                    .libraryDestinations()
            }
            .id(selection)
        }
        .onAppear {
            if let screen = harness.launchScreen, let item = LibraryItem(screen: screen) {
                selection = item
            }
        }
    }
}
