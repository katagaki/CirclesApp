import AXiS
import CoreGraphics
import Observation
import RADiUS
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
        let favoriteColors: [Int: WebCatalogColor]
        let visitedCircleIDs: [Int]
        let colorPriority: [WebCatalogColor]?
    }

    enum Mode {
        case efficient
        case prioritized
    }

    static let planningSpaceSize: CGFloat = 40.0

    private(set) var route: PlannedRoute?
    private(set) var stepIndex: Int = 0
    private(set) var isPlanning: Bool = false
    private(set) var origin: CGPoint?
    private(set) var closures: [RouteClosure] = []
    private(set) var skippedSpaces: [String] = []
    private(set) var halls: [RouteHall] = []
    private(set) var pendingPoint: CGPoint?
    private(set) var selectedClosureID: UUID?
    var isNoStopsAlertPresented: Bool = false
    var isStatusExpanded: Bool = false
    var pendingMode: Mode?
    var priorityCounts: [WebCatalogColor: Int] = [:]
    var chosenPriority: [WebCatalogColor]?
    var onboardingDismissals: Int = 0
    var priorityDismissals: Int = 0

    @ObservationIgnored private var context: Context?
    @ObservationIgnored private var remainingStopIDs: Set<Int>?
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

    var activeClosures: [RouteClosure] {
        closures.filter(\.isActive)
    }

    var canReportBlocked: Bool {
        guard let currentStep else { return false }
        switch currentStep.action {
        case .begin, .enter: return false
        case .turn, .arrive, .exit: return true
        }
    }

    func start(_ context: Context, database: Database) {
        self.context = context
        remainingStopIDs = nil
        plan(database: database)
    }

    var colorPriority: [WebCatalogColor]? {
        context?.colorPriority
    }

    func plan(database: Database) {
        guard let context else { return }
        planningTask?.cancel()
        isPlanning = true
        planningTask = Task {
            let route = await Self.makeRoute(
                context: context, origin: origin, closures: activeClosures,
                remainingStopIDs: remainingStopIDs, database: database, cache: mapCache
            )
            guard !Task.isCancelled else { return }
            if let map = route.map {
                mapCache[Self.cacheKey(context)] = map
            }
            if !route.halls.isEmpty {
                halls = route.halls
            }
            let planned = route.route.flatMap { $0.steps.isEmpty ? nil : $0 }
            withAnimation(.smooth) {
                self.route = planned
                self.skippedSpaces = route.route?.skippedSpaces ?? []
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

    // MARK: Long Press

    /// Holds a long-pressed spot, in the map's display coordinates, until the visitor says
    /// whether they are standing there or the way is closed there.
    func hold(_ point: CGPoint, spaceSize: CGFloat) {
        let scale = Self.planningSpaceSize / spaceSize
        withAnimation(.smooth) {
            selectedClosureID = nil
            pendingPoint = CGPoint(x: point.x * scale, y: point.y * scale)
        }
    }

    func cancelHold() {
        withAnimation(.smooth) {
            pendingPoint = nil
            selectedClosureID = nil
        }
    }

    func setOriginAtHold(database: Database) {
        guard let pendingPoint else { return }
        withAnimation(.smooth) {
            origin = pendingPoint
            self.pendingPoint = nil
        }
        keepRemainingStops()
        if context != nil {
            plan(database: database)
        }
    }

    /// The lines where neighbouring halls meet. Where the printed ranges overlap, the
    /// boundary is taken as the middle of the overlap.
    var hallBoundaries: [CGFloat] {
        zip(halls, halls.dropFirst()).map { left, right in (left.rect.maxX + right.rect.minX) / 2.0 }
    }

    /// Loads the halls of the open map, so their boundaries can be closed off before a
    /// route has been planned on it.
    func loadHalls(inMap mapID: Int, database: Database) {
        Task {
            let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
            let halls = await fetcher.hallAreas(inMap: mapID)
            self.halls = halls
        }
    }

    func closeHallsAtHold(database: Database) {
        guard let pendingPoint,
              let boundary = hallBoundaries.min(by: { abs($0 - pendingPoint.x) < abs($1 - pendingPoint.x) }) else { return }
        withAnimation(.smooth) {
            closures.append(RouteClosure(point: CGPoint(x: boundary, y: pendingPoint.y), hallBoundaryX: boundary))
            self.pendingPoint = nil
        }
        replanFromCurrentStep(database: database)
    }

    func closePathAtHold(database: Database) {
        guard let pendingPoint else { return }
        withAnimation(.smooth) {
            closures.append(RouteClosure(point: pendingPoint))
            self.pendingPoint = nil
        }
        replanFromCurrentStep(database: database)
    }

    // MARK: Closures

    /// The way ahead is closed: seals off the aisle the current step turns into, or the
    /// stretch it walks if it ends at a stop, and plans again from where the step began.
    func reportBlocked(database: Database) {
        guard let route, let step = currentStep, canReportBlocked else { return }
        let next = route.steps.indices.contains(stepIndex + 1) ? route.steps[stepIndex + 1] : nil
        let stretch: [CGPoint]
        if !step.isArrival, let next, next.stopIndex == step.stopIndex, next.path.count > 1 {
            stretch = Array(next.path.prefix(12))
        } else {
            stretch = step.path
        }
        let closure: RouteClosure
        if let map = context.flatMap({ mapCache[Self.cacheKey($0)] }),
           let crossing = map.narrowestCrossing(along: stretch) {
            closure = RouteClosure(point: crossing.point, across: crossing.across)
        } else {
            closure = RouteClosure(point: stretch[stretch.count / 2])
        }
        withAnimation(.smooth) {
            closures.append(closure)
        }
        replanFromCurrentStep(database: database)
    }

    @discardableResult
    func selectClosure(near point: CGPoint, spaceSize: CGFloat) -> Bool {
        let scale = Self.planningSpaceSize / spaceSize
        let target = CGPoint(x: point.x * scale, y: point.y * scale)
        guard let closure = activeClosures.first(where: {
            hypot($0.point.x - target.x, $0.point.y - target.y) < Self.planningSpaceSize
        }) else { return false }
        withAnimation(.smooth) {
            pendingPoint = nil
            selectedClosureID = closure.id
        }
        return true
    }

    func reopenSelectedClosure(database: Database) {
        guard let selectedClosureID else { return }
        withAnimation(.smooth) {
            closures.removeAll { $0.id == selectedClosureID }
            self.selectedClosureID = nil
        }
        replanFromCurrentStep(database: database)
    }

    var selectedClosureIsHallBoundary: Bool {
        closures.first { $0.id == selectedClosureID }?.hallBoundaryX != nil
    }

    func clearClosures() {
        closures.removeAll()
        halls = []
        pendingPoint = nil
        selectedClosureID = nil
    }

    private func keepRemainingStops() {
        guard let route, let step = currentStep else { return }
        remainingStopIDs = Set(route.stops[step.stopIndex...].map(\.id))
    }

    private func replanFromCurrentStep(database: Database) {
        guard context != nil else { return }
        if let step = currentStep, step.action != .begin, let start = step.path.first {
            origin = start
        }
        keepRemainingStops()
        plan(database: database)
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
            pendingPoint = nil
            selectedClosureID = nil
            skippedSpaces = []
            isPlanning = false
            stepIndex = 0
        }
        context = nil
        remainingStopIDs = nil
        endActivity()
    }

    // MARK: Planning

    private struct Outcome: Sendable {
        let route: PlannedRoute?
        let map: WalkableMap?
        var halls: [RouteHall] = []
    }

    private static func cacheKey(_ context: Context) -> String {
        "\(context.eventNumber)-\(context.day)-\(context.mapID)"
    }

    private static func makeRoute(
        context: Context, origin: CGPoint?, closures: [RouteClosure], remainingStopIDs: Set<Int>?,
        database: Database, cache: [String: WalkableMap]
    ) async -> Outcome {
        var stopIDs: [Int] = []
        var layoutsByStop: [Int: (LayoutCatalogMapping, Int)] = [:]
        for (layout, webCatalogIDs) in context.layouts {
            for webCatalogID in webCatalogIDs
            where context.favoriteColors[webCatalogID] != nil
                && remainingStopIDs?.contains(webCatalogID) ?? true {
                if let priority = context.colorPriority,
                   let color = context.favoriteColors[webCatalogID], !priority.contains(color) {
                    continue
                }
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
        let halls = await fetcher.hallAreas(inMap: context.mapID)

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
            let color = context.favoriteColors[webCatalogID] ?? .uncolored
            return RouteStopRequest(
                webCatalogID: webCatalogID, circleID: circle.circleID, name: circle.name,
                spaceName: circle.spaceName, spaceRect: rect, opensSideways: opensSideways,
                rank: context.colorPriority?.firstIndex(of: color) ?? 0, colorRawValue: color.rawValue
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
            RoutePlanner.plan(map: map, stops: requests, origin: origin, closures: closures, halls: halls)
        }.value
        return Outcome(route: route, map: map, halls: halls)
    }
}
