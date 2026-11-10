import SwiftUI

struct SpotlightRowLabel: View {

    let title: String
    var subtitle: String?
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12.0) {
            Image(systemName: symbol)
                .font(.system(size: 14.0, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30.0, height: 30.0)
                .background(tint.gradient, in: .rect(cornerRadius: 8.0))
            VStack(alignment: .leading, spacing: 1.0) {
                Text(title).foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
    }
}
