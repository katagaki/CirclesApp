import SwiftUI

struct UnifiedRoutePill: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        HStack(spacing: 6.0) {
            if navigator.isPlanning {
                ProgressView()
                    .controlSize(.small)
                Text("Route.Planning")
                    .fontWeight(.semibold)
            } else if let route = navigator.route, let step = navigator.currentStep, let stop = navigator.currentStop {
                Image(systemName: step.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 20.0, height: 20.0)
                    .background(Color.accentColor, in: .circle)
                    .contentTransition(.symbolEffect(.replace))
                Text(stop.spaceName)
                    .fontWeight(.semibold)
                Text("\(step.stopIndex + 1)/\(route.stops.count)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .lineLimit(1)
    }
}
