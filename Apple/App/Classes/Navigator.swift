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
    private(set) var isTrapped: Bool = false
    private(set) var isFinished: Bool = false
    var isStatusExpanded: Bool = false
    var pendingMode: Mode?
    var priorityCounts: [WebCatalogColor: Int] = [:]
    var chosenPriority: [WebCatalogColor]?
    var priorityDismissals: Int = 0

    @ObservationIgnored private var context: Context?
    @ObservationIgnored private var remainingStopIDs: Set<Int>?
    /// Where a visitor can walk in the open hall, kept once read off the map image so closures
    /// can be drawn, and routes planned, without reading it again.
    private(set) var walkableMap: WalkableMap?
    @ObservationIgnored private var walkableMapKey: String?
    @ObservationIgnored var activity: AnyObject?
    @ObservationIgnored private var planningTask: Task<Void, Never>?
    @ObservationIgnored private var retryTask: Task<Void, Never>?
    @ObservationIgnored private var savedSession: GuideSession? = GuideSession.load()

    var isActive: Bool { route != nil || isPlanning || isTrapped }

    var currentStep: RouteStep? {
        guard let route, route.steps.indices.contains(stepIndex) else { return nil }
        return route.steps[stepIndex]
    }

    var currentStop: RouteStop? {
        guard let route, let currentStep else { return nil }
        return route.stops[currentStep.stopIndex]
    }

    /// Where the visitor is standing: the start of the step they are on while a route is up,
    /// so it follows them as they step through it, otherwise the spot they long-pressed.
    var currentLocation: CGPoint? {
        if isFinished, let end = currentStep?.path.last {
            return end
        }
        if let start = currentStep?.path.first {
            return start
        }
        return origin
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
        case .begin, .entrance, .enter: return false
        case .turn, .arrive, .exit: return true
        }
    }

    func start(_ context: Context, database: Database) {
        self.context = context
        savedSession = nil
        isStatusExpanded = false
        remainingStopIDs = nil
        plan(database: database)
    }

    /// A message the visitor has to see grows out of the pill, so the pill lands at the
    /// trailing edge first and only then expands, the way a tap would expand it.
    private func expandAfterAppearing() {
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.smooth.speed(2.0)) {
                isStatusExpanded = true
            }
        }
    }

    /// Shrinks the message back into the pill, then lets the pill go.
    func dismissNoStops() {
        withAnimation(.smooth.speed(2.0)) {
            isStatusExpanded = false
        }
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.smooth.speed(2.0)) {
                isNoStopsAlertPresented = false
            }
        }
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
                remainingStopIDs: remainingStopIDs, database: database,
                cached: walkableMapKey == Self.cacheKey(context) ? walkableMap : nil
            )
            guard !Task.isCancelled else { return }
            if let map = route.map {
                walkableMap = map
                walkableMapKey = Self.cacheKey(context)
            }
            if !route.halls.isEmpty {
                halls = route.halls
            }
            let planned = route.route.flatMap { $0.steps.isEmpty ? nil : $0 }
            let trapped = planned == nil && !(route.route?.skippedSpaces.isEmpty ?? true)
            withAnimation(.smooth) {
                self.route = planned
                self.skippedSpaces = route.route?.skippedSpaces ?? []
                self.stepIndex = 0
                self.isFinished = false
                self.isPlanning = false
                self.isTrapped = trapped
                if planned == nil && !trapped {
                    self.isNoStopsAlertPresented = true
                }
            }
            persist()
            if trapped {
                endActivity()
                retryWhenClosuresLapse(database: database)
                expandAfterAppearing()
            } else if planned == nil {
                endActivity()
                expandAfterAppearing()
            } else if let planned {
                await storeActivityCuts(for: planned.stops, database: database)
                guard !Task.isCancelled else { return }
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

    /// The aisle a closure at the long-pressed spot would seal, drawn before the visitor
    /// chooses to close it, so they can see which way it runs.
    var pendingClosureLine: (from: CGPoint, to: CGPoint)? {
        guard let pendingPoint, let walkableMap else { return nil }
        return RoutePlanner.line(through: walkableMap.closureCells(at: pendingPoint), in: walkableMap)
    }

    /// The lines across every closed way, drawn whether or not a route is up.
    var closureLines: [RouteClosureLine] {
        guard let walkableMap else { return [] }
        return RoutePlanner.seal(activeClosures, in: walkableMap).lines
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
    func loadHalls(inMap mapID: Int, hall: ComiketHall?, day: Int?, database: Database) {
        Task {
            let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
            let halls = await fetcher.hallAreas(inMap: mapID)
            self.halls = halls
            guard let hall, let day else { return }
            let key = Self.mapKey(mapID: mapID, day: day)
            guard walkableMapKey != key else { return }
            let tables = await Self.tables(inMap: mapID, database: database)
            guard let map = await Self.buildMap(hall: hall, day: day, tables: tables, database: database) else { return }
            walkableMap = map
            walkableMapKey = key
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
        if let map = walkableMap,
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
        walkableMap = nil
        walkableMapKey = nil
        pendingPoint = nil
        selectedClosureID = nil
    }

    /// Every way out is closed. Closures lapse on their own, so the route is planned again
    /// as soon as the first of them does.
    private func retryWhenClosuresLapse(database: Database) {
        retryTask?.cancel()
        guard let next = activeClosures.map(\.expiresAt).min() else { return }
        retryTask = Task {
            try? await Task.sleep(for: .seconds(max(1.0, next.timeIntervalSinceNow + 1.0)))
            guard !Task.isCancelled, isTrapped else { return }
            plan(database: database)
        }
    }

    private func keepRemainingStops() {
        guard let route, let step = currentStep else { return }
        remainingStopIDs = Set(route.stops[step.stopIndex...].map(\.id))
    }

    private func replanFromCurrentStep(database: Database) {
        guard context != nil else { return }
        if let step = currentStep, !step.isStart, let start = step.path.first {
            origin = start
        }
        keepRemainingStops()
        plan(database: database)
    }

    func next() {
        guard let route, stepIndex + 1 < route.steps.count else { return }
        withAnimation(.smooth) { stepIndex += 1 }
        persist()
        updateActivity()
    }

    func previous() {
        if isFinished {
            withAnimation(.smooth) { isFinished = false }
            persist()
            updateActivity()
            return
        }
        guard stepIndex > 0 else { return }
        withAnimation(.smooth) { stepIndex -= 1 }
        persist()
        updateActivity()
    }

    /// Moves past the current step without marking anything; past the last stop, the
    /// visitor is told they are done, and the route stays up until they end it.
    func skip() {
        if let route, stepIndex + 1 < route.steps.count {
            next()
        } else if route != nil, !isFinished {
            withAnimation(.smooth) { isFinished = true }
            persist()
            endActivity()
        }
    }

    func markVisitedAndContinue() {
        guard let currentStop, let eventNumber = context?.eventNumber else { return }
        let circleID = currentStop.circleID
        Task.detached {
            let actor = VisitActor(modelContainer: sharedModelContainer)
            await actor.markVisited(circleID: circleID, eventNumber: eventNumber)
        }
        skip()
    }

    func end() {
        planningTask?.cancel()
        retryTask?.cancel()
        withAnimation(.smooth) {
            route = nil
            origin = nil
            pendingPoint = nil
            selectedClosureID = nil
            skippedSpaces = []
            isTrapped = false
            isFinished = false
            isPlanning = false
            stepIndex = 0
        }
        context = nil
        remainingStopIDs = nil
        savedSession = nil
        GuideSession.remove()
        endActivity()
    }

    // MARK: Persistence

    private func persist() {
        guard let context, route != nil || isTrapped else {
            GuideSession.remove()
            return
        }
        GuideSession(
            eventNumber: context.eventNumber, mapID: context.mapID, day: context.day,
            favoriteColors: context.favoriteColors, visitedCircleIDs: context.visitedCircleIDs,
            colorPriority: context.colorPriority, route: route, stepIndex: stepIndex, origin: origin,
            closures: closures.filter(\.isActive), skippedSpaces: skippedSpaces,
            remainingStopIDs: remainingStopIDs, isTrapped: isTrapped, isFinished: isFinished
        ).save()
    }

    /// Picks up the session left when the app last closed, once the map it was on is open
    /// again with its layouts loaded.
    func resume(
        eventNumber: Int, mapID: Int, mapName: String, hall: ComiketHall, day: Int,
        layouts: Mapper.Layouts, database: Database
    ) {
        guard let session = savedSession, !isActive, context == nil, !layouts.isEmpty,
              session.eventNumber == eventNumber, session.mapID == mapID, session.day == day else { return }
        savedSession = nil
        context = Context(
            eventNumber: eventNumber, mapID: mapID, mapName: mapName, hall: hall, day: day,
            layouts: layouts, favoriteColors: session.favoriteColors,
            visitedCircleIDs: session.visitedCircleIDs, colorPriority: session.colorPriority
        )
        remainingStopIDs = session.remainingStopIDs
        closures = session.closures.filter(\.isActive)
        origin = session.origin
        guard let route = session.route, !session.isTrapped, !route.steps.isEmpty else {
            plan(database: database)
            return
        }
        withAnimation(.smooth) {
            self.route = route
            stepIndex = min(max(session.stepIndex, 0), route.steps.count - 1)
            skippedSpaces = session.skippedSpaces
            isFinished = session.isFinished
        }
        guard !session.isFinished else { return }
        Task {
            await storeActivityCuts(for: route.stops, database: database)
            updateActivity(hallName: mapName)
        }
    }

    // MARK: Planning

    private struct Outcome: Sendable {
        let route: PlannedRoute?
        let map: WalkableMap?
        var halls: [RouteHall] = []
    }

    private static func cacheKey(_ context: Context) -> String {
        mapKey(mapID: context.mapID, day: context.day)
    }

    private static func mapKey(mapID: Int, day: Int) -> String {
        "\(day)-\(mapID)"
    }

    private static func tables(inMap mapID: Int, database: Database) async -> [RouteTable] {
        let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
        let layouts = await fetcher.layoutMappings(inMap: mapID, useHighResolutionMaps: true)
        let blockNames = Dictionary(database.blocks().map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        return layouts.map { layout in
            RouteTable(
                rect: CGRect(x: CGFloat(layout.positionX), y: CGFloat(layout.positionY),
                             width: planningSpaceSize, height: planningSpaceSize),
                blockName: blockNames[layout.blockID] ?? "",
                opensSideways: layout.layoutType != .aOnTop && layout.layoutType != .aOnBottom
            )
        }
    }

    private static func buildMap(
        hall: ComiketHall, day: Int, tables: [RouteTable], database: Database
    ) async -> WalkableMap? {
        guard let image = await database.mapImageAsync(for: hall, on: day, usingHighDefinition: true),
              let cgImage = image.cgImage else { return nil }
        let entrances = hall.entrances
        return await Task.detached(priority: .userInitiated) {
            WalkableMap.build(image: cgImage, tables: tables, entrances: entrances)
        }.value
    }

    private static func makeRoute(
        context: Context, origin: CGPoint?, closures: [RouteClosure], remainingStopIDs: Set<Int>?,
        database: Database, cached: WalkableMap?
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

        var map = cached
        if map == nil {
            map = await buildMap(hall: context.hall, day: context.day, tables: tables, database: database)
        }
        guard let map else { return Outcome(route: nil, map: nil) }
        let route = await Task.detached(priority: .userInitiated) {
            RoutePlanner.plan(map: map, stops: requests, origin: origin, closures: closures, halls: halls)
        }.value
        return Outcome(route: route, map: map, halls: halls)
    }
}
