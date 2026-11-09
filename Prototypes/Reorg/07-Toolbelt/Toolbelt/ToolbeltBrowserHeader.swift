import SwiftUI

struct ToolbeltBrowserHeader: View {

    @Binding var segment: ToolbeltSegment
    let showsGuestBanner: Bool

    var body: some View {
        VStack(spacing: 10.0) {
            SearchField()
            Picker("Browse", selection: $segment) {
                ForEach(ToolbeltSegment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            if showsGuestBanner {
                GuestBanner()
            }
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 16.0)
        .padding(.bottom, 8.0)
    }
}
