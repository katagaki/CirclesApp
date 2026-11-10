import SwiftUI

struct ModesMapChrome: View {

    @Environment(Harness.self) var harness
    @Binding var mode: AppMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            HStack(alignment: .top) {
                ModeSwitch(mode: $mode)
                Spacer(minLength: 8.0)
                DayHallControl()
            }
            HStack(alignment: .top) {
                if mode == .go {
                    RouteStatusPill()
                }
                Spacer(minLength: 8.0)
                if harness.isOffline {
                    OfflinePill()
                } else if mode == .go {
                    GoReadinessPill()
                }
            }
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}
