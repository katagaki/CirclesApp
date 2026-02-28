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

struct CircleSearchResult: Sendable {
    let circles: [ActionExtensionCircle]
    let totalCount: Int
}

enum CircleSearcher {

    static let groupContainerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
    )
    nonisolated(unsafe) static let sharedDefaults = UserDefaults(suiteName: "group.com.tsubuzaki.CiRCLES")
    nonisolated(unsafe) private static var cachedConnection: Connection?
    nonisolated(unsafe) private static var cachedEventNumber: Int?

    static func search(_ searchTerm: String) -> CircleSearchResult {
        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        guard term.count >= 2 else { return CircleSearchResult(circles: [], totalCount: 0) }

        guard let db = getConnection() else { return CircleSearchResult(circles: [], totalCount: 0) }

        do {
            let table = Table("ComiketCircleWC")
            let colID = table[Expression<Int>("id")]
            let colEventNumber = table[Expression<Int>("comiketNo")]
            let colCircleName = Expression<String>("circleName")
            let colCircleNameKana = Expression<String>("circleKana")
            let colPenName = Expression<String>("penName")

            let filtered = table.filter(
                colCircleName.like("%\(term)%") ||
                colCircleNameKana.like("%\(term)%") ||
                colPenName.like("%\(term)%")
            )

            let totalCount = try db.scalar(filtered.count)

            let circles = try db.prepare(filtered.limit(10)).map { row in
                ActionExtensionCircle(
                    id: row[colID],
                    eventNumber: row[colEventNumber],
                    circleName: row[colCircleName],
                    penName: row[colPenName]
                )
            }

            return CircleSearchResult(circles: circles, totalCount: totalCount)
        } catch {
            debugPrint("Search failed: \(error.localizedDescription)")
            return CircleSearchResult(circles: [], totalCount: 0)
        }
    }

    private static func getConnection() -> Connection? {
        let activeEventNumber = sharedDefaults?.integer(forKey: "Events.Active.Number") ?? 0
        guard activeEventNumber > 0 else { return nil }

        if let cachedConnection, cachedEventNumber == activeEventNumber {
            return cachedConnection
        }

        guard let groupContainerURL else { return nil }
        let textDBURL = groupContainerURL.appending(path: "webcatalog\(activeEventNumber).db")
        guard FileManager.default.fileExists(atPath: textDBURL.path(percentEncoded: false)),
              let db = try? Connection(textDBURL.path(percentEncoded: false), readonly: true) else {
            return nil
        }

        cachedConnection = db
        cachedEventNumber = activeEventNumber
        return db
    }
}
