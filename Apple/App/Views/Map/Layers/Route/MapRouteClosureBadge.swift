import SwiftUI

struct MapRouteClosureBadge: View {

    let size: CGFloat
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: size * 1.8, height: size * 1.8)
            }
            Circle()
                .fill(Color.primary)
            Circle()
                .strokeBorder(Color(uiColor: .systemBackground), lineWidth: size * 0.1)
            Image(systemName: "nosign")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(Color(uiColor: .systemBackground))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: size * 0.08)
    }
}
