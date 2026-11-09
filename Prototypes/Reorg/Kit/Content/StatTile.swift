import SwiftUI

struct StatTile: View {

    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(value).font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(tint)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12.0)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14.0))
    }
}
