import CoreGraphics

/// How the ways into a hall are read off its map. The catalog has no entrances, and each
/// hall's map draws them differently.
nonisolated enum HallEntrances: Sendable {
    /// Open gaps along the bottom edge of the map.
    case bottomEdge(alignsStarts: Bool, requiresClearFloor: Bool)
    /// The vestibules that join an open area outside the halls to the hall floor.
    case vestibules
    /// One spot, as a fraction of the map's width and height.
    case fixed(x: CGFloat, y: CGFloat)
    /// The hall name plates on the edge of the map, for halls whose entrances have not been
    /// checked yet.
    case signs
}
