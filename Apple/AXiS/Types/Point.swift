import CoreGraphics

public struct Point: Codable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func cgPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}
