import SwiftUI

struct GoSectionTitle: View {

    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.headline)
            Spacer()
            if let detail {
                Text(detail).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 10.0)
        .padding(.horizontal, 4.0)
    }
}
