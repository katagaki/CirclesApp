import SQLite

public protocol SQLiteable {
    init(from row: Row) // NOSONAR
}
