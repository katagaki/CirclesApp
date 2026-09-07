//
//  SharedBuysSession+Activity.swift
//  CiRCLES
//

import ActivityKit
import Foundation

@MainActor
public extension SharedBuysSession {

    public var activityState: SharedBuysAttributes.ContentState {
        let mine = items.filter { $0.assignee == actorPID }
        let pending = mine.filter { $0.status == .pending }
        let next = pending.first
        return SharedBuysAttributes.ContentState(
            nextItemName: next?.name ?? "担当分はすべて完了しました",
            nextItemDetail: next.map { "¥\($0.cost)" } ?? "",
            boughtCount: mine.filter { $0.status == .bought }.count,
            assignedCount: mine.count,
            memberInitials: members.values.sorted().map { String($0.prefix(1)) }
        )
    }

    public var activityCount: Int {
        Activity<SharedBuysAttributes>.activities.count
    }

    public var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public var liveActivity: Activity<SharedBuysAttributes>? {
        activity as? Activity<SharedBuysAttributes>
    }

    public func adoptActivity() {
        guard activity == nil, isActive else { return }
        guard let existing = Activity<SharedBuysAttributes>.activities
            .first(where: { $0.attributes.roomID == roomID }) else {
            startActivity()
            return
        }
        activity = existing
        note("live activity adopted")
        updateActivity()
    }

    public func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            note("live activity not permitted")
            return
        }
        guard liveActivity == nil, let roomID else { return }
        do {
            activity = try Activity.request(
                attributes: SharedBuysAttributes(roomID: roomID),
                content: ActivityContent(state: activityState, staleDate: nil)
            )
            note("live activity started")
        } catch {
            note("live activity failed: \(error.localizedDescription)")
        }
    }

    public func updateActivity() {
        guard let identifier = liveActivity?.id else { return }
        let state = activityState
        Task { await Self.push(state, to: identifier) }
    }

    public func endActivity() {
        guard let identifier = liveActivity?.id else { return }
        activity = nil
        Task { await Self.finish(identifier) }
        note("live activity ended")
    }

    private nonisolated static func push(
        _ state: SharedBuysAttributes.ContentState,
        to identifier: String
    ) async {
        guard let live = Activity<SharedBuysAttributes>.activities
            .first(where: { $0.id == identifier }) else { return }
        await live.update(ActivityContent(state: state, staleDate: nil))
    }

    private nonisolated static func finish(_ identifier: String) async {
        guard let live = Activity<SharedBuysAttributes>.activities
            .first(where: { $0.id == identifier }) else { return }
        await live.end(nil, dismissalPolicy: .immediate)
    }
}
