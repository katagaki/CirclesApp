import SQLite

public struct CorporateMap: SQLiteable, Identifiable, Hashable, Sendable {
    public var eventNumber: Int
    public var area: String
    public var scale: Int
    public var width: Int
    public var height: Int

    public var id: String { area }

    public init(from row: Row) {
        self.eventNumber = row[Expression<Int>("comiketNo")]
        self.area = row[Expression<String>("area")]
        self.scale = row[Expression<Int>("scale")]
        self.width = row[Expression<Int>("width")]
        self.height = row[Expression<Int>("height")]
    }
}
