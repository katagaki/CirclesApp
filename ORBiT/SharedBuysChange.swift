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
}

public struct SharedBuyPayload: Codable, Sendable {
    public var actor: Int
    public var kind: SharedBuyKind
    public var itemID: String
    public var circleID: Int
    public var text: String?
    public var value: Int?

    enum CodingKeys: String, CodingKey {
        case actor = "a"
        case kind = "k"
        case itemID = "i"
        case circleID = "c"
        case text = "t"
        case value = "v"
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

public struct SharedBuyItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let circleID: Int
    public var name: String
    public var cost: Int
    public var status: SharedBuyStatus
    public var assignee: Int?
    public var isRemoved: Bool
    public var lastTouchedBy: Int
}

public enum SharedBuyFold {
    public static func items(from changes: [SharedBuyChange]) -> [SharedBuyItem] {
        var byID: [String: SharedBuyItem] = [:]
        var order: [String] = []
        var deferred: [String: [SharedBuyChange]] = [:]

        for change in changes.sorted(by: ordered) {
            let payload = change.payload
            switch payload.kind {
            case .addItem:
                if byID[payload.itemID] == nil { order.append(payload.itemID) }
                byID[payload.itemID] = SharedBuyItem(
                    id: payload.itemID,
                    circleID: payload.circleID,
                    name: payload.text ?? "",
                    cost: payload.value ?? 0,
                    status: .pending,
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
            case .memberJoined:
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
        switch payload.kind {
        case .setStatus:
            byID[payload.itemID]?.status = SharedBuyStatus(rawValue: payload.value ?? 0) ?? .pending
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
        case .addItem, .memberJoined:
            break
        }
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
