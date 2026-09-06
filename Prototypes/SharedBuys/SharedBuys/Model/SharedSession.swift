//
//  SharedSession.swift
//  SharedBuys
//

import Foundation

struct Member: Identifiable, Hashable, Sendable {
    let id: Int
    let nickname: String
    let deviceID: String
    let tint: Int
}

struct SharedItem: Identifiable, Hashable, Sendable {
    let id: String
    let circleID: Int
    var name: String
    var cost: Int
    var status: SharedBuyStatus = .pending
    var assignee: Int?
    var isRemoved: Bool = false
    var lastTouchedBy: Int?
}

struct SharedCircle: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let space: String
    let day: Int
}

enum SampleData {
    static let circles: [SharedCircle] = [
        SharedCircle(id: 1, name: "こんぺいとう工房", space: "東 A-12a", day: 1),
        SharedCircle(id: 2, name: "Studio Mikazuki", space: "東 D-45b", day: 1),
        SharedCircle(id: 3, name: "藍色ノート", space: "西 は-03a", day: 2),
        SharedCircle(id: 4, name: "Neon Parade", space: "南 ま-21b", day: 2)
    ]

    static let members: [Member] = [
        Member(id: 1001, nickname: "Justin", deviceID: "A", tint: 0),
        Member(id: 1002, nickname: "Aoi", deviceID: "B", tint: 1),
        Member(id: 1003, nickname: "Mika", deviceID: "C", tint: 2)
    ]

    static func seedOps() -> [Op] {
        var lamport = 0
        func next() -> Int {
            lamport += 1
            return lamport
        }
        return [
            Op(lamport: next(), device: "A", actor: 1001, kind: .addItem, itemID: "i1", circleID: 1,
               text: "新刊 B5 アンソロジー", value: 1200),
            Op(lamport: next(), device: "A", actor: 1001, kind: .addItem, itemID: "i2", circleID: 1,
               text: "アクリルスタンド", value: 2500),
            Op(lamport: next(), device: "A", actor: 1001, kind: .addItem, itemID: "i3", circleID: 2,
               text: "設定資料集", value: 3000),
            Op(lamport: next(), device: "A", actor: 1001, kind: .addItem, itemID: "i4", circleID: 3,
               text: "缶バッジセット", value: 800),
            Op(lamport: next(), device: "A", actor: 1001, kind: .addItem, itemID: "i5", circleID: 4,
               text: "タペストリー", value: 4500),
            Op(lamport: next(), device: "A", actor: 1001, kind: .setAssignee, itemID: "i1", circleID: 1,
               text: nil, value: 1002),
            Op(lamport: next(), device: "A", actor: 1001, kind: .setAssignee, itemID: "i4", circleID: 3,
               text: nil, value: 1003),
            Op(lamport: next(), device: "A", actor: 1001, kind: .setAssignee, itemID: "i2", circleID: 1,
               text: nil, value: 1001),
            Op(lamport: next(), device: "A", actor: 1001, kind: .setAssignee, itemID: "i3", circleID: 2,
               text: nil, value: 1001)
        ]
    }
}

struct SessionFold {
    static func items(from ops: [Op]) -> [SharedItem] {
        var byID: [String: SharedItem] = [:]
        var order: [String] = []
        for op in ops.causallySorted {
            switch op.kind {
            case .addItem:
                if byID[op.itemID] == nil {
                    order.append(op.itemID)
                }
                byID[op.itemID] = SharedItem(
                    id: op.itemID,
                    circleID: op.circleID,
                    name: op.text ?? "",
                    cost: op.value ?? 0,
                    lastTouchedBy: op.actor
                )
            case .setStatus:
                byID[op.itemID]?.status = SharedBuyStatus(rawValue: op.value ?? 0) ?? .pending
                byID[op.itemID]?.lastTouchedBy = op.actor
            case .setAssignee:
                byID[op.itemID]?.assignee = op.value
                byID[op.itemID]?.lastTouchedBy = op.actor
            case .setCost:
                byID[op.itemID]?.cost = op.value ?? 0
                byID[op.itemID]?.lastTouchedBy = op.actor
            case .removeItem:
                byID[op.itemID]?.isRemoved = true
            case .memberJoined:
                continue
            }
        }
        return order.compactMap { byID[$0] }.filter { !$0.isRemoved }
    }
}
