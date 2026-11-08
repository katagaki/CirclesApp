import CoreGraphics

/// Turns a walk over grid cells into the line drawn on the map. Long runs stay straight
/// along the aisle, and the short steps between them become one angled stroke, so a
/// sidestep of a cell reads as a slight bend rather than a lean across the whole aisle.
nonisolated enum RouteStraightener {

    /// Runs this long or shorter are sidesteps, not stretches of aisle.
    static let jogLength = CGFloat(WalkableMap.cellSize) * 2.0

    /// `arrivalAxis` is the way the aisle runs in front of the stop the walk ends at. When
    /// the walk comes down that aisle and only steps aside to reach the stop, the end moves
    /// onto the line instead, so the line runs through the stop's badge rather than past it.
    static func straighten(_ points: [CGPoint], arrivalAxis: CGPoint? = nil) -> [CGPoint] {
        let walk = corners(of: points)
        guard walk.count > 2 else { return walk }
        let isLong = zip(walk, walk.dropFirst()).map { distance($0, $1) > jogLength }
        guard isLong.contains(true) else { return [walk[0], walk[walk.count - 1]] }
        var result: [CGPoint] = [walk[0]]
        var index = 0
        while index < isLong.count {
            if isLong[index] {
                result.append(walk[index + 1])
                index += 1
                continue
            }
            var end = index
            while end < isLong.count && !isLong[end] { end += 1 }
            result.removeLast()
            result += bend(walk, from: index, to: end, arrivalAxis: arrivalAxis)
            index = end
        }
        return corners(of: result)
    }

    /// Replaces the short runs between corners `start` and `end` with one stroke, pulled
    /// back into the long runs on either side so it leaves them at 45 degrees.
    private static func bend(
        _ corners: [CGPoint], from start: Int, to end: Int, arrivalAxis: CGPoint?
    ) -> [CGPoint] {
        let from = corners[start]
        let to = corners[end]
        let before = start > 0 ? unit(corners[start - 1], from) : nil
        let after = end < corners.count - 1 ? unit(to, corners[end + 1]) : nil
        if let before, let after, abs(dot(before, after)) < 0.1 {
            return [from, to]
        }
        if let before, let after, dot(before, after) < 0.9 {
            return Array(corners[start...end])
        }
        guard let direction = before ?? after else { return [from, to] }
        let offset = CGPoint(x: to.x - from.x, y: to.y - from.y)
        let along = dot(offset, direction)
        let across = hypot(offset.x - along * direction.x, offset.y - along * direction.y)
        if after == nil, let before, let arrivalAxis, abs(dot(before, arrivalAxis)) > 0.9, across <= jogLength {
            return [CGPoint(x: from.x + direction.x * along, y: from.y + direction.y * along)]
        }
        let extra = max(across - along, 0)
        let backLength = start > 0 ? distance(corners[start - 1], from) / 2.0 : 0
        let aheadLength = end < corners.count - 1 ? distance(to, corners[end + 1]) / 2.0 : 0
        let share = before != nil && after != nil ? extra / 2.0 : extra
        let back = before == nil ? 0 : min(share, backLength)
        let ahead = after == nil ? 0 : min(share, aheadLength)
        return [
            CGPoint(x: from.x - direction.x * back, y: from.y - direction.y * back),
            CGPoint(x: to.x + direction.x * ahead, y: to.y + direction.y * ahead)
        ]
    }

    /// The points where the walk changes direction, plus its two ends.
    static func corners(of points: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []
        for point in points {
            if let last = result.last, distance(last, point) < 0.01 { continue }
            if result.count >= 2 {
                let first = unit(result[result.count - 2], result[result.count - 1])
                let second = unit(result[result.count - 1], point)
                if abs(first.x * second.y - first.y * second.x) < 0.01 && dot(first, second) > 0 {
                    result[result.count - 1] = point
                    continue
                }
            }
            result.append(point)
        }
        return result
    }

    private static func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(second.x - first.x, second.y - first.y)
    }

    private static func unit(_ from: CGPoint, _ to: CGPoint) -> CGPoint {
        let length = max(distance(from, to), 0.0001)
        return CGPoint(x: (to.x - from.x) / length, y: (to.y - from.y) / length)
    }

    private static func dot(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        first.x * second.x + first.y * second.y
    }
}
