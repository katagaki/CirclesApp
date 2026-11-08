import AXiS
import Foundation
#if os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
import ORBiT
import UIKit

extension Navigator {

    private var activityState: RouteAttributes.ContentState? {
        guard let route, let currentStep, let currentStop, let currentInstruction else { return nil }
        return RouteAttributes.ContentState(
            instruction: currentInstruction,
            symbolName: currentStep.symbolName,
            stopSpace: currentStop.spaceName,
            stopName: currentStop.name,
            circleID: currentStop.circleID,
            progress: String(localized: "Route.Stop.\(currentStep.stopIndex + 1).\(route.stops.count)"),
            stopNumber: currentStep.stopIndex + 1,
            stopCount: route.stops.count,
            isArriving: currentStep.isArrival,
            canReportBlocked: canReportBlocked
        )
    }

    func updateActivity(hallName: String? = nil) {
        guard let state = activityState else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        if let current = activity as? Activity<RouteAttributes> {
            let id = current.id
            Task { await Self.update(id, with: state) }
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        for stray in Activity<RouteAttributes>.activities.map(\.id) {
            Task { await Self.finish(stray) }
        }
        let attributes = RouteAttributes(title: String(localized: "Route.Title"), hallName: hallName ?? "")
        activity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    func endActivity() {
        guard let current = activity as? Activity<RouteAttributes> else { return }
        let id = current.id
        activity = nil
        RouteCutStore.removeAll()
        Task { await Self.finish(id) }
    }

    func storeActivityCuts(for stops: [RouteStop], database: Database) async {
        for stop in stops where !RouteCutStore.contains(stop.circleID) {
            guard !Task.isCancelled else { return }
            guard let image = await database.circleImageAsync(for: stop.circleID),
                  let data = Self.activityCutData(from: image) else { continue }
            RouteCutStore.save(data, for: stop.circleID)
        }
    }

    private static func activityCutData(from image: UIImage) -> Data? {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > 0.0 else { return nil }
        let scale = min(1.0, 200.0 / largestSide)
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            .jpegData(compressionQuality: 0.8)
    }

    nonisolated private static func update(_ id: String, with state: RouteAttributes.ContentState) async {
        guard let activity = Activity<RouteAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    nonisolated private static func finish(_ id: String) async {
        guard let activity = Activity<RouteAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    func connectActivityButtons(database: Database) {
        RouteIntentBridge.handler = { [weak self] isForward in
            if isForward {
                self?.skip()
            } else {
                self?.previous()
            }
        }
        RouteIntentBridge.visitedHandler = { [weak self] in
            self?.markVisitedAndContinue()
        }
        RouteIntentBridge.blockedHandler = { [weak self] in
            self?.reportBlocked(database: database)
        }
    }
}
#else
extension Navigator {
    func updateActivity(hallName: String? = nil) {}
    func endActivity() {}
    func storeActivityCuts(for stops: [RouteStop], database: Database) async {}
    func connectActivityButtons(database: Database) {}
}
#endif
