import SwiftUI

struct GuestBanner: View {

    @Environment(Harness.self) var harness

    var body: some View {
        if harness.isGuest {
            HStack(spacing: 12.0) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text("You're browsing as a guest").font(.subheadline.weight(.semibold))
                    Text("Sign in with Circle.ms to see the full catalog and sync favorites.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0.0)
                Button("Sign In") { harness.isGuest = false }
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
            }
            .padding(12.0)
            .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: 16.0))
        }
    }
}
