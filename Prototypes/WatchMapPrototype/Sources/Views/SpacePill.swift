import SwiftUI

struct SpacePill: View {

    let label: String
    let color: FavoriteColor?
    var fontSize: CGFloat = 20.0
    var isVisited: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .strikethrough(isVisited, pattern: .solid, color: .secondary)
            .foregroundStyle(foreground)
            .padding(.horizontal, fontSize * 0.32)
            .padding(.vertical, fontSize * 0.08)
            .background(Capsule().fill(fill))
    }

    private var foreground: AnyShapeStyle {
        if isVisited { return AnyShapeStyle(.secondary) }
        guard let color else { return AnyShapeStyle(.primary) }
        return AnyShapeStyle(color.foreground)
    }

    private var fill: AnyShapeStyle {
        if isVisited { return AnyShapeStyle(.quaternary) }
        guard let color else { return AnyShapeStyle(.ultraThinMaterial) }
        return AnyShapeStyle(color.color)
    }
}
