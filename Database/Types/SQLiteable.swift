//
//  SQLiteable.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

protocol SQLiteable {
    init(from row: Row)
}
