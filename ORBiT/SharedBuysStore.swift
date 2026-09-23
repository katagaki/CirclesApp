import Foundation

struct SharedBuysSnapshot: Codable, Sendable {
    var sessionKey: Data
    var deviceID: String
    var deviceAuthKey: Data?
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

    /// Writes the snapshot, keeping it out of device backups.
    ///
    /// It holds the room key, this device's relay key and its change counter. Restored
    /// onto another phone it would speak as this device from a stale counter, and the
    /// relay silently drops every change that reuses a sequence number. The atomic
    /// write replaces the file, so the exclusion is set again after every save.
    static func save(_ snapshot: SharedBuysSnapshot) {
        guard var fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? fileURL.setResourceValues(values)
    }

    enum Pending {
        case save
        case clear
    }

    enum Write: Sendable {
        case save(SharedBuysSnapshot)
        case clear
    }

    static func perform(_ write: Write) {
        switch write {
        case .save(let snapshot): save(snapshot)
        case .clear: clear()
        }
    }

    static func clear() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}

@MainActor
extension SharedBuysSession {

    /// Marks the session as needing a save.
    ///
    /// One writer drains the latest request, so saves can neither land out of order —
    /// an older snapshot overwriting a newer one rolled `lastSeq` back, and the next
    /// change reused a sequence number the relay already held — nor outlive a `leave()`
    /// and bring the room back on the next launch. A burst of changes collapses into
    /// one write, and the snapshot is taken when the write starts, not per change.
    func persist() {
        guard sessionKey != nil else { return }
        submit(.save)
    }

    func submit(_ write: SharedBuysStore.Pending) {
        pendingWrite = write
        guard writeTask == nil else { return }
        writeTask = Task { await drainWrites() }
    }

    private func drainWrites() async {
        while let write = pendingWrite {
            pendingWrite = nil
            let operation: SharedBuysStore.Write
            switch write {
            case .clear:
                operation = .clear
            case .save:
                guard let sessionKey else { continue }
                operation = .save(
                    SharedBuysSnapshot(
                        sessionKey: sessionKey,
                        deviceID: deviceID,
                        deviceAuthKey: deviceAuthKey,
                        eventNumber: eventNumber,
                        lastSeq: lastSeq,
                        changes: changes
                    )
                )
            }
            await Task.detached(priority: .utility) { SharedBuysStore.perform(operation) }.value
        }
        writeTask = nil
    }
}
