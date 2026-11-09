import SwiftUI

struct CircleRow: View {

    @Environment(Harness.self) var harness
    let circle: MockCircle

    var body: some View {
        HStack(spacing: 12.0) {
            CircleCut(circle: circle, size: 36.0)
            VStack(alignment: .leading, spacing: 3.0) {
                Text(circle.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6.0) {
                    SpaceBadge(circle: circle)
                    Text(circle.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0.0)
            if let favorite = harness.favorites[circle.id] {
                Image(systemName: "star.fill")
                    .foregroundStyle(favorite.color)
                    .shadow(color: .black.opacity(0.2), radius: 0.5)
            }
            if harness.visited.contains(circle.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .contentShape(.rect)
    }
}
