import SwiftUI

struct SpotlightRecentCircle: View {

    let circle: MockCircle

    var body: some View {
        VStack(spacing: 4.0) {
            CircleCut(circle: circle, size: 48.0)
            Text(circle.spaceName)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 60.0)
    }
}
