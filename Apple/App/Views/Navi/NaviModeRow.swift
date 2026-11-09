import SwiftUI

struct NaviModeRow: View {

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14.0) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40.0, height: 40.0)
                    .background(Color.accentColor.gradient, in: .rect(cornerRadius: 12.0, style: .continuous))
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0.0)
                Text("Navi.Go")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14.0)
                    .padding(.vertical, 7.0)
                    .background(Color.green.gradient, in: .capsule)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
