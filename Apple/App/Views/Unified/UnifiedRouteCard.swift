import SwiftData
import SwiftUI

struct UnifiedRouteCard: View {

    @Environment(Events.self) var planner
    @Environment(Navigator.self) var navigator

    @Query var visits: [CirclesVisitEntry]

    var body: some View {
        Group {
            if navigator.isPlanning {
                HStack(spacing: 10.0) {
                    ProgressView()
                    Text("Route.Planning")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 16.0)
                .padding(.vertical, 12.0)
                .glassEffect(.regular, in: .capsule)
            } else if let route = navigator.route, let step = navigator.currentStep,
                      let stop = navigator.currentStop, let instruction = navigator.currentInstruction {
                VStack(alignment: .leading, spacing: 12.0) {
                    HStack(alignment: .top, spacing: 12.0) {
                        Image(systemName: step.symbolName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 48.0, height: 48.0)
                            .background(step.isArrival ? Color.red : Color.accentColor, in: .rect(cornerRadius: 14.0))
                            .contentTransition(.symbolEffect(.replace))
                        VStack(alignment: .leading, spacing: 4.0) {
                            Text(instruction)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                                .contentTransition(.opacity)
                            HStack(spacing: 6.0) {
                                Text(stop.spaceName)
                                    .fontWeight(.semibold)
                                Text(stop.name)
                                    .lineLimit(1)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0.0)
                    }
                    UnifiedRouteControls(
                        progress: String(localized: "Route.Stop.\(step.stopIndex + 1).\(route.stops.count)"),
                        isArrival: step.isArrival,
                        canGoBack: navigator.stepIndex > 0,
                        onBack: { navigator.previous() },
                        onNext: {
                            if step.isArrival {
                                navigator.markVisitedAndContinue(
                                    eventNumber: planner.activeEventNumber,
                                    visitedCircleIDs: Set(visits.map(\.circleID))
                                )
                            } else {
                                navigator.next()
                            }
                        }
                    )
                }
                .padding(14.0)
                .glassEffect(.regular, in: .rect(cornerRadius: 22.0))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: navigator.stepIndex)
    }
}
