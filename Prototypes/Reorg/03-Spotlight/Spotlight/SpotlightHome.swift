import SwiftUI

struct SpotlightHome: View {

    @Environment(Harness.self) var harness
    @Environment(\.stageStyle) var stageStyle
    @Binding var path: NavigationPath

    var body: some View {
        List {
            if harness.isGuest {
                Section {
                    GuestBanner()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }
            if harness.searchText.isEmpty {
                SpotlightSuggestions()
            } else {
                SpotlightResults(path: $path)
            }
        }
        .listSectionSpacing(.compact)
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .top, spacing: 0.0) {
            VStack(spacing: 12.0) {
                SpotlightField()
                if harness.searchText.isEmpty || stageStyle == .panel {
                    SpotlightChips()
                }
            }
            .padding(.top, 16.0)
            .padding(.bottom, 8.0)
        }
    }
}
