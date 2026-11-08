import RADiUS
import SwiftUI

struct RoutePriorityColorCell: View {

    let color: WebCatalogColor
    let rank: Int?
    let count: Int

    var body: some View {
        VStack(spacing: 6.0) {
            ZStack {
                Circle()
                    .fill(color.backgroundColor().opacity(rank == nil ? 0.3 : 1.0))
                if rank == nil {
                    Image(systemName: "xmark")
                        .font(.system(size: 20.0, weight: .bold, design: .rounded))
                        .foregroundStyle(color.backgroundColor())
                }
                if let rank {
                    Text("\(rank)")
                        .font(.system(size: 22.0, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(color.foregroundColor())
                        .contentTransition(.numericText())
                }
            }
            .frame(width: 56.0, height: 56.0)
            .shadow(color: .black.opacity(rank == nil ? 0.0 : 0.15), radius: 3.0, y: 1.0)
            Text("Route.Priority.Count.\(count)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .opacity(rank != nil && count == 0 ? 0.45 : 1.0)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(color.name()))
        .accessibilityValue(Text("Route.Priority.Count.\(count)"))
        .accessibilityAddTraits(rank == nil ? [] : .isSelected)
    }
}
