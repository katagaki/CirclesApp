import Foundation

enum SharedBuyStatus: Int, Codable, Sendable, CaseIterable {
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

    var symbolName: String {
        switch self {
        case .pending: "circle"
        case .bought: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }
}

enum OpKind: String, Codable, Sendable {
    case addItem
    case setStatus
    case setAssignee
    case setCost
    case removeItem
    case memberJoined
}

struct Op: Codable, Sendable, Hashable, Identifiable {
    var lamport: Int
    var device: String
    var actor: Int
    var kind: OpKind
    var itemID: String
    var circleID: Int
    var text: String?
    var value: Int?

    var id: String { "\(device)#\(lamport)" }

    var wireSize: Int {
        (try? JSONEncoder().encode(self))?.count ?? 0
    }
}

extension Array where Element == Op {
    var causallySorted: [Op] {
        sorted { lhs, rhs in
            lhs.lamport == rhs.lamport ? lhs.device < rhs.device : lhs.lamport < rhs.lamport
        }
    }
}

typealias VersionVector = [String: Int]

extension Dictionary where Key == String, Value == Int {
    func missing(from ops: [Op]) -> [Op] {
        ops.filter { $0.lamport > (self[$0.device] ?? 0) }
    }

    var digest: String {
        var hash: UInt32 = 2166136261
        for key in keys.sorted() {
            for byte in Array(key.utf8) + withUnsafeBytes(of: UInt32(self[key] ?? 0).littleEndian, Array.init) {
                hash = (hash ^ UInt32(byte)) &* 16777619
            }
        }
        return String(format: "%04X", UInt16(truncatingIfNeeded: hash >> 8))
    }
}
