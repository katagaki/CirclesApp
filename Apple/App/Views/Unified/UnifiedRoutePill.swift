import SwiftUI

struct UnifiedRoutePill: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        HStack(spacing: 5.0) {
            if navigator.isPlanning {
                ProgressView()
                    .controlSize(.mini)
                Text("Route.Planning")
                    .fontWeight(.semibold)
            } else if let route = navigator.route, let step = navigator.currentStep, let stop = navigator.currentStop {
                Image(systemName: step.symbolName)
                    .foregroundStyle(.tint)
                    .contentTransition(.symbolEffect(.replace))
                Text(stop.spaceName)
                    .fontWeight(.semibold)
                Text("\(step.stopIndex + 1)/\(route.stops.count)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            } else if navigator.isTrapped {
                Image(systemName: "hourglass")
                    .foregroundStyle(.tint)
                Text("Route.Trapped.Pill")
                    .fontWeight(.semibold)
            } else {
                Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                    .foregroundStyle(.tint)
                Text("Route.Title")
                    .fontWeight(.semibold)
            }
        }
        .font(.caption)
        .lineLimit(1)
    }
}
