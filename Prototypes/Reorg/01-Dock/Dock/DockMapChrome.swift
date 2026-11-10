import SwiftUI

struct DockMapChrome: View {

    @Environment(Harness.self) var harness

    var body: some View {
        HStack(alignment: .top) {
            OfflinePill()
            Spacer(minLength: 8.0)
            DayHallControl()
            Spacer(minLength: 8.0)
            if harness.isNavigating {
                RouteStatusPill()
            } else {
                Button {
                    harness.isNavigating = true
                } label: {
                    Image(systemName: Feature.navigation.symbol)
                        .font(.title3)
                        .frame(width: 44.0, height: 44.0)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}
