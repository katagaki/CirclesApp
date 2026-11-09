import SwiftUI

struct CircleGridCell: View {

    @Environment(Harness.self) var harness
    let circle: MockCircle

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            CircleCut(circle: circle, size: 70.0)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    if let favorite = harness.favorites[circle.id] {
                        Rectangle()
                            .fill(favorite.color)
                            .frame(width: 12.0, height: 12.0)
                            .overlay(Rectangle().stroke(.white, lineWidth: 1.5))
                            .padding(4.0)
                    }
                }
            Text(circle.spaceName)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
