import RADiUS
import SwiftUI

struct RoutePriorityRow: View {

    let color: WebCatalogColor
    let rank: Int?
    let count: Int

    var body: some View {
        HStack(spacing: 12.0) {
            ZStack {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(color.backgroundColor())
                if let rank {
                    Text("\(rank)")
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(color.foregroundColor())
                }
            }
            .frame(width: 32.0, height: 32.0)
            Text(color.name())
            Spacer(minLength: 8.0)
            Text("Route.Priority.Count.\(count)")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .opacity(rank == nil ? 0.5 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(color.name()))
        .accessibilityValue(Text("Route.Priority.Count.\(count)"))
    }
}
