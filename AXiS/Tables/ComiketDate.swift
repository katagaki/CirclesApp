//
//  ComiketDate.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite

public final class ComiketDate: SQLiteable, Identifiable, Hashable {
    public static func == (lhs: ComiketDate, rhs: ComiketDate) -> Bool {
        return lhs.id == rhs.id && lhs.eventNumber == rhs.eventNumber
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventNumber)
    }

    public var eventNumber: Int
    public var id: Int
    public var date: Date

    public required init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colID = Expression<Int>("id")
        let colYear = Expression<Int>("year")
        let colMonth = Expression<Int>("month")
        let colDay = Expression<Int>("day")

        self.eventNumber = row[colEventNumber]
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
