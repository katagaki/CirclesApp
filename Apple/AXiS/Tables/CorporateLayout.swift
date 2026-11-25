import CoreGraphics
import SQLite

public struct CorporateLayout: SQLiteable, Identifiable, Hashable, Sendable {
    public var boothID: Int
    public var sequence: Int
    public var area: String
    public var rect: CGRect
    public var isCut: Bool

    public var id: String { "\(boothID)-\(area)-\(sequence)" }

    public init(from row: Row) {
        self.boothID = row[Expression<Int>("boothId")]
        self.sequence = row[Expression<Int>("seq")]
        self.area = row[Expression<String>("area")]
        let left = row[Expression<Int>("x1")]
        let top = row[Expression<Int>("y1")]
        let right = row[Expression<Int>("x2")]
        let bottom = row[Expression<Int>("y2")]
        self.rect = CGRect(x: min(left, right), y: min(top, bottom),
                           width: abs(right - left), height: abs(bottom - top))
        self.isCut = row[Expression<Int>("isCut")] == 1
    }
}
