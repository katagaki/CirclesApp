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

    /// The app group on iOS, Application Support when there is no group to join.
    ///
    /// The Mac harness is not a member of `group.com.tsubuzaki.CiRCLES` — the group is
    /// registered for iOS — and without a fallback every save there silently did nothing.
    static var fileURL: URL? {
        let manager = FileManager.default
        // Existence, not a non-nil URL, is what says the group is really there.
        if let container = manager
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"),
           manager.fileExists(atPath: container.path()) {
            return container.appending(path: filename)
        }
        return try? manager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
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
