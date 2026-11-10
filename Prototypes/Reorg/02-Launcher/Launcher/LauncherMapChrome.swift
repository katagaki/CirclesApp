import SwiftUI

struct LauncherMapChrome: View {

    @Environment(Harness.self) var harness

    var body: some View {
        HStack(alignment: .top) {
            DayHallControl()
            Spacer(minLength: 8.0)
            VStack(alignment: .trailing, spacing: 8.0) {
                OfflinePill()
                RouteStatusPill()
            }
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}
