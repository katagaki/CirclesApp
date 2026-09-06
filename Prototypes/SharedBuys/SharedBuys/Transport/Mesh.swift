//
//  Mesh.swift
//  SharedBuys
//

import Foundation
import Observation

enum Channel: String, Sendable {
    case bluetooth
    case internet

    var symbolName: String {
        switch self {
        case .bluetooth: "dot.radiowaves.left.and.right"
        case .internet: "network"
        }
    }
}

struct WireEvent: Identifiable, Sendable {
    let id = UUID()
    let at: Date
    let from: String
    let to: String
    let channel: Channel
    let bytes: Int
    let opCount: Int
    let summary: String
}

@Observable
@MainActor
final class DeviceNode: @MainActor Identifiable {

    let member: Member
    var id: String { member.deviceID }

    var ops: [Op] = []
    var lamport: Int = 0

    var isSessionActive: Bool = false
    var isBluetoothEnabled: Bool = true
    var isNearby: Bool = true
    var hasInternet: Bool = true

    var acknowledgedVectors: [String: VersionVector] = [:]
    var bytesOverBluetooth: Int = 0
    var bytesOverInternet: Int = 0
    var advertisementsSkipped: Int = 0

    init(member: Member) {
        self.member = member
    }

    var versionVector: VersionVector {
        ops.reduce(into: VersionVector()) { result, op in
            result[op.device] = max(result[op.device] ?? 0, op.lamport)
        }
    }

    var items: [SharedItem] {
        SessionFold.items(from: ops)
    }

    func items(forCircle circleID: Int) -> [SharedItem] {
        items.filter { $0.circleID == circleID }
    }

    func apply(_ incoming: [Op]) {
        let known = Set(ops.map(\.id))
        let fresh = incoming.filter { !known.contains($0.id) }
        guard !fresh.isEmpty else { return }
        ops.append(contentsOf: fresh)
        lamport = max(lamport, fresh.map(\.lamport).max() ?? 0)
    }

    @discardableResult
    func makeOp(_ kind: OpKind, itemID: String, circleID: Int, text: String? = nil, value: Int? = nil) -> Op {
        lamport += 1
        let op = Op(
            lamport: lamport,
            device: id,
            actor: member.id,
            kind: kind,
            itemID: itemID,
            circleID: circleID,
            text: text,
            value: value
        )
        ops.append(op)
        return op
    }
}

@Observable
@MainActor
final class Mesh {

    var devices: [DeviceNode]
    var wireLog: [WireEvent] = []
    var focusedDeviceID: String
    var isJapanese: Bool = true

    private var timer: Timer?

    init() {
        let nodes = SampleData.members.map { DeviceNode(member: $0) }
        self.devices = nodes
        self.focusedDeviceID = nodes[0].id
        nodes[0].ops = SampleData.seedOps()
        nodes[0].lamport = nodes[0].ops.map(\.lamport).max() ?? 0
        nodes[0].isSessionActive = true
        start()
    }

    var focused: DeviceNode {
        devices.first { $0.id == focusedDeviceID } ?? devices[0]
    }

    func device(_ deviceID: String) -> DeviceNode? {
        devices.first { $0.id == deviceID }
    }

    func member(pid: Int?) -> Member? {
        guard let pid else { return nil }
        return SampleData.members.first { $0.id == pid }
    }

    var activeDevices: [DeviceNode] {
        devices.filter(\.isSessionActive)
    }

    func nearbyPeers(of node: DeviceNode) -> [DeviceNode] {
        activeDevices.filter { $0.id != node.id && channel(from: node, to: $0) == .bluetooth }
    }

    func channel(from source: DeviceNode, to destination: DeviceNode) -> Channel? {
        guard source.isSessionActive, destination.isSessionActive else { return nil }
        if source.isBluetoothEnabled, destination.isBluetoothEnabled, source.isNearby, destination.isNearby {
            return .bluetooth
        }
        if source.hasInternet, destination.hasInternet {
            return .internet
        }
        return nil
    }

    func connectivity(of node: DeviceNode) -> Channel? {
        guard node.isSessionActive else { return nil }
        let peers = activeDevices.filter { $0.id != node.id }
        if peers.contains(where: { channel(from: node, to: $0) == .bluetooth }) { return .bluetooth }
        if peers.contains(where: { channel(from: node, to: $0) == .internet }) { return .internet }
        return nil
    }

    func pendingCount(for node: DeviceNode) -> Int {
        let peers = activeDevices.filter { $0.id != node.id }
        guard !peers.isEmpty else { return 0 }
        return peers.reduce(0) { total, peer in
            let acknowledged = node.acknowledgedVectors[peer.id] ?? [:]
            return max(total, acknowledged.missing(from: node.ops).count)
        }
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            Task { @MainActor in self.converge() }
        }
    }

    func converge() {
        for source in activeDevices {
            for destination in activeDevices where destination.id != source.id {
                guard let channel = channel(from: source, to: destination) else { continue }
                let acknowledged = source.acknowledgedVectors[destination.id] ?? [:]
                if !acknowledged.isEmpty, acknowledged.digest == destination.versionVector.digest,
                   destination.versionVector.missing(from: source.ops).isEmpty {
                    source.advertisementsSkipped += 1
                    continue
                }
                let missing = destination.versionVector.missing(from: source.ops).causallySorted
                source.acknowledgedVectors[destination.id] = destination.versionVector
                destination.acknowledgedVectors[source.id] = source.versionVector
                guard !missing.isEmpty else {
                    source.advertisementsSkipped += 1
                    continue
                }
                destination.apply(missing)
                source.acknowledgedVectors[destination.id] = destination.versionVector
                let bytes = missing.reduce(0) { $0 + $1.wireSize }
                switch channel {
                case .bluetooth: source.bytesOverBluetooth += bytes
                case .internet: source.bytesOverInternet += bytes
                }
                record(
                    WireEvent(
                        at: .now,
                        from: source.id,
                        to: destination.id,
                        channel: channel,
                        bytes: bytes,
                        opCount: missing.count,
                        summary: summary(of: missing)
                    )
                )
            }
        }
    }

    private func summary(of ops: [Op]) -> String {
        guard let first = ops.first else { return "" }
        let label = first.kind.rawValue
        return ops.count == 1 ? label : "\(label) +\(ops.count - 1)"
    }

    private func record(_ event: WireEvent) {
        wireLog.insert(event, at: 0)
        if wireLog.count > 60 {
            wireLog.removeLast(wireLog.count - 60)
        }
    }

    func join(_ node: DeviceNode) {
        guard !node.isSessionActive else { return }
        node.isSessionActive = true
        node.makeOp(.memberJoined, itemID: "-", circleID: 0, text: node.member.nickname, value: node.member.id)
        converge()
    }

    func leave(_ node: DeviceNode) {
        node.isSessionActive = false
        node.acknowledgedVectors.removeAll()
    }

    var totalBluetoothBytes: Int { devices.reduce(0) { $0 + $1.bytesOverBluetooth } }
    var totalInternetBytes: Int { devices.reduce(0) { $0 + $1.bytesOverInternet } }
    var totalSkipped: Int { devices.reduce(0) { $0 + $1.advertisementsSkipped } }
}
