import SwiftUI

struct HubMapChrome: View {

    @Binding var showsMe: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8.0) {
            DayHallControl()
            Spacer(minLength: 0.0)
            OfflinePill()
            Button {
                showsMe = true
            } label: {
                ProfileAvatar(size: 36.0)
                    .padding(4.0)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("Me")
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}
