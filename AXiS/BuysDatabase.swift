//
//  BuysDatabase.swift
//  AXiS
//
//  Created by Claude on 2026/03/26.
//

import Foundation
import SQLite

public final class BuysDatabase: Sendable {

    public static let shared = BuysDatabase()

    let groupContainerURL: URL? = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
    )

    private init() {}

    private func connection(for eventNumber: Int) -> Connection? {
        guard let groupContainerURL else { return nil }
        let dbURL = groupContainerURL.appending(path: "buys\(eventNumber).db")
        return try? Connection(dbURL.path(percentEncoded: false))
    }

    private func createTablesIfNeeded(for eventNumber: Int) {
        guard let database = connection(for: eventNumber) else { return }
        do {
            try database.run("""
                CREATE TABLE IF NOT EXISTS BuyEntries (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    circleID INTEGER NOT NULL UNIQUE
                )
                """)
            try database.run("""
                CREATE TABLE IF NOT EXISTS BuyItems (
                    id TEXT PRIMARY KEY,
                    entryID INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    cost INTEGER NOT NULL DEFAULT 0,
                    imageData BLOB,
                    status INTEGER NOT NULL DEFAULT 0,
                    sortOrder INTEGER NOT NULL DEFAULT 0,
                    FOREIGN KEY (entryID) REFERENCES BuyEntries(id) ON DELETE CASCADE
                )
                """)
            try database.run("PRAGMA foreign_keys = ON")
        } catch {
            debugPrint("BuysDatabase: Failed to create tables: \(error.localizedDescription)")
        }
    }

    // MARK: - Entries

    public func entries(for eventNumber: Int) -> [BuyEntry] {
        createTablesIfNeeded(for: eventNumber)
        guard let database = connection(for: eventNumber) else { return [] }

        let entriesTable = Table("BuyEntries")
        let itemsTable = Table("BuyItems")
        let colID = Expression<Int>("id")
        let colCircleID = Expression<Int>("circleID")
        let colItemID = Expression<String>("id")
        let colEntryID = Expression<Int>("entryID")
        let colName = Expression<String>("name")
        let colCost = Expression<Int>("cost")
        let colImageData = Expression<Data?>("imageData")
        let colStatus = Expression<Int>("status")
        let colSortOrder = Expression<Int>("sortOrder")

        do {
            var result: [BuyEntry] = []
            for entryRow in try database.prepare(entriesTable) {
                let entryID = entryRow[colID]
                let circleID = entryRow[colCircleID]
                let query = itemsTable.filter(colEntryID == entryID).order(colSortOrder.asc)
                let items: [BuyItem] = try database.prepare(query).map { row in
                    BuyItem(
                        id: row[colItemID],
                        name: row[colName],
                        cost: row[colCost],
                        imageData: row[colImageData],
                        status: BuyItemStatus(rawValue: row[colStatus]) ?? .pending,
                        sortOrder: row[colSortOrder]
                    )
                }
                result.append(BuyEntry(id: entryID, circleID: circleID, items: items))
            }
            return result
        } catch {
            debugPrint("BuysDatabase: Failed to fetch entries: \(error.localizedDescription)")
            return []
        }
    }

    public func entry(for circleID: Int, eventNumber: Int) -> BuyEntry? {
        createTablesIfNeeded(for: eventNumber)
        guard let database = connection(for: eventNumber) else { return nil }

        let entriesTable = Table("BuyEntries")
        let itemsTable = Table("BuyItems")
        let colID = Expression<Int>("id")
        let colCircleID = Expression<Int>("circleID")
        let colItemID = Expression<String>("id")
        let colEntryID = Expression<Int>("entryID")
        let colName = Expression<String>("name")
        let colCost = Expression<Int>("cost")
        let colImageData = Expression<Data?>("imageData")
        let colStatus = Expression<Int>("status")
        let colSortOrder = Expression<Int>("sortOrder")

        do {
            guard let entryRow = try database.pluck(entriesTable.filter(colCircleID == circleID)) else {
                return nil
            }
            let entryID = entryRow[colID]
            let query = itemsTable.filter(colEntryID == entryID).order(colSortOrder.asc)
            let items: [BuyItem] = try database.prepare(query).map { row in
                BuyItem(
                    id: row[colItemID],
                    name: row[colName],
                    cost: row[colCost],
                    imageData: row[colImageData],
                    status: BuyItemStatus(rawValue: row[colStatus]) ?? .pending,
                    sortOrder: row[colSortOrder]
                )
            }
            return BuyEntry(id: entryID, circleID: circleID, items: items)
        } catch {
            debugPrint("BuysDatabase: Failed to fetch entry: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Items

    public func addItem(_ item: BuyItem, circleID: Int, eventNumber: Int) {
        createTablesIfNeeded(for: eventNumber)
        guard let database = connection(for: eventNumber) else { return }

        let entriesTable = Table("BuyEntries")
        let itemsTable = Table("BuyItems")
        let colID = Expression<Int>("id")
        let colCircleID = Expression<Int>("circleID")
        let colItemID = Expression<String>("id")
        let colEntryID = Expression<Int>("entryID")
        let colName = Expression<String>("name")
        let colCost = Expression<Int>("cost")
        let colImageData = Expression<Data?>("imageData")
        let colStatus = Expression<Int>("status")
        let colSortOrder = Expression<Int>("sortOrder")

        do {
            try database.run("PRAGMA foreign_keys = ON")

            let entryID: Int
            if let existingEntry = try database.pluck(entriesTable.filter(colCircleID == circleID)) {
                entryID = existingEntry[colID]
            } else {
                entryID = Int(try database.run(entriesTable.insert(
                    colCircleID <- circleID
                )))
            }

            let maxOrder = try database.scalar(
                itemsTable.filter(colEntryID == entryID).select(colSortOrder.max)
            ) ?? -1

            try database.run(itemsTable.insert(
                colItemID <- item.id,
                colEntryID <- entryID,
                colName <- item.name,
                colCost <- item.cost,
                colImageData <- item.imageData,
                colStatus <- item.status.rawValue,
                colSortOrder <- maxOrder + 1
            ))
        } catch {
            debugPrint("BuysDatabase: Failed to add item: \(error.localizedDescription)")
        }
    }

    public func updateItem(_ item: BuyItem, eventNumber: Int) {
        createTablesIfNeeded(for: eventNumber)
        guard let database = connection(for: eventNumber) else { return }

        let itemsTable = Table("BuyItems")
        let colItemID = Expression<String>("id")
        let colName = Expression<String>("name")
        let colCost = Expression<Int>("cost")
        let colImageData = Expression<Data?>("imageData")
        let colStatus = Expression<Int>("status")
        let colSortOrder = Expression<Int>("sortOrder")

        let row = itemsTable.filter(colItemID == item.id)
        do {
            try database.run(row.update(
                colName <- item.name,
                colCost <- item.cost,
                colImageData <- item.imageData,
                colStatus <- item.status.rawValue,
                colSortOrder <- item.sortOrder
            ))
        } catch {
            debugPrint("BuysDatabase: Failed to update item: \(error.localizedDescription)")
        }
    }

    public func deleteItem(id: String, eventNumber: Int) {
        createTablesIfNeeded(for: eventNumber)
        guard let database = connection(for: eventNumber) else { return }

        let itemsTable = Table("BuyItems")
        let entriesTable = Table("BuyEntries")
        let colItemID = Expression<String>("id")
        let colEntryID = Expression<Int>("entryID")
        let colID = Expression<Int>("id")

        do {
            try database.run("PRAGMA foreign_keys = ON")

            if let itemRow = try database.pluck(itemsTable.filter(colItemID == id)) {
                let entryID = itemRow[colEntryID]
                try database.run(itemsTable.filter(colItemID == id).delete())

                let remainingCount = try database.scalar(
                    itemsTable.filter(colEntryID == entryID).count
                )
                if remainingCount == 0 {
                    try database.run(entriesTable.filter(colID == entryID).delete())
                }
            }
        } catch {
            debugPrint("BuysDatabase: Failed to delete item: \(error.localizedDescription)")
        }
    }

    public func moveItems(circleID: Int, eventNumber: Int, fromOffsets: IndexSet, toOffset: Int) {
        guard var entry = entry(for: circleID, eventNumber: eventNumber) else { return }
        var items = entry.items
        let moving = fromOffsets.map { items[$0] }
        for index in fromOffsets.sorted().reversed() {
            items.remove(at: index)
        }
        let insertAt = min(toOffset, items.count)
        items.insert(contentsOf: moving, at: insertAt)
        for (index, item) in items.enumerated() {
            var updated = item
            updated.sortOrder = index
            updateItem(updated, eventNumber: eventNumber)
        }
    }
}

// MARK: - Data Types

public struct BuyEntry: Identifiable, Sendable {
    public let id: Int
    public let circleID: Int
    public var items: [BuyItem]

    public init(id: Int, circleID: Int, items: [BuyItem]) {
        self.id = id
        self.circleID = circleID
        self.items = items
    }
}

public struct BuyItem: Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var cost: Int
    public var imageData: Data?
    public var status: BuyItemStatus
    public var sortOrder: Int

    public init(
        id: String = UUID().uuidString,
        name: String,
        cost: Int,
        imageData: Data? = nil,
        status: BuyItemStatus = .pending,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.cost = cost
        self.imageData = imageData
        self.status = status
        self.sortOrder = sortOrder
    }
}

public enum BuyItemStatus: Int, Sendable {
    case pending = 0
    case bought = 1
    case cancelled = 2

    public var next: BuyItemStatus {
        switch self {
        case .pending: .bought
        case .bought: .cancelled
        case .cancelled: .pending
        }
    }
}
