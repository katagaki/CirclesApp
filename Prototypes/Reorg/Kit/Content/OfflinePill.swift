import SwiftUI

struct OfflinePill: View {

    @Environment(Harness.self) var harness

    var body: some View {
        if harness.isOffline {
            HStack(spacing: 6.0) {
                Image(systemName: "wifi.slash")
                Text("Offline").font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 12.0)
            .frame(height: 36.0)
            .glassEffect(.regular, in: .capsule)
        }
    }
}
