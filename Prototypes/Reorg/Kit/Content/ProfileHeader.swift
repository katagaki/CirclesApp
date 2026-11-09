import SwiftUI

struct ProfileHeader: View {

    @Environment(Harness.self) var harness

    var body: some View {
        HStack(spacing: 14.0) {
            ProfileAvatar(size: 56.0)
            VStack(alignment: .leading, spacing: 3.0) {
                Text(harness.isGuest ? "Guest" : "Justin").font(.title3.weight(.bold))
                Text(harness.isGuest ? "Not signed in" : "Circle.ms Gold Member")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
        }
    }
}
