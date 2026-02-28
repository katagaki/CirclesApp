//
//  AttachmentsDatabase.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import Foundation
import SQLite

final class AttachmentsDatabase: Sendable {

    static let shared = AttachmentsDatabase()

    let groupContainerURL: URL? = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
    )

    private init() {
        createTableIfNeeded()
    }

    private func connection() -> Connection? {
        guard let groupContainerURL else { return nil }
        let dbURL = groupContainerURL.appending(path: "Attachments.db")
        return try? Connection(dbURL.path(percentEncoded: false))
    }

    private func createTableIfNeeded() {
        guard let db = connection() else { return }
        do {
            try db.run("""
                CREATE TABLE IF NOT EXISTS Attachments (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    eventNumber INTEGER NOT NULL,
                    circleID INTEGER NOT NULL,
                    attachmentType TEXT NOT NULL,
                    type TEXT NOT NULL,
                    attachmentBlob BLOB NOT NULL
                )
                """)
        } catch {
            debugPrint("AttachmentsDatabase: Failed to create table: \(error.localizedDescription)")
        }
    }

    // MARK: - CRUD

    func insert(
        eventNumber: Int,
        circleID: Int,
        attachmentType: String,
        type: String,
        attachmentBlob: Data
    ) {
        guard let db = connection() else { return }
        let table = Table("Attachments")
        let colEventNumber = Expression<Int>("eventNumber")
        let colCircleID = Expression<Int>("circleID")
        let colAttachmentType = Expression<String>("attachmentType")
        let colType = Expression<String>("type")
        let colAttachmentBlob = Expression<Data>("attachmentBlob")

        do {
            try db.run(table.insert(
                colEventNumber <- eventNumber,
                colCircleID <- circleID,
                colAttachmentType <- attachmentType,
                colType <- type,
                colAttachmentBlob <- attachmentBlob
            ))
        } catch {
            debugPrint("AttachmentsDatabase: Failed to insert: \(error.localizedDescription)")
        }
    }

    func attachments(eventNumber: Int, circleID: Int) -> [CircleAttachment] {
        guard let db = connection() else { return [] }
        let table = Table("Attachments")
        let colID = Expression<Int>("id")
        let colEventNumber = Expression<Int>("eventNumber")
        let colCircleID = Expression<Int>("circleID")
        let colAttachmentType = Expression<String>("attachmentType")
        let colType = Expression<String>("type")
        let colAttachmentBlob = Expression<Data>("attachmentBlob")

        let query = table.filter(colEventNumber == eventNumber && colCircleID == circleID)
        do {
            return try db.prepare(query).map { row in
                CircleAttachment(
                    id: row[colID],
                    eventNumber: row[colEventNumber],
                    circleID: row[colCircleID],
                    attachmentType: row[colAttachmentType],
                    type: row[colType],
                    attachmentBlob: row[colAttachmentBlob]
                )
            }
        } catch {
            debugPrint("AttachmentsDatabase: Failed to fetch: \(error.localizedDescription)")
            return []
        }
    }

    func delete(id: Int) {
        guard let db = connection() else { return }
        let table = Table("Attachments")
        let colID = Expression<Int>("id")
        let row = table.filter(colID == id)
        do {
            try db.run(row.delete())
        } catch {
            debugPrint("AttachmentsDatabase: Failed to delete: \(error.localizedDescription)")
        }
    }
}

struct CircleAttachment: Identifiable, Sendable {
    let id: Int
    let eventNumber: Int
    let circleID: Int
    let attachmentType: String
    let type: String
    let attachmentBlob: Data
}
