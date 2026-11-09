import Foundation

extension RouteStep {

    func instruction(stop: RouteStop) -> String {
        let walk = blocks > 0
            ? String(localized: "Route.Walk.Blocks.\(blocks)")
            : String(localized: "Route.Walk.Ahead")
        switch action {
        case .begin:
            return String(localized: "Route.Begin.\(stop.spaceName)")
        case .entrance(let hall):
            return Self.entranceInstruction(hall: hall)
        case .exit(let hall):
            return String(localized: "Route.Exit.\(walk).\(hall)")
        case .enter(let hall):
            return String(localized: "Route.Enter.\(hall)")
        case .turn(let turn, let passage):
            return Self.turnInstruction(turn, walk: walk, into: passage.name)
        case .arrive(let side):
            switch side {
            case .left: return String(localized: "Route.Arrive.Left.\(walk).\(stop.spaceName)")
            case .right: return String(localized: "Route.Arrive.Right.\(walk).\(stop.spaceName)")
            case .ahead: return String(localized: "Route.Arrive.Ahead.\(walk).\(stop.spaceName)")
            }
        }
    }

    private static func turnInstruction(_ turn: RouteTurn, walk: String, into: String) -> String {
        switch turn {
        case .left: String(localized: "Route.Turn.Left.\(walk).\(into)")
        case .right: String(localized: "Route.Turn.Right.\(walk).\(into)")
        case .straight: String(localized: "Route.Turn.Straight.\(walk).\(into)")
        }
    }

    private static func entranceInstruction(hall: String) -> String {
        hall.isEmpty ? String(localized: "Route.Entrance") : String(localized: "Route.Entrance.\(hall)")
    }

    var symbolName: String {
        switch action {
        case .turn(.left, _): "arrow.turn.up.left"
        case .turn(.right, _): "arrow.turn.up.right"
        case .turn(.straight, _): "arrow.up"
        case .arrive: "mappin.and.ellipse"
        case .begin: "figure.walk"
        case .entrance: "door.left.hand.open"
        case .exit: "figure.walk.departure"
        case .enter: "figure.walk.arrival"
        }
    }

    /// The step that puts the visitor on the route, before they have walked any of it.
    var isStart: Bool {
        switch action {
        case .begin, .entrance: true
        case .turn, .arrive, .exit, .enter: false
        }
    }

    var isArrival: Bool {
        switch action {
        case .arrive, .begin: true
        case .turn, .entrance, .exit, .enter: false
        }
    }
}

extension RoutePassage {

    var name: String {
        switch self {
        case .corridor:
            String(localized: "Route.Passage.Corridor")
        case .corridorAlong(let block):
            String(localized: "Route.Passage.CorridorAlong.\(block)")
        case .aisleBetween(let left, let right):
            String(localized: "Route.Passage.AisleBetween.\(left).\(right)")
        case .aisleThrough(let block):
            String(localized: "Route.Passage.AisleThrough.\(block)")
        }
    }
}
