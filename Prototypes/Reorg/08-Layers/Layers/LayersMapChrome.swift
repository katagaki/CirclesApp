import SwiftUI

struct LayersMapChrome: View {

    @Environment(Harness.self) var harness

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(alignment: .top, spacing: 8.0) {
                DayHallControl()
                Spacer(minLength: 0.0)
                OfflinePill()
                RouteStatusPill()
            }
            .padding(.horizontal, 16.0)
            LayerChipBar()
        }
        .padding(.top, 4.0)
    }
}
