import SwiftUI

struct LauncherTile: View {

    let feature: Feature
    let subtitle: String
    var isLive: Bool = false

    var body: some View {
        NavigationLink(value: feature) {
            VStack(alignment: .leading, spacing: 8.0) {
                HStack(spacing: 10.0) {
                    Image(systemName: feature.symbol)
                        .font(.system(size: 15.0, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32.0, height: 32.0)
                        .background(feature.tint.gradient, in: .circle)
                    Text(feature.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0.0)
                    if isLive {
                        Circle().fill(.green).frame(width: 8.0, height: 8.0)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12.0)
            .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 18.0))
        }
        .buttonStyle(.plain)
    }
}
