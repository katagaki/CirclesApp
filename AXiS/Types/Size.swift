import CoreGraphics

public struct Size: Codable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public func cgSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
}
