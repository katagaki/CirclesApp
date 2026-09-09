//
//  SharedBuysStore.swift
//  CiRCLES
//

import Foundation

struct SharedBuysSnapshot: Codable {
    var sessionKey: Data
    var deviceID: String
    var eventNumber: Int
    var lastSeq: Int
    var changes: [SharedBuyChange]
}

enum SharedBuysStore {

    static let filename = "shared-buys-session.json"

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES")?
            .appending(path: filename)
    }

    static func load() -> SharedBuysSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SharedBuysSnapshot.self, from: data)
    }

    static func save(_ snapshot: SharedBuysSnapshot) {
        guard let fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Serialises saves so two in flight cannot land out of order.
    actor Writer {
        func save(_ snapshot: SharedBuysSnapshot) { SharedBuysStore.save(snapshot) }
    }

    static let writer = Writer()

    static func clear() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
