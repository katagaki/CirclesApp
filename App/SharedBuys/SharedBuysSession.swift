//
//  SharedBuysSession.swift
//  CiRCLES
//

import CryptoKit
import Foundation
import Observation

enum SharedBuysStatus: Equatable {
    case idle
    case connecting
    case connected
    case offline(String)
}

@Observable
@MainActor
final class SharedBuysSession {

    static let joinHost = "buys-join"

    var status: SharedBuysStatus = .idle
    var log: [String] = []
    var relayBaseURL: String = "ws://127.0.0.1:8787"
    var actorPID: Int = 0

    private(set) var sessionKey: Data?
    private(set) var deviceID: String = ""
    private(set) var eventNumber: Int = 0
    private(set) var changes: [SharedBuyChange] = []
    private var lastSeq: Int = 0
    private let relay = SharedBuysRelay()

    var isActive: Bool { sessionKey != nil }

    var roomID: String? {
        guard let sessionKey else { return nil }
        return SharedBuysCrypto.roomID(sessionKey: sessionKey)
    }

    var items: [SharedBuyItem] { SharedBuyFold.items(from: changes) }

    var members: [Int: String] { SharedBuyFold.members(from: changes) }

    var joinURL: URL? {
        guard let sessionKey else { return nil }
        var components = URLComponents()
        components.scheme = "circles-app"
        components.host = Self.joinHost
        components.queryItems = [
            URLQueryItem(name: "v", value: "1"),
            URLQueryItem(name: "e", value: String(eventNumber)),
            URLQueryItem(name: "k", value: sessionKey.base64URL)
        ]
        return components.url
    }

    var versionVector: [String: Int] {
        changes.reduce(into: [String: Int]()) { result, change in
            result[change.device] = max(result[change.device] ?? 0, change.seq)
        }
    }

    func restore() {
        guard let snapshot = SharedBuysStore.load() else { return }
        sessionKey = snapshot.sessionKey
        deviceID = snapshot.deviceID
        eventNumber = snapshot.eventNumber
        lastSeq = snapshot.lastSeq
        changes = snapshot.changes
    }

    func start(eventNumber: Int, nickname: String) {
        sessionKey = SharedBuysCrypto.newSessionKey()
        deviceID = SharedBuysCrypto.newDeviceID()
        self.eventNumber = eventNumber
        lastSeq = 0
        changes = []
        persist()
        append(.memberJoined, itemID: "-", circleID: 0, text: nickname, value: actorPID)
        note("started room \(roomID ?? "?") as \(deviceID)")
        connect()
    }

    func join(url: URL, nickname: String) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let raw = components.queryItems?.first(where: { $0.name == "k" })?.value,
              let key = Data(base64URL: raw), key.count == 32 else {
            note("bad join link")
            return
        }
        let event = Int(components.queryItems?.first(where: { $0.name == "e" })?.value ?? "") ?? 0
        sessionKey = key
        deviceID = SharedBuysCrypto.newDeviceID()
        eventNumber = event
        lastSeq = 0
        changes = []
        persist()
        append(.memberJoined, itemID: "-", circleID: 0, text: nickname, value: actorPID)
        note("joined room \(roomID ?? "?") as \(deviceID)")
        connect()
    }

    func leave() {
        Task { await relay.disconnect() }
        sessionKey = nil
        changes = []
        lastSeq = 0
        status = .idle
        SharedBuysStore.clear()
        note("left session")
    }

    func connect() {
        guard let sessionKey, let roomID else { return }
        status = .connecting
        let base = relayBaseURL
        let device = deviceID
        let vector = versionVector
        Task {
            await relay.connect(
                SharedBuysRelay.Endpoint(
                    baseURL: base,
                    roomID: roomID,
                    deviceID: device,
                    sessionKey: sessionKey,
                    vector: vector
                )
            ) { event in
                Task { @MainActor in self.handle(event) }
            }
        }
    }

    func addItem(name: String, cost: Int, circleID: Int) {
        let itemID = String(UUID().uuidString.prefix(8)).lowercased()
        append(.addItem, itemID: itemID, circleID: circleID, text: name, value: cost)
        append(.setAssignee, itemID: itemID, circleID: circleID, value: actorPID)
    }

    func cycle(_ item: SharedBuyItem) {
        append(.setStatus, itemID: item.id, circleID: item.circleID, value: item.status.next.rawValue)
    }

    func assign(_ item: SharedBuyItem, to pid: Int?) {
        append(.setAssignee, itemID: item.id, circleID: item.circleID, value: pid)
    }

    private func append(_ kind: SharedBuyKind, itemID: String, circleID: Int, text: String? = nil, value: Int? = nil) {
        guard let sessionKey, let roomID else { return }
        lastSeq += 1
        let change = SharedBuyChange(
            device: deviceID,
            seq: lastSeq,
            payload: SharedBuyPayload(
                actor: actorPID,
                kind: kind,
                itemID: itemID,
                circleID: circleID,
                text: text,
                value: value
            )
        )
        changes.append(change)
        persist()
        guard let record = seal(change, sessionKey: sessionKey, roomID: roomID) else { return }
        Task { await relay.send(records: [record]) }
    }

    private func seal(_ change: SharedBuyChange, sessionKey: Data, roomID: String) -> RelayRecord? {
        guard let plaintext = try? JSONEncoder().encode(change.payload) else { return nil }
        let contentKey = SharedBuysCrypto.derive(SharedBuysCrypto.opsInfo, from: sessionKey)
        let relayAuthKey = SharedBuysCrypto.derive(SharedBuysCrypto.relayAuthInfo, from: sessionKey)
        guard let blob = try? SharedBuysCrypto.seal(
            plaintext,
            contentKey: contentKey,
            roomID: roomID,
            deviceID: change.device,
            seq: change.seq
        ) else { return nil }
        let tag = SharedBuysCrypto.recordTag(
            deviceID: change.device,
            seq: change.seq,
            blob: blob,
            relayAuthKey: relayAuthKey
        )
        return RelayRecord(
            device: change.device,
            seq: change.seq,
            blob: blob.base64URL,
            tag: tag.base64URL
        )
    }

    private func handle(_ event: RelayEvent) {
        switch event {
        case .connected:
            status = .connected
            note("connected")
            resend()
        case .records(let records):
            ingest(records)
        case .failed(let reason):
            status = .offline(reason)
            note("failed: \(reason)")
        case .closed(let code):
            status = .offline("closed \(code)")
            note("closed \(code)")
        }
    }

    private func resend() {
        guard let sessionKey, let roomID else { return }
        let mine = changes.filter { $0.device == deviceID }
        let records = mine.compactMap { seal($0, sessionKey: sessionKey, roomID: roomID) }
        guard !records.isEmpty else { return }
        Task { await relay.send(records: Array(records.prefix(32))) }
    }

    private func ingest(_ records: [RelayRecord]) {
        guard let sessionKey, let roomID else { return }
        let contentKey = SharedBuysCrypto.derive(SharedBuysCrypto.opsInfo, from: sessionKey)
        let known = Set(changes.map(\.id))
        var added = 0
        for record in records {
            let identifier = "\(record.device)#\(record.seq)"
            guard !known.contains(identifier), let blob = Data(base64URL: record.blob) else { continue }
            guard let plaintext = try? SharedBuysCrypto.open(
                blob,
                contentKey: contentKey,
                roomID: roomID,
                deviceID: record.device,
                seq: record.seq
            ), let payload = try? JSONDecoder().decode(SharedBuyPayload.self, from: plaintext) else {
                note("could not open \(identifier)")
                continue
            }
            changes.append(SharedBuyChange(device: record.device, seq: record.seq, payload: payload))
            added += 1
        }
        if added > 0 {
            persist()
            note("received \(added)")
        }
    }

    private func persist() {
        guard let sessionKey else { return }
        SharedBuysStore.save(
            SharedBuysSnapshot(
                sessionKey: sessionKey,
                deviceID: deviceID,
                eventNumber: eventNumber,
                lastSeq: lastSeq,
                changes: changes
            )
        )
    }

    private func note(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 40 { log.removeLast() }
    }
}
