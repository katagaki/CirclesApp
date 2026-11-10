import SwiftUI

struct LibraryStackPanel: View {

    @Environment(Harness.self) var harness
    @Environment(\.stageStyle) var stageStyle
    @Binding var detent: PresentationDetent
    @State var path = NavigationPath()

    var isCompact: Bool {
        stageStyle == .sheet && detent == LibraryRoot.compactDetent
    }

    var body: some View {
        NavigationStack(path: $path) {
            LibrarySidebar(isCompact: isCompact)
                .safeAreaInset(edge: .top, spacing: 0.0) {
                    SearchField()
                        .padding(.horizontal, 16.0)
                        .padding(.top, 16.0)
                        .padding(.bottom, 4.0)
                }
                .contentMargins(.top, 8.0, for: .scrollContent)
                .listSectionSpacing(.compact)
                .toolbarVisibility(.hidden, for: .navigationBar)
                .libraryDestinations()
        }
        .onAppear {
            if let screen = harness.launchScreen, let item = LibraryItem(screen: screen) {
                path.append(item)
            }
        }
        .onChange(of: path.count) { _, count in
            if count > 0 && isCompact { detent = .medium }
        }
        .onChange(of: harness.searchText) { old, new in
            if old.isEmpty && !new.isEmpty && isCompact { detent = .medium }
        }
    }
}
