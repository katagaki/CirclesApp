import ActivityKit
import ORBiT
import SwiftUI
import WidgetKit

struct SharedBuysLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SharedBuysAttributes.self) { context in
            lockScreen(context.state)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(Self.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("共同購入リスト", systemImage: "bag.fill")
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
                        VStack(alignment: .leading, spacing: 4.0) {
                            circle(context.state)
                            headline(context.state)
                        }
                        progress(context.state)
                    }
                    .padding(.horizontal, 4.0)
                    .padding(.top, 4.0)
                }
            } compactLeading: {
                Image(systemName: "bag.fill")
                    .font(.caption)
                    .foregroundStyle(Self.accent)
            } compactTrailing: {
                ring(context.state)
                    .frame(width: 18.0, height: 18.0)
            } minimal: {
                ring(context.state)
                    .frame(width: 18.0, height: 18.0)
            }
            .keylineTint(Self.accent)
        }
    }

    @ViewBuilder
    func lockScreen(_ state: SharedBuysAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(spacing: 5.0) {
                Image(systemName: "bag.fill")
                    .frame(width: 18.0)
                Text("共同購入リスト")
                Spacer(minLength: 12.0)
                avatars(state: state)
            }
            .font(.system(size: 13.0, weight: .semibold))
            .fontDesign(.rounded)
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
            .background(Self.accent.opacity(0.7))

            HStack(alignment: .center, spacing: 12.0) {
                if let key = state.imageKey, let image = SharedBuysActivityImageStore.image(for: key) {
                    SharedBuysActivityPhoto(image: image)
                }
                VStack(alignment: .leading, spacing: 12.0) {
                    VStack(alignment: .leading, spacing: 4.0) {
                        circle(state)
                        headline(state)
                    }
                    progress(state)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
        }
    }

    @ViewBuilder
    func circle(_ state: SharedBuysAttributes.ContentState) -> some View {
        if !state.isComplete, let name = state.circleName, !name.isEmpty {
            HStack(spacing: 6.0) {
                if let space = state.circleSpace, !space.isEmpty {
                    Text(space)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                Text(name)
                    .lineLimit(1)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
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
                    .foregroundStyle(Self.accent)
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
                .fill(Self.accent.opacity(0.25))
                .frame(height: 6.0)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Self.accent.gradient)
                            .frame(width: proxy.size.width * fraction(state))
                    }
                }
            Text("\(state.boughtCount)/\(state.assignedCount)")
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            if state.canFlip {
                SharedBuysFlipButtons()
            }
        }
    }

    /// The compact and minimal presentations have room for one glyph, so the count becomes
    /// the shape of the ring rather than digits nothing could read at that size.
    @ViewBuilder
    func ring(_ state: SharedBuysAttributes.ContentState) -> some View {
        ZStack {
            Circle()
                .stroke(Self.accent.opacity(0.25), lineWidth: 3.0)
            Circle()
                .trim(from: 0.0, to: fraction(state))
                .stroke(Self.accent, style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
                .rotationEffect(.degrees(-90.0))
            if state.isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 8.0, weight: .black))
                    .foregroundStyle(Self.accent)
            }
        }
    }

    @ViewBuilder
    func avatars(state: SharedBuysAttributes.ContentState) -> some View {
        HStack(spacing: -6.0) {
            ForEach(Array(state.memberNames.prefix(4).enumerated()), id: \.offset) { _, name in
                MemberInitial(nickname: name, size: 20.0)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
            }
        }
    }

    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(displayP3Red: 0.544, green: 0.647, blue: 1.0, alpha: 1.0)
            : UIColor(displayP3Red: 0.361, green: 0.488, blue: 1.0, alpha: 1.0)
    })

    func fraction(_ state: SharedBuysAttributes.ContentState) -> Double {
        guard state.assignedCount > 0 else { return 0.0 }
        return min(Double(state.boughtCount) / Double(state.assignedCount), 1.0)
    }
}
