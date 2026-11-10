import SwiftUI

struct NaviModeRow: View {

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: NaviModeIcon.Kind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14.0) {
                NaviModeIcon(kind: icon)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0.0)
                Text("Navi.Go")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18.0)
                    .frame(height: 40.0)
                    .background(Color.accentColor, in: .capsule)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
