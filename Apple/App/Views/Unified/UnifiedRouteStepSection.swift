import AXiS
import SwiftUI

struct UnifiedRouteStepSection: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        if navigator.route != nil, let step = navigator.currentStep,
           let stop = navigator.currentStop, let instruction = navigator.currentInstruction {
            VStack(alignment: .leading, spacing: 12.0) {
                HStack(alignment: .top, spacing: 12.0) {
                    if step.isArrival {
                        UnifiedRouteCircleCut(circleID: stop.circleID)
                    } else {
                        Image(systemName: step.symbolName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 48.0, height: 48.0)
                            .background(Color.accentColor, in: .rect(cornerRadius: 14.0))
                            .frame(width: 56.0, alignment: .leading)
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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 80.0, alignment: .top)
                if !navigator.skippedSpaces.isEmpty {
                    Label(
                        String(localized: "Route.Skipped.\(navigator.skippedSpaces.joined(separator: "、"))"),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                if step.isArrival {
                    NaviMarkVisitedButton()
                }
                NaviBuysCarousel(circleID: stop.circleID)
            }
        }
    }
}
