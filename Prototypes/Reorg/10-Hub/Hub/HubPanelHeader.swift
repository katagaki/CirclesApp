import SwiftUI

struct HubPanelHeader: View {

    @Environment(Harness.self) var harness
    @Binding var segment: HubSegment
    @Binding var path: NavigationPath

    var body: some View {
        VStack(spacing: 10.0) {
            HStack(spacing: 10.0) {
                Picker("Section", selection: $segment) {
                    ForEach(HubSegment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                if !harness.isNavigating {
                    HubStartRouteButton()
                }
            }
            if harness.isNavigating {
                HubLiveRouteBar(path: $path)
            }
            if segment == .circles {
                SearchField()
            }
            GuestBanner()
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 16.0)
        .padding(.bottom, 8.0)
    }
}
