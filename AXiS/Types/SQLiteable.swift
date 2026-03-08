//
//  SQLiteable.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

public protocol SQLiteable {
    // row is used by conforming types to populate properties from a database row.
    init(from row: Row) // NOSONAR
}
