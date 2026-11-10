import SwiftUI

struct ListIconLabel: View {

    let title: LocalizedStringKey
    var subtitle: String?
    let image: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2.0) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            ListIconImage(name: image)
        }
    }
}
