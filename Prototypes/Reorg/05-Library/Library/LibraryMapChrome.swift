import SwiftUI

struct LibraryMapChrome: View {

    var body: some View {
        HStack(alignment: .top) {
            OfflinePill()
            Spacer(minLength: 8.0)
            DayHallControl()
            Spacer(minLength: 8.0)
            RouteStatusPill()
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}
