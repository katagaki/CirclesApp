//
//  SharedBuysChange.swift
//  CiRCLES
//

import Foundation

public enum SharedBuyKind: Int, Codable, Sendable {
    case addItem = 0
    case setStatus = 1
    case setAssignee = 2
    case setCost = 3
    case removeItem = 4
    case memberJoined = 5
    case renameItem = 6

    /// Circle name and space, relayed once per circle so a member without the
    /// catalog database can still read the list.
    ///
    /// A guest joins by scanning a code and never downloads the catalog, so
    /// `database.circles(_:)` returns nothing and every section header would read
    /// "Unknown circle 12345". The contributor who first adds an item from a circle
    /// carries that circle's name and space into the log alongside it, so the guest
    /// reads the header off the log instead. Sent once per circle per room.
    case circleInfo = 7

    /// Whether this kind is carried over the peer-to-peer Bluetooth path.
    ///
    /// Bluetooth frames are chunked at 160 bytes and reassembled by hand, so the
    /// transport is only dependable for small, self-contained payloads. Item names,
    /// costs and images travel over the relay exclusively; on-site we only exchange
    /// status flips, which is what makes the list useful while walking a venue.
    public var travelsOverBluetooth: Bool {
        switch self {
        case .setStatus: true
        default: false
        }
    }
}

public enum SharedBuyStatus: Int, Codable, Sendable {
    case pending = 0
    case bought = 1
    case cancelled = 2

    public var next: SharedBuyStatus {
        switch self {
        case .pending: .bought
        case .bought: .cancelled
        case .cancelled: .pending
        }
    }

    /// The next status in the cycle, starting from a raw value this build may not know.
    ///
    /// Mirrors Android's `SharedBuyStatus.next`, where anything unrecognised cycles to
    /// pending. Coercing the unknown value to pending first and then advancing would
    /// land on bought instead, and the two platforms would disagree after one tap.
    public static func next(after rawStatus: Int) -> SharedBuyStatus {
        SharedBuyStatus(rawValue: rawStatus)?.next ?? .pending
    }
}

public struct SharedBuyPayload: Codable, Sendable {
    public var actor: Int

    /// The change kind exactly as it arrived on the wire.
    ///
    /// Decoding this as a closed enum made any kind this build does not know a hard
    /// decode failure: the change was dropped, never reached the log or the version
    /// vector, and was re-requested on every `want` forever — while Android, which
    /// stores the raw int, kept it. The two devices then disagreed permanently. A kind
    /// we cannot interpret is now folded as a no-op instead, so a future change kind
    /// costs an old build a missing feature rather than a divergent list.
    public var rawKind: Int

    public var itemID: String
    public var circleID: Int
    public var text: String?
    public var value: Int?

    /// The circle's space, as `spaceName()` renders it. Only `circleInfo` sets it.
    ///
    /// A separate field rather than a delimiter inside `text`: a circle name is
    /// user-supplied and may contain anything, so any separator would eventually be
    /// part of a name. Optional, so it costs nothing on the other six kinds — both
    /// platforms omit nil rather than encoding null.
    public var space: String?

    /// The kind, when it is one this build understands.
    public var kind: SharedBuyKind? { SharedBuyKind(rawValue: rawKind) }

    public init(
        actor: Int,
        kind: SharedBuyKind,
        itemID: String,
        circleID: Int,
        text: String? = nil,
        value: Int? = nil,
        space: String? = nil
    ) {
        self.actor = actor
        self.rawKind = kind.rawValue
        self.itemID = itemID
        self.circleID = circleID
        self.text = text
        self.value = value
        self.space = space
    }

    enum CodingKeys: String, CodingKey {
        case actor = "a"
        case rawKind = "k"
        case itemID = "i"
        case circleID = "c"
        case text = "t"
        case value = "v"
        case space = "s"
    }
}

public struct SharedBuyChange: Codable, Sendable, Identifiable, Hashable {
    public var device: String
    public var seq: Int
    public var payload: SharedBuyPayload

    public var id: String { "\(device)#\(seq)" }

    public static func == (lhs: SharedBuyChange, rhs: SharedBuyChange) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A circle as the shared log describes it, for a member who cannot look it up.
public struct SharedBuyCircle: Identifiable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let space: String?
}

public struct SharedBuyItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let circleID: Int
    public var name: String
    public var cost: Int

    /// The status exactly as the log recorded it, which may not be one of the three
    /// this build knows. Kept raw so a status flip written by a newer build survives a
    /// round trip through this one, and so cycling matches Android.
    public var rawStatus: Int

    public var assignee: Int?
    public var isRemoved: Bool
    public var lastTouchedBy: Int

    public var status: SharedBuyStatus { SharedBuyStatus(rawValue: rawStatus) ?? .pending }
}

public enum SharedBuyFold {
    public static func items(from changes: [SharedBuyChange]) -> [SharedBuyItem] {
        var byID: [String: SharedBuyItem] = [:]
        var order: [String] = []
        var deferred: [String: [SharedBuyChange]] = [:]

        for change in changes.sorted(by: ordered) {
            let payload = change.payload
            // A kind this build does not understand cannot be folded into an item, but
            // it stays in `changes` and in the version vector so the log still matches
            // a build that does understand it.
            guard let kind = payload.kind else { continue }
            switch kind {
            case .addItem:
                if byID[payload.itemID] == nil { order.append(payload.itemID) }
                byID[payload.itemID] = SharedBuyItem(
                    id: payload.itemID,
                    circleID: payload.circleID,
                    name: payload.text ?? "",
                    cost: payload.value ?? 0,
                    rawStatus: SharedBuyStatus.pending.rawValue,
                    assignee: nil,
                    isRemoved: false,
                    lastTouchedBy: payload.actor
                )
                // A mutation can land before the addItem it targets: Bluetooth carries
                // status flips but never the item itself, so a peer can learn that
                // something was bought before the relay delivers what it is. Replay
                // whatever was parked on this item, in the same order it was folded.
                for pending in deferred.removeValue(forKey: payload.itemID) ?? [] {
                    apply(pending, to: &byID)
                }
            case .memberJoined, .circleInfo:
                continue
            default:
                if byID[payload.itemID] == nil {
                    deferred[payload.itemID, default: []].append(change)
                } else {
                    apply(change, to: &byID)
                }
            }
        }
        return order.compactMap { byID[$0] }.filter { !$0.isRemoved }
    }

    private static func apply(_ change: SharedBuyChange, to byID: inout [String: SharedBuyItem]) {
        let payload = change.payload
        guard let kind = payload.kind else { return }
        switch kind {
        case .setStatus:
            // Stored raw. Coercing an unrecognised status to pending here made this
            // device disagree with Android, which keeps the value it was sent.
            byID[payload.itemID]?.rawStatus = payload.value ?? 0
            byID[payload.itemID]?.lastTouchedBy = payload.actor
        case .setAssignee:
            byID[payload.itemID]?.assignee = payload.value
            byID[payload.itemID]?.lastTouchedBy = payload.actor
        case .setCost:
            byID[payload.itemID]?.cost = payload.value ?? 0
            byID[payload.itemID]?.lastTouchedBy = payload.actor
        case .renameItem:
            byID[payload.itemID]?.name = payload.text ?? ""
            byID[payload.itemID]?.lastTouchedBy = payload.actor
        case .removeItem:
            byID[payload.itemID]?.isRemoved = true
        case .addItem, .memberJoined, .circleInfo:
            break
        }
    }

    /// Circle name and space per circle ID, as the log carries them.
    ///
    /// Only ever a fallback for a member holding the catalog database, which is both
    /// richer and current; for a guest it is the only source there is.
    public static func circles(from changes: [SharedBuyChange]) -> [Int: SharedBuyCircle] {
        var result: [Int: SharedBuyCircle] = [:]
        for change in changes.sorted(by: ordered) where change.payload.kind == .circleInfo {
            result[change.payload.circleID] = SharedBuyCircle(
                id: change.payload.circleID,
                name: change.payload.text ?? "",
                space: change.payload.space
            )
        }
        return result
    }

    public static func members(from changes: [SharedBuyChange]) -> [Int: String] {
        var result: [Int: String] = [:]
        for change in changes.sorted(by: ordered) where change.payload.kind == .memberJoined {
            result[change.payload.actor] = change.payload.text ?? ""
        }
        return result
    }

    private static func ordered(_ lhs: SharedBuyChange, _ rhs: SharedBuyChange) -> Bool {
        lhs.seq == rhs.seq ? lhs.device < rhs.device : lhs.seq < rhs.seq
    }
}
