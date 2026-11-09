import SwiftUI

struct WalletMapChrome: View {

    var body: some View {
        HStack(alignment: .top, spacing: 8.0) {
            DayHallControl()
            Spacer(minLength: 0.0)
            OfflinePill()
            RouteStatusPill()
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}
