//
//  SharedBuysLiveActivity.swift
//  SharedBuysWidget
//

import ActivityKit
import ORBiT
import SwiftUI
import WidgetKit

struct SharedBuysLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SharedBuysAttributes.self) { context in
            lockScreen(context.state)
                .padding(16.0)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("共有宝物リスト", systemImage: "bag.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(progressText(context.state))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4.0) {
                        Text(headline(context.state))
                            .font(.headline)
                        if !context.state.nextItemDetail.isEmpty {
                            Text(context.state.nextItemDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        progressBar(context.state)
                    }
                }
            } compactLeading: {
                Image(systemName: "bag.fill")
                    .foregroundStyle(.pink)
            } compactTrailing: {
                Text(progressText(context.state))
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "bag.fill")
                    .foregroundStyle(.pink)
            }
        }
    }

    @ViewBuilder
    func lockScreen(_ state: SharedBuysAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(spacing: 6.0) {
                Image(systemName: "bag.fill")
                    .font(.caption)
                Text("共有宝物リスト")
                    .font(.caption2)
                    .fontWeight(.heavy)
                Spacer()
                HStack(spacing: -6.0) {
                    ForEach(state.memberInitials.prefix(4), id: \.self) { initial in
                        Circle()
                            .fill(Color.pink.gradient)
                            .frame(width: 20.0, height: 20.0)
                            .overlay {
                                Text(initial)
                                    .font(.system(size: 10.0, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .overlay { Circle().strokeBorder(.black.opacity(0.4), lineWidth: 1.5) }
                    }
                }
            }
            .foregroundStyle(.white.opacity(0.7))

            Text(headline(state))
                .font(.headline)
                .foregroundStyle(.white)

            if !state.nextItemDetail.isEmpty {
                Text(state.nextItemDetail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 8.0) {
                progressBar(state)
                Text(progressText(state))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    func progressBar(_ state: SharedBuysAttributes.ContentState) -> some View {
        ProgressView(
            value: Double(state.boughtCount),
            total: Double(max(state.assignedCount, 1))
        )
        .tint(.pink)
    }

    func headline(_ state: SharedBuysAttributes.ContentState) -> String {
        state.isComplete ? "担当分はすべて完了しました" : state.nextItemName
    }

    func progressText(_ state: SharedBuysAttributes.ContentState) -> String {
        "\(state.boughtCount)/\(state.assignedCount)"
    }
}
