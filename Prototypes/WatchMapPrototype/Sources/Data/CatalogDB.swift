import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct SQLiteRow {
    let statement: OpaquePointer

    func int(_ index: Int32) -> Int {
        Int(sqlite3_column_int64(statement, index))
    }

    func string(_ index: Int32) -> String {
        guard let text = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: text)
    }

    func data(_ index: Int32) -> Data? {
        guard let bytes = sqlite3_column_blob(statement, index) else { return nil }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, index)))
    }
}

final class CatalogDB {
    private var handle: OpaquePointer?

    init?(path: String) {
        guard sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }
    }

    deinit {
        sqlite3_close(handle)
    }

    func rows(_ sql: String, integers: [Int] = [], strings: [String] = [], body: (SQLiteRow) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else { return }
        defer { sqlite3_finalize(statement) }

        var index: Int32 = 1
        for value in integers {
            sqlite3_bind_int64(statement, index, Int64(value))
            index += 1
        }
        for value in strings {
            sqlite3_bind_text(statement, index, value, -1, sqliteTransient)
            index += 1
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            body(SQLiteRow(statement: statement))
        }
    }

    func blob(_ sql: String, strings: [String] = []) -> Data? {
        var result: Data?
        rows(sql, strings: strings) { row in
            if result == nil { result = row.data(0) }
        }
        return result
    }
}
