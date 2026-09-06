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
    var nickname: String = ""

    private(set) var sessionKey: Data?
    private(set) var deviceID: String = ""
    private(set) var eventNumber: Int = 0
    private(set) var changes: [SharedBuyChange] = []
    private var lastSeq: Int = 0
    private var reconnectAttempt: Int = 0
    private var reconnectTask: Task<Void, Never>?
    var activity: Any?
    private let relay = SharedBuysRelay()
    private let bluetooth = SharedBuysBluetooth()

    var bluetoothPeers: Int = 0
    var bluetoothNote: String = ""
    var isBluetoothEnabled: Bool = true

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
        adoptIdentity()
        guard let snapshot = SharedBuysStore.load() else { return }
        sessionKey = snapshot.sessionKey
        deviceID = snapshot.deviceID
        eventNumber = snapshot.eventNumber
        lastSeq = snapshot.lastSeq
        changes = snapshot.changes
        note("restored room \(roomID ?? "?") as \(deviceID)")
        adoptActivity()
        connect()
        startBluetooth()
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
        startBluetooth()
        startActivity()
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
        startBluetooth()
        startActivity()
    }

    func leave() {
        endActivity()
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempt = 0
        bluetooth.stop()
        bluetoothPeers = 0
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
        reconnectTask?.cancel()
        reconnectTask = nil
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

    func runSelfTest() {
        let vector = ["aaaaaaaa": 3, "bbbbbbbb": 1, "cafebabe": 260]
        let digest = SharedBuysDigest.data(of: vector).map { String(format: "%02x", $0) }.joined()
        note("digest \(digest)")

        let payload = Data((0..<500).map { UInt8($0 % 251) })
        let frames = SharedBuysFraming.chunks(of: payload, messageID: 7)
        var reassembler = SharedBuysFraming.Reassembler()
        var rebuilt: Data?
        for frame in frames.shuffled() {
            if let result = reassembler.accept(frame) { rebuilt = result }
        }
        note("framing \(frames.count) chunks, round trip \(rebuilt == payload ? "ok" : "FAILED")")

        if let sessionKey {
            let tag = SharedBuysProfile.sessionTag(sessionKey: sessionKey)
                .map { String(format: "%02x", $0) }.joined()
            note("ble tag \(tag) window \(SharedBuysProfile.window(at: .now))")
        }
    }

    func startBluetooth() {
        guard isBluetoothEnabled, let sessionKey else { return }
        bluetooth.start(sessionKey: sessionKey, digest: SharedBuysDigest.data(of: versionVector)) { event in
            switch event {
            case .peerCount(let count):
                self.bluetoothPeers = count
                self.note("bluetooth peers \(count)")
                if count > 0 { self.sendWant() }
            case .payload(let payload):
                self.handleBluetooth(payload)
            case .unavailable(let reason):
                self.bluetoothNote = reason
                self.note("bluetooth: \(reason)")
            }
        }
    }

    func stopBluetooth() {
        bluetooth.stop()
        bluetoothPeers = 0
    }

    private func sendWant() {
        let frame: [String: Any] = ["t": "want", "v": versionVector]
        guard let data = try? JSONSerialization.data(withJSONObject: frame) else { return }
        bluetooth.send(data)
    }

    private func handleBluetooth(_ payload: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] else { return }
        switch object["t"] as? String {
        case "want":
            let theirs = object["v"] as? [String: Int] ?? [:]
            let missing = changes.filter { $0.seq > (theirs[$0.device] ?? 0) }
            sendOverBluetooth(missing)
        case "ops":
            let raw = object["o"] as? [[String: Any]] ?? []
            let records: [RelayRecord] = raw.compactMap { entry in
                guard let device = entry["d"] as? String,
                      let seq = entry["n"] as? Int,
                      let blob = entry["b"] as? String,
                      let tag = entry["a"] as? String else { return nil }
                return RelayRecord(device: device, seq: seq, blob: blob, tag: tag)
            }
            ingest(records)
        default:
            break
        }
    }

    private func sendOverBluetooth(_ outgoing: [SharedBuyChange]) {
        guard !outgoing.isEmpty, bluetoothPeers > 0, let sessionKey, let roomID else { return }
        let records = outgoing.compactMap { seal($0, sessionKey: sessionKey, roomID: roomID) }
        guard !records.isEmpty else { return }
        let frame: [String: Any] = ["t": "ops", "o": records.map {
            ["d": $0.device, "n": $0.seq, "b": $0.blob, "a": $0.tag]
        }]
        guard let data = try? JSONSerialization.data(withJSONObject: frame) else { return }
        bluetooth.send(data)
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
        sendOverBluetooth([change])
        bluetooth.update(digest: SharedBuysDigest.data(of: versionVector))
        updateActivity()
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
            reconnectAttempt = 0
            note("connected")
            resend()
        case .records(let records):
            ingest(records)
        case .failed(let reason):
            status = .offline(reason)
            note("failed: \(reason)")
            scheduleReconnect()
        case .closed(let code):
            status = .offline("closed \(code)")
            note("closed \(code)")
            scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        guard isActive, reconnectTask == nil else { return }
        guard bluetoothPeers == 0 else {
            note("holding off, bluetooth is carrying")
            return
        }
        reconnectAttempt = min(reconnectAttempt + 1, 6)
        let backoff = min(pow(2.0, Double(reconnectAttempt)), 30.0)
        let delay = backoff + Double.random(in: 0...1)
        note("reconnect in \(String(format: "%.1f", delay))s")
        reconnectTask = Task { [delay] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self.reconnectTask = nil
            if self.isActive, self.bluetoothPeers == 0 { self.connect() }
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
            bluetooth.update(digest: SharedBuysDigest.data(of: versionVector))
            updateActivity()
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

    func note(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 40 { log.removeLast() }
    }
}
