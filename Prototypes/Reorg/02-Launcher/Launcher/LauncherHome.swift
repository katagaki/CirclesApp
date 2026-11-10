import SwiftUI

struct LauncherHome: View {

    @Environment(Harness.self) var harness
    let isCompact: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18.0) {
                if isCompact {
                    LauncherShortcuts()
                }
                GuestBanner()
                if harness.searchText.isEmpty {
                    if !isCompact {
                        if harness.isNavigating {
                            NextStopCard()
                        }
                        LauncherTiles()
                    }
                } else {
                    LauncherSearchResults()
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
        }
        .safeAreaInset(edge: .top, spacing: 0.0) {
            LauncherHeader()
                .padding(.horizontal, 16.0)
                .padding(.top, 16.0)
                .padding(.bottom, 12.0)
        }
    }
}
