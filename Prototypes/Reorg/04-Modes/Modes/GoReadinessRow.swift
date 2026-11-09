import SwiftUI

struct GoReadinessRow: View {

    let title: String
    let detail: String
    let isReady: Bool

    var body: some View {
        HStack(spacing: 10.0) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "clock.fill")
                .foregroundStyle(isReady ? Color.green : Color.orange)
            Text(title)
            Spacer()
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}
