import SwiftUI

/// Every way to the remaining favourites is closed. There is nothing to do but wait, so
/// this says so plainly instead of offering choices.
struct UnifiedRouteTrappedSection: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text("Route.Trapped.Title")
                .font(.headline)
            Text("Route.Trapped.Message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
