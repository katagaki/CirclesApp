import SwiftUI

/// The circle the route is heading to, shown on every step so the visitor always knows
/// where the directions lead.
struct NaviUpcomingCircle: View {

    let stop: RouteStop
    let isArrival: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12.0) {
            UnifiedRouteCircleCut(circleID: stop.circleID)
            VStack(alignment: .leading, spacing: 4.0) {
                Text(stop.spaceName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(stop.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 0.0)
                if isArrival {
                    NaviMarkVisitedButton()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80.0, alignment: .topLeading)
        }
        .padding(12.0)
        .background(.fill.quaternary, in: .rect(cornerRadius: 26.0))
        .padding(.horizontal, -3.5)
    }
}
