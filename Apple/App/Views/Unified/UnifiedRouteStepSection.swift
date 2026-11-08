import AXiS
import SwiftData
import SwiftUI

struct UnifiedRouteStepSection: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Navigator.self) var navigator

    @Query var visits: [CirclesVisitEntry]

    var body: some View {
        if navigator.route != nil, let step = navigator.currentStep,
           let stop = navigator.currentStop, let instruction = navigator.currentInstruction {
            VStack(alignment: .leading, spacing: 12.0) {
                HStack(alignment: .top, spacing: 12.0) {
                    if step.isArrival {
                        UnifiedRouteCircleCut(circleID: stop.circleID)
                    } else {
                        Image(systemName: step.symbolName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40.0, height: 40.0)
                            .background(Color.accentColor, in: .rect(cornerRadius: 12.0))
                            .contentTransition(.symbolEffect(.replace))
                    }
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
                }
                if !navigator.skippedSpaces.isEmpty {
                    Label(
                        String(localized: "Route.Skipped.\(navigator.skippedSpaces.joined(separator: "、"))"),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        }
    }
}
