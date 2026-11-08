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
}

nonisolated struct RouteStop: Sendable, Identifiable, Hashable {
    let id: Int
    let circleID: Int
    let name: String
    let spaceName: String
    let accessPoint: CGPoint
    let spaceCenter: CGPoint
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

nonisolated struct PlannedRoute: Sendable, Hashable {
    let stops: [RouteStop]
    let legs: [[CGPoint]]
    let steps: [RouteStep]
    let origin: CGPoint?
}
