import SwiftUI

struct SpaceBadge: View {

    let circle: MockCircle

    var body: some View {
        Text(circle.spaceName)
            .font(.caption2.weight(.semibold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 6.0)
            .padding(.vertical, 2.0)
            .background(circle.hall.accent, in: .capsule)
    }
}
