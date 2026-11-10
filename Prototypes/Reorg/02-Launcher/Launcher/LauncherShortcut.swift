import SwiftUI

struct LauncherShortcut: View {

    let feature: Feature
    let title: String

    var body: some View {
        NavigationLink(value: feature) {
            VStack(spacing: 6.0) {
                Image(systemName: feature.symbol)
                    .font(.system(size: 20.0, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52.0, height: 52.0)
                    .background(feature.tint.gradient, in: .circle)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
