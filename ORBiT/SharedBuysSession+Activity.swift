#if os(iOS)
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

    /// Re-attaches to an activity that outlived the process, and ends any that no longer
    /// belongs to this session.
    ///
    /// An activity is addressable only through the in-memory `activity` handle, so one
    /// left over from a room joined on a previous launch — or from a session the app no
    /// longer holds a snapshot of — can never be reached by `endActivity()`. This is the
    /// only place the Lock Screen is reconciled against the session from scratch, so it
    /// runs on every restore, including the one that finds no room to come back to.
    public func adoptActivity() {
        let strays = Activity<SharedBuysAttributes>.activities
            .filter { $0.attributes.roomID != roomID }
            .map(\.id)
        for stray in strays {
            note("stray live activity ended")
            Task { await Self.finish(stray) }
        }
        if activity == nil, let roomID,
           let existing = Activity<SharedBuysAttributes>.activities
            .first(where: { $0.attributes.roomID == roomID }) {
            activity = existing
            note("live activity adopted")
        }
        updateActivity()
    }

    /// Starts an activity, but only for a session that has something to put in it.
    ///
    /// Entering a room is not the trigger: a room is created and joined empty, and the
    /// list is shared per member, so a room full of someone else's items warrants
    /// nothing here either. `updateActivity()` calls this once the first item lands on
    /// this member.
    public func startActivity() {
        let state = activityState
        guard isActive, state.assignedCount > 0 else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            note("live activity not permitted")
            return
        }
        guard liveActivity == nil, let roomID else { return }
        do {
            activity = try Activity.request(
                attributes: SharedBuysAttributes(roomID: roomID),
                content: ActivityContent(state: state, staleDate: nil)
            )
            note("live activity started")
        } catch {
            note("live activity failed: \(error.localizedDescription)")
        }
    }

    /// Reconciles the activity with the session: one exists exactly while this member is
    /// carrying something. Called after every change, local or ingested, so the activity
    /// appears with the first item assigned here and goes away with the last one —
    /// unassigned, removed, or the whole room left.
    public func updateActivity() {
        let state = activityState
        guard isActive, state.assignedCount > 0 else {
            endActivity()
            return
        }
        guard let identifier = liveActivity?.id else {
            startActivity()
            return
        }
        Task { await Self.push(state, to: identifier) }
    }

    public func endActivity() {
        guard let identifier = liveActivity?.id else {
            activity = nil
            return
        }
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
#else
import Foundation

/// The Mac harness stands in for a second iOS device (§15) and has no ActivityKit.
/// The session drives the activity from half a dozen places; stubs keep those call
/// sites identical rather than scattering `#if os(iOS)` through the sync engine.
@MainActor
public extension SharedBuysSession {
    var activityCount: Int { 0 }
    var activitiesEnabled: Bool { false }
    func adoptActivity() {}
    func startActivity() {}
    func updateActivity() {}
    func endActivity() {}
}
#endif
