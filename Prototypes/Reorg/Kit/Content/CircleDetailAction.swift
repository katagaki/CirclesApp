import SwiftUI

struct CircleDetailAction: View {

    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4.0) {
                Image(systemName: symbol).font(.title3)
                Text(title).font(.caption.weight(.medium))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 58.0)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14.0))
        }
        .buttonStyle(.plain)
    }
}
