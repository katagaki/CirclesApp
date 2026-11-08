import AXiS
import CoreGraphics
import Observation
import SwiftUI

/// Plans a walk through the favourites on the open hall map and steps through it.
@MainActor
@Observable
final class Navigator {

    struct Context {
        let eventNumber: Int
        let mapID: Int
        let mapName: String
        let hall: ComiketHall
        let day: Int
        let layouts: Mapper.Layouts
        let favoriteWebCatalogIDs: Set<Int>
        let visitedCircleIDs: [Int]
    }

    static let planningSpaceSize: CGFloat = 40.0

    private(set) var route: PlannedRoute?
    private(set) var stepIndex: Int = 0
    private(set) var isPlanning: Bool = false
    private(set) var origin: CGPoint?
    var isNoStopsAlertPresented: Bool = false

    @ObservationIgnored private var context: Context?
    @ObservationIgnored private var mapCache: [String: WalkableMap] = [:]
    @ObservationIgnored var activity: AnyObject?
    @ObservationIgnored private var planningTask: Task<Void, Never>?

    var isActive: Bool { route != nil || isPlanning }

    var currentStep: RouteStep? {
        guard let route, route.steps.indices.contains(stepIndex) else { return nil }
        return route.steps[stepIndex]
    }

    var currentStop: RouteStop? {
        guard let route, let currentStep else { return nil }
        return route.stops[currentStep.stopIndex]
    }

    var currentInstruction: String? {
        guard let currentStep, let currentStop else { return nil }
        return currentStep.instruction(stop: currentStop)
    }

    func start(_ context: Context, database: Database) {
        self.context = context
        plan(database: database)
    }

    func plan(database: Database) {
        guard let context else { return }
        planningTask?.cancel()
        isPlanning = true
        planningTask = Task {
            let route = await Self.makeRoute(context: context, origin: origin, database: database, cache: mapCache)
            guard !Task.isCancelled else { return }
            if let map = route.map {
                mapCache[Self.cacheKey(context)] = map
            }
            let planned = route.route.flatMap { $0.steps.isEmpty ? nil : $0 }
            withAnimation(.smooth) {
                self.route = planned
                self.stepIndex = 0
                self.isPlanning = false
            }
            if planned == nil {
                isNoStopsAlertPresented = true
                endActivity()
            } else {
                updateActivity(hallName: context.mapName)
            }
        }
    }

    /// Sets where the visitor is standing, in the map's display coordinates, and plans the
    /// rest of the route again from there.
    func setOrigin(_ point: CGPoint, spaceSize: CGFloat, database: Database) {
        let scale = Self.planningSpaceSize / spaceSize
        withAnimation(.smooth) {
            origin = CGPoint(x: point.x * scale, y: point.y * scale)
        }
        if context != nil {
            plan(database: database)
        }
    }

    func next() {
        guard let route, stepIndex + 1 < route.steps.count else { return }
        withAnimation(.smooth) { stepIndex += 1 }
        updateActivity()
    }

    func previous() {
        guard stepIndex > 0 else { return }
        withAnimation(.smooth) { stepIndex -= 1 }
        updateActivity()
    }

    func markVisitedAndContinue(eventNumber: Int, visitedCircleIDs: Set<Int>) {
        guard let currentStop else { return }
        if !visitedCircleIDs.contains(currentStop.circleID) {
            let circleID = currentStop.circleID
            Task.detached {
                let actor = VisitActor(modelContainer: sharedModelContainer)
                await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
            }
        }
        if let route, stepIndex + 1 < route.steps.count {
            next()
        } else {
            end()
        }
    }

    func end() {
        planningTask?.cancel()
        withAnimation(.smooth) {
            route = nil
            origin = nil
            isPlanning = false
            stepIndex = 0
        }
        context = nil
        endActivity()
    }

    // MARK: Planning

    private struct Outcome: Sendable {
        let route: PlannedRoute?
        let map: WalkableMap?
    }

    private static func cacheKey(_ context: Context) -> String {
        "\(context.eventNumber)-\(context.day)-\(context.mapID)"
    }

    private static func makeRoute(
        context: Context, origin: CGPoint?, database: Database, cache: [String: WalkableMap]
    ) async -> Outcome {
        var stopIDs: [Int] = []
        var layoutsByStop: [Int: (LayoutCatalogMapping, Int)] = [:]
        for (layout, webCatalogIDs) in context.layouts {
            for webCatalogID in webCatalogIDs where context.favoriteWebCatalogIDs.contains(webCatalogID) {
                stopIDs.append(webCatalogID)
                layoutsByStop[webCatalogID] = (layout, webCatalogIDs.count)
            }
        }
        guard !stopIDs.isEmpty else { return Outcome(route: nil, map: nil) }

        let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
        let tablesLayouts = await fetcher.layoutMappings(inMap: context.mapID, useHighResolutionMaps: true)
        let circles = await fetcher.routeCircles(withWebCatalogIDs: stopIDs)
        let visited = Set(await fetcher.webCatalogIDs(forCircleIDs: context.visitedCircleIDs))
        let blockNames = Dictionary(database.blocks().map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })

        let space = planningSpaceSize
        var positions: [String: LayoutCatalogMapping] = [:]
        let tables = tablesLayouts.map { layout -> RouteTable in
            positions[layout.viewID()] = layout
            return RouteTable(
                rect: CGRect(x: CGFloat(layout.positionX), y: CGFloat(layout.positionY), width: space, height: space),
                blockName: blockNames[layout.blockID] ?? "",
                opensSideways: layout.layoutType != .aOnTop && layout.layoutType != .aOnBottom
            )
        }

        let requests = stopIDs.filter { !visited.contains($0) }.compactMap { webCatalogID -> RouteStopRequest? in
            guard let circle = circles[webCatalogID],
                  let (layout, count) = layoutsByStop[webCatalogID],
                  let position = positions[layout.viewID()] else { return nil }
            let opensSideways = layout.layoutType != .aOnTop && layout.layoutType != .aOnBottom
            let isReversed = layout.layoutType == .aOnBottom || layout.layoutType == .aOnRight
            let total = CGFloat(max(count, 1))
            let index = CGFloat(min(isReversed ? count - 1 - circle.spaceNumberSuffix : circle.spaceNumberSuffix,
                                    count - 1))
            let base = CGRect(x: CGFloat(position.positionX), y: CGFloat(position.positionY), width: space, height: space)
            let rect = opensSideways
                ? CGRect(x: base.minX + index * space / total, y: base.minY, width: space / total, height: space)
                : CGRect(x: base.minX, y: base.minY + index * space / total, width: space, height: space / total)
            return RouteStopRequest(
                webCatalogID: webCatalogID, circleID: circle.circleID, name: circle.name,
                spaceName: circle.spaceName, spaceRect: rect, opensSideways: opensSideways
            )
        }
        guard !requests.isEmpty else { return Outcome(route: nil, map: nil) }

        let key = cacheKey(context)
        var map = cache[key]
        if map == nil {
            guard let image = await database.mapImageAsync(for: context.hall, on: context.day, usingHighDefinition: true),
                  let cgImage = image.cgImage else { return Outcome(route: nil, map: nil) }
            map = await Task.detached(priority: .userInitiated) {
                WalkableMap.build(image: cgImage, tables: tables)
            }.value
        }
        guard let map else { return Outcome(route: nil, map: nil) }
        let route = await Task.detached(priority: .userInitiated) {
            RoutePlanner.plan(map: map, stops: requests, origin: origin)
        }.value
        return Outcome(route: route, map: map)
    }
}
