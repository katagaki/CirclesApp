//
//  SharedBuysChange.swift
//  CiRCLES
//

import Foundation

enum SharedBuyKind: Int, Codable, Sendable {
    case addItem = 0
    case setStatus = 1
    case setAssignee = 2
    case setCost = 3
    case removeItem = 4
    case memberJoined = 5
}

enum SharedBuyStatus: Int, Codable, Sendable {
    case pending = 0
    case bought = 1
    case cancelled = 2

    var next: SharedBuyStatus {
        switch self {
        case .pending: .bought
        case .bought: .cancelled
        case .cancelled: .pending
        }
    }
}

struct SharedBuyPayload: Codable, Sendable {
    var actor: Int
    var kind: SharedBuyKind
    var itemID: String
    var circleID: Int
    var text: String?
    var value: Int?

    enum CodingKeys: String, CodingKey {
        case actor = "a"
        case kind = "k"
        case itemID = "i"
        case circleID = "c"
        case text = "t"
        case value = "v"
    }
}

struct SharedBuyChange: Codable, Sendable, Identifiable, Hashable {
    var device: String
    var seq: Int
    var payload: SharedBuyPayload

    var id: String { "\(device)#\(seq)" }

    static func == (lhs: SharedBuyChange, rhs: SharedBuyChange) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct SharedBuyItem: Identifiable, Sendable, Hashable {
    let id: String
    let circleID: Int
    var name: String
    var cost: Int
    var status: SharedBuyStatus
    var assignee: Int?
    var isRemoved: Bool
    var lastTouchedBy: Int
}

enum SharedBuyFold {
    static func items(from changes: [SharedBuyChange]) -> [SharedBuyItem] {
        var byID: [String: SharedBuyItem] = [:]
        var order: [String] = []
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
            case .setStatus:
                byID[payload.itemID]?.status = SharedBuyStatus(rawValue: payload.value ?? 0) ?? .pending
                byID[payload.itemID]?.lastTouchedBy = payload.actor
            case .setAssignee:
                byID[payload.itemID]?.assignee = payload.value
                byID[payload.itemID]?.lastTouchedBy = payload.actor
            case .setCost:
                byID[payload.itemID]?.cost = payload.value ?? 0
                byID[payload.itemID]?.lastTouchedBy = payload.actor
            case .removeItem:
                byID[payload.itemID]?.isRemoved = true
            case .memberJoined:
                continue
            }
        }
        return order.compactMap { byID[$0] }.filter { !$0.isRemoved }
    }

    static func members(from changes: [SharedBuyChange]) -> [Int: String] {
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
