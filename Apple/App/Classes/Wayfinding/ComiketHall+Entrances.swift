import AXiS

extension ComiketHall {

    var entrances: HallEntrances {
        switch self {
        case .east123: .bottomEdge(alignsStarts: true, requiresClearFloor: false)
        case .east7: .fixed(x: 0.189, y: 0.956)
        case .west12: .vestibules
        case .south12: .bottomEdge(alignsStarts: false, requiresClearFloor: true)
        case .east456, .east78, .west34, .south34: .signs
        }
    }
}
