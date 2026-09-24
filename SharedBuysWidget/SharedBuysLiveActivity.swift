import ActivityKit
import ORBiT
import SwiftUI
import WidgetKit

struct SharedBuysLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SharedBuysAttributes.self) { context in
            lockScreen(context.state)
                .padding(.horizontal, 16.0)
                .padding(.vertical, 14.0)
                .activitySystemActionForegroundColor(.pink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("共有宝物リスト", systemImage: "bag.fill")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4.0)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    avatars(state: context.state)
                        .padding(.trailing, 4.0)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 10.0) {
                        headline(context.state)
                        progress(context.state)
                    }
                    .padding(.horizontal, 4.0)
                    .padding(.top, 4.0)
                }
            } compactLeading: {
                Image(systemName: "bag.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
            } compactTrailing: {
                ring(context.state)
                    .frame(width: 18.0, height: 18.0)
            } minimal: {
                ring(context.state)
                    .frame(width: 18.0, height: 18.0)
            }
            .keylineTint(.pink)
        }
    }

    @ViewBuilder
    func lockScreen(_ state: SharedBuysAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: 6.0) {
                Image(systemName: "bag.fill")
                    .font(.caption2)
                Text("共有宝物リスト")
                    .font(.caption2)
                    .fontWeight(.semibold)
                Spacer(minLength: 8.0)
            }
            .foregroundStyle(.secondary)
            .overlay(alignment: .trailing) { avatars(state: state) }

            headline(state)
            progress(state)
        }
    }

    /// The item being carried, with its cost sitting on the same baseline rather than on a
    /// line of its own: the name is rarely long enough to need the full width, and the
    /// spare room is what made the old layout look empty.
    @ViewBuilder
    func headline(_ state: SharedBuysAttributes.ContentState) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10.0) {
            if state.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.pink)
            }
            Text(state.isComplete ? "担当分はすべて完了しました" : state.nextItemName)
                .font(state.isComplete ? .subheadline : .title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8.0)
            if !state.nextItemDetail.isEmpty {
                Text(state.nextItemDetail)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    func progress(_ state: SharedBuysAttributes.ContentState) -> some View {
        HStack(spacing: 10.0) {
            Capsule()
                .fill(.pink.opacity(0.25))
                .frame(height: 6.0)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(.pink.gradient)
                            .frame(width: proxy.size.width * fraction(state))
                    }
                }
            Text("\(state.boughtCount)/\(state.assignedCount)")
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    /// The compact and minimal presentations have room for one glyph, so the count becomes
    /// the shape of the ring rather than digits nothing could read at that size.
    @ViewBuilder
    func ring(_ state: SharedBuysAttributes.ContentState) -> some View {
        ZStack {
            Circle()
                .stroke(.pink.opacity(0.25), lineWidth: 3.0)
            Circle()
                .trim(from: 0.0, to: fraction(state))
                .stroke(.pink, style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
                .rotationEffect(.degrees(-90.0))
            if state.isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 8.0, weight: .black))
                    .foregroundStyle(.pink)
            }
        }
    }

    @ViewBuilder
    func avatars(state: SharedBuysAttributes.ContentState) -> some View {
        HStack(spacing: -6.0) {
            ForEach(Array(state.memberInitials.prefix(4).enumerated()), id: \.offset) { _, initial in
                Text(initial)
                    .font(.system(size: 10.0, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20.0, height: 20.0)
                    .background(Circle().fill(Color.pink.gradient))
                    .overlay { Circle().strokeBorder(.background, lineWidth: 1.5) }
            }
        }
    }

    func fraction(_ state: SharedBuysAttributes.ContentState) -> Double {
        guard state.assignedCount > 0 else { return 0.0 }
        return min(Double(state.boughtCount) / Double(state.assignedCount), 1.0)
    }
}
