import Foundation

extension RouteStep {

    func instruction(stop: RouteStop) -> String {
        let walk = blocks > 0
            ? String(localized: "Route.Walk.Blocks.\(blocks)")
            : String(localized: "Route.Walk.Ahead")
        switch action {
        case .begin:
            return String(localized: "Route.Begin.\(stop.spaceName)")
        case .turn(let turn, let passage):
            let into = passage.name
            switch turn {
            case .left: return String(localized: "Route.Turn.Left.\(walk).\(into)")
            case .right: return String(localized: "Route.Turn.Right.\(walk).\(into)")
            case .straight: return String(localized: "Route.Turn.Straight.\(walk).\(into)")
            }
        case .arrive(let side):
            switch side {
            case .left: return String(localized: "Route.Arrive.Left.\(walk).\(stop.spaceName)")
            case .right: return String(localized: "Route.Arrive.Right.\(walk).\(stop.spaceName)")
            case .ahead: return String(localized: "Route.Arrive.Ahead.\(walk).\(stop.spaceName)")
            }
        }
    }

    var symbolName: String {
        switch action {
        case .turn(.left, _): "arrow.turn.up.left"
        case .turn(.right, _): "arrow.turn.up.right"
        case .turn(.straight, _): "arrow.up"
        case .arrive: "mappin.and.ellipse"
        case .begin: "figure.walk"
        }
    }

    var isArrival: Bool {
        switch action {
        case .arrive, .begin: true
        case .turn: false
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
