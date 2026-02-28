//
//  CircleSearcher.swift
//  AttachProductList
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import Foundation
import SQLite

struct ActionExtensionCircle: Identifiable, Sendable {
    let id: Int
    let eventNumber: Int
    let circleName: String
    let penName: String
}

enum CircleSearcher {

    static func search(_ searchTerm: String) -> [ActionExtensionCircle] {
        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        guard term.count >= 2 else { return [] }

        let databaseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let databaseURL else { return [] }

        let activeEventNumber = UserDefaults.standard.integer(forKey: "Events.Active.Number")
        guard activeEventNumber > 0 else { return [] }

        let textDBURL = databaseURL.appending(path: "webcatalog\(activeEventNumber).db")
        guard FileManager.default.fileExists(atPath: textDBURL.path(percentEncoded: false)),
              let db = try? Connection(textDBURL.path(percentEncoded: false), readonly: true) else {
            return []
        }

        do {
            let table = Table("ComiketCircleWC")
            let colID = Expression<Int>("id")
            let colEventNumber = table[Expression<Int>("comiketNo")]
            let colCircleName = Expression<String>("circleName")
            let colCircleNameKana = Expression<String>("circleKana")
            let colPenName = Expression<String>("penName")

            let query = table.filter(
                colCircleName.like("%\(term)%") ||
                colCircleNameKana.like("%\(term)%") ||
                colPenName.like("%\(term)%")
            )

            return try db.prepare(query).map { row in
                ActionExtensionCircle(
                    id: row[colID],
                    eventNumber: row[colEventNumber],
                    circleName: row[colCircleName],
                    penName: row[colPenName]
                )
            }
        } catch {
            debugPrint("Search failed: \(error.localizedDescription)")
            return []
        }
    }
}
