import CoreGraphics
import Foundation

nonisolated struct GridPoint: Hashable, Sendable {
    var row: Int
    var column: Int
}

/// A table on the hall map, in high-resolution map pixels.
nonisolated struct RouteTable: Sendable {
    let rect: CGRect
    let blockName: String
    let opensSideways: Bool
}

/// A circle the route has to visit, in high-resolution map pixels.
nonisolated struct RouteStopRequest: Sendable {
    let webCatalogID: Int
    let circleID: Int
    let name: String
    let spaceName: String
    let spaceRect: CGRect
    let opensSideways: Bool
    let rank: Int
    let colorRawValue: Int
}

nonisolated struct RouteStop: Sendable, Identifiable, Hashable {
    let id: Int
    let circleID: Int
    let name: String
    let spaceName: String
    let accessPoint: CGPoint
    let spaceCenter: CGPoint
    let colorRawValue: Int
}

nonisolated enum RouteTurn: Sendable, Hashable {
    case left
    case right
    case straight
}

nonisolated enum RouteSide: Sendable, Hashable {
    case left
    case right
    case ahead
}

nonisolated enum RoutePassage: Sendable, Hashable {
    case corridor
    case corridorAlong(String)
    case aisleBetween(String, String)
    case aisleThrough(String)
}

nonisolated enum RouteAction: Sendable, Hashable {
    case begin
    case exit(hall: String)
    case enter(hall: String)
    case turn(RouteTurn, into: RoutePassage)
    case arrive(RouteSide)
}

nonisolated struct RouteStep: Sendable, Identifiable, Hashable {
    let id: Int
    let stopIndex: Int
    let blocks: Int
    let action: RouteAction
    let path: [CGPoint]
}

/// One hall of a map that spans several, such as East 1 within East 1–3.
nonisolated struct RouteHall: Sendable, Hashable {
    let name: String
    let rect: CGRect
}

/// A way in and out of the hall, found from the hall sign on the wall beside it.
nonisolated struct RouteDoor: Sendable, Hashable {
    enum Edge: Sendable, Hashable {
        case top
        case bottom
        case left
        case right
    }

    let cell: GridPoint
    let sign: CGRect
    let edge: Edge
}

/// A path staff have closed off, in high-resolution map pixels. Closures lapse on their
/// own, since a queue or crowd that closes an aisle rarely lasts.
nonisolated struct RouteClosure: Sendable, Identifiable, Hashable {
    static let lifetime: TimeInterval = 30 * 60

    let id: UUID
    let point: CGPoint
    let across: GridPoint?
    let hallBoundaryX: CGFloat?
    let expiresAt: Date

    init(point: CGPoint, across: GridPoint? = nil, hallBoundaryX: CGFloat? = nil, now: Date = .now) {
        self.id = UUID()
        self.point = point
        self.across = across
        self.hallBoundaryX = hallBoundaryX
        self.expiresAt = now.addingTimeInterval(Self.lifetime)
    }

    var isActive: Bool { expiresAt > .now }
}

nonisolated struct RouteClosureLine: Sendable, Hashable {
    let id: UUID
    let from: CGPoint
    let to: CGPoint
}

nonisolated struct PlannedRoute: Sendable, Hashable {
    let stops: [RouteStop]
    let legs: [[CGPoint]]
    let steps: [RouteStep]
    let origin: CGPoint?
    let closures: [RouteClosureLine]
    let outsidePaths: [[CGPoint]]
    let skippedSpaces: [String]
}
