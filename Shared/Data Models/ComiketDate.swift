//
//  ComiketDate.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite
import SwiftData

@Model
final class ComiketDate: SQLiteable {
    var number: Int
    var id: Int
    var date: Date

    init(from row: Row) {
        let colNumber = Expression<Int>("comiketNo")
        let colID = Expression<Int>("id")
        let colYear = Expression<Int>("year")
        let colMonth = Expression<Int>("month")
        let colDay = Expression<Int>("day")

        self.number = row[colNumber]
        self.id = row[colID]
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .init(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let year = String(format: "%04d", row[colYear])
        let month = String(format: "%02d", row[colMonth])
        let day = String(format: "%02d", row[colDay])

        if let date = dateFormatter.date(from: "\(year)-\(month)-\(day)") {
            self.date = date
        } else {
            self.date = .distantPast
        }
    }
}
