import SQLite

public struct CorporateBooth: SQLiteable, Identifiable, Hashable, Sendable {
    public var eventNumber: Int
    public var id: Int
    public var name: String
    public var boothNumber: Int
    public var summary: String
    public var products: String
    public var area: String?

    public init(from row: Row) {
        self.eventNumber = row[Expression<Int>("comiketNo")]
        self.id = row[Expression<Int>("boothId")]
        self.name = row[Expression<String>("name")]
        self.boothNumber = row[Expression<Int>("boothNo")]
        self.summary = row[Expression<String>("description")]
        self.products = row[Expression<String>("product")]
        self.area = row[Expression<String?>("area")]
    }
}
