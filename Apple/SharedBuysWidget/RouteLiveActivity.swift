import ActivityKit
import AppIntents
import ORBiT
import SwiftUI
import WidgetKit

struct RouteLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RouteAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.blue)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    turnIcon(context.state, size: 44.0)
                        .padding(.leading, 4.0)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.progress)
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 4.0)
                }
                DynamicIslandExpandedRegion(.center) {
                    stopLine(context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center, spacing: 10.0) {
                        Text(context.state.instruction)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4.0)
                        stepButtons
                    }
                    .padding(.horizontal, 4.0)
                }
            } compactLeading: {
                Image(systemName: context.state.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(context.state.isArriving ? .red : .blue)
            } compactTrailing: {
                Text(context.state.stopSpace)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            } minimal: {
                Image(systemName: context.state.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(context.state.isArriving ? .red : .blue)
            }
            .keylineTint(.blue)
        }
    }

    @ViewBuilder
    func lockScreen(_ context: ActivityViewContext<RouteAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(spacing: 6.0) {
                Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                    .font(.caption2)
                Text(context.attributes.title)
                    .font(.caption2.weight(.semibold))
                if !context.attributes.hallName.isEmpty {
                    Text(context.attributes.hallName)
                        .font(.caption2)
                }
                Spacer(minLength: 8.0)
                Text(context.state.progress)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
            .background(Color.blue.opacity(0.75))

            HStack(alignment: .center, spacing: 12.0) {
                turnIcon(context.state, size: 48.0)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(context.state.instruction)
                        .font(.headline)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                    stopLine(context.state)
                }
                Spacer(minLength: 4.0)
                stepButtons
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
        }
    }

    func turnIcon(_ state: RouteAttributes.ContentState, size: CGFloat) -> some View {
        Image(systemName: state.symbolName)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(state.isArriving ? Color.red : Color.blue, in: .rect(cornerRadius: size * 0.28))
    }

    func stopLine(_ state: RouteAttributes.ContentState) -> some View {
        HStack(spacing: 6.0) {
            Text(state.stopSpace)
                .fontWeight(.semibold)
            Text(state.stopName)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    var stepButtons: some View {
        HStack(spacing: 6.0) {
            Button(intent: RouteStepIntent(isForward: false)) {
                Image(systemName: "chevron.backward")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36.0, height: 36.0)
            }
            .buttonStyle(.plain)
            .background(.quaternary, in: .circle)
            Button(intent: RouteStepIntent(isForward: true)) {
                Image(systemName: "chevron.forward")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36.0, height: 36.0)
            }
            .buttonStyle(.plain)
            .background(Color.blue, in: .circle)
        }
    }
}

struct SharedBuysWidgetAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [ORBiTAppIntents.self]
    }
}
