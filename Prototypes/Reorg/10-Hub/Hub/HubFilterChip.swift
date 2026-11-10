import SwiftUI

struct HubFilterChip: View {

    let title: String
    var symbol: String?
    var tint: Color = .accentColor
    var swatch: Color?
    var count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5.0) {
                if let swatch {
                    Rectangle()
                        .fill(swatch)
                        .frame(width: 10.0, height: 10.0)
                        .overlay(Rectangle().stroke(.white, lineWidth: isSelected ? 1.0 : 0.0))
                }
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? Color.white : tint)
                }
                Text(title)
                if let count {
                    Text("\(count)").foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12.0)
            .padding(.vertical, 6.0)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(isSelected ? Color.accentColor : Color(uiColor: .tertiarySystemFill), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
