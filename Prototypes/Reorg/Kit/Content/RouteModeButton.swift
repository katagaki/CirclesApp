import SwiftUI

struct RouteModeButton: View {

    @Environment(Harness.self) var harness
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        Button {
            harness.routeStep = 1
            harness.isNavigating = true
        } label: {
            HStack(spacing: 12.0) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 32.0)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(title).font(.body.weight(.semibold))
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
