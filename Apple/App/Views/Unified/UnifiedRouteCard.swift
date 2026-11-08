import AXiS
import RADiUS
import SwiftData
import SwiftUI

struct UnifiedRouteCard: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Navigator.self) var navigator

    @Query var visits: [CirclesVisitEntry]

    var body: some View {
        Group {
            if navigator.isNoStopsAlertPresented {
                UnifiedRouteNoStopsCard {
                    navigator.isNoStopsAlertPresented = false
                }
            } else if navigator.isPlanning {
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
                                if let color = WebCatalogColor(rawValue: stop.colorRawValue), color != .uncolored {
                                    Circle()
                                        .fill(color.backgroundColor())
                                        .frame(width: 8.0, height: 8.0)
                                }
                                Text(stop.spaceName)
                                    .fontWeight(.semibold)
                                Text(stop.name)
                                    .lineLimit(1)
                                Spacer(minLength: 6.0)
                                Text("Route.Stop.\(step.stopIndex + 1).\(route.stops.count)")
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .fixedSize()
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0.0)
                    }
                    if !navigator.skippedSpaces.isEmpty {
                        Label(
                            String(localized: "Route.Skipped.\(navigator.skippedSpaces.joined(separator: "、"))"),
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                    UnifiedRouteControls(
                        isArrival: step.isArrival,
                        canGoBack: navigator.stepIndex > 0,
                        canReportBlocked: navigator.canReportBlocked,
                        onBack: { navigator.previous() },
                        onBlocked: { navigator.reportBlocked(database: database) },
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
