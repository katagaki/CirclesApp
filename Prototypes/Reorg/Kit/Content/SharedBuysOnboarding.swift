import SwiftUI

struct SharedBuysOnboarding: View {

    @Environment(Harness.self) var harness

    var body: some View {
        VStack(spacing: 14.0) {
            MemberStack(size: 44.0)
            Text("Shop together").font(.title3.weight(.bold))
            Text("Share your Buys list with friends, split up the circles, and see what's been bought as it happens.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("Start a List") { harness.isSharedBuysActive = true }
                    .buttonStyle(.glassProminent)
                Button("Scan to Join") {}
                    .buttonStyle(.glass)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12.0)
    }
}
