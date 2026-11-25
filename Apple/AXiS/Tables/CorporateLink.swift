import Foundation
import SQLite

public struct CorporateLink: SQLiteable, Identifiable, Hashable, Sendable {
    public var boothID: Int
    public var displayOrder: Int
    public var linkURL: URL?
    public var imageURL: URL?

    public var id: Int { displayOrder }

    public init(from row: Row) {
        self.boothID = row[Expression<Int>("boothId")]
        self.displayOrder = row[Expression<Int>("displayOrder")]
        self.linkURL = row[Expression<String?>("linkUrl")].flatMap { URL(string: $0) }
        self.imageURL = row[Expression<String?>("imageUrl")].flatMap { URL(string: $0) }
    }
}
