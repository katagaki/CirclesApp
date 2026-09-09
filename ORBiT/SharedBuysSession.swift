//
//  SharedBuysSession.swift
//  CiRCLES
//

import CryptoKit
import Foundation
import Observation

public enum SharedBuysStatus: Equatable {
    case idle
    case connecting
    case connected
    case offline(String)
}

@Observable
@MainActor
public final class SharedBuysSession {

    public init() {}

    public static let joinHost = "buys-join"

    /// The relay refuses a frame carrying more than this (`MAX_RECORDS_PER_FRAME`).
    public static let recordsPerFrame = 32

    /// How long an outbound record waits for company before it is sent.
    ///
    /// The relay's bucket is 20 messages per 10 seconds and `addItem` alone emits two
    /// changes, so a frame per change put ten quick adds over the limit and earned a
    /// rate-limit close. A quarter second is under the threshold of feeling laggy and
    /// collapses a burst of typing into one frame.
    public static let coalesceWindow: Duration = .milliseconds(250)

    public var status: SharedBuysStatus = .idle
    public var log: [String] = []
    public var relayBaseURL: String = "ws://127.0.0.1:8787"
    public var actorPID: Int = 0
    public var nickname: String = ""

    public private(set) var sessionKey: Data?
    public private(set) var deviceID: String = ""
    public private(set) var eventNumber: Int = 0
    public private(set) var changes: [SharedBuyChange] = []
    private var lastSeq: Int = 0
    private var reconnectAttempt: Int = 0
    private var reconnectTask: Task<Void, Never>?
    var outbox: [RelayRecord] = []
    var flushTask: Task<Void, Never>?
    public var activity: Any?
    let relay = SharedBuysRelay()
    let bluetooth = SharedBuysBluetooth()

    public var bluetoothPeers: Int = 0
    public var bluetoothNote: String = ""
    public var isBluetoothEnabled: Bool = true

    public var isActive: Bool { sessionKey != nil }

    public var roomID: String? {
        guard let sessionKey else { return nil }
        return SharedBuysCrypto.roomID(sessionKey: sessionKey)
    }

    public var items: [SharedBuyItem] { SharedBuyFold.items(from: changes) }

    public var members: [Int: String] { SharedBuyFold.members(from: changes) }

    public var joinURL: URL? {
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

    /// What we hold with no gap in it, per device.
    ///
    /// A vector of `max(seq)` claims everything below the highest sequence number we
    /// have seen, so a change learned out of order — over Bluetooth, or from a peer's
    /// backlog — buries whatever is still missing underneath it, and the relay withholds
    /// the gap forever. The contiguous prefix claims only what is actually complete;
    /// anything above a hole is sent again and deduped on ingest.
    public var versionVector: [String: Int] {
        Self.contiguousPrefix(of: changes)
    }

    /// The highest `n` for which every sequence number from 1 to `n` is present. A
    /// device we hold nothing contiguous for is left out rather than claimed at 0.
    static func contiguousPrefix(of changes: [SharedBuyChange]) -> [String: Int] {
        var held: [String: Set<Int>] = [:]
        for change in changes { held[change.device, default: []].insert(change.seq) }
        return held.compactMapValues { seqs in
            var next = 1
            while seqs.contains(next) { next += 1 }
            return next > 1 ? next - 1 : nil
        }
    }

    public func restore() {
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

    public func start(eventNumber: Int, nickname: String) {
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

    public func join(url: URL, nickname: String) {
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

    public func leave() {
        endActivity()
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempt = 0
        flushTask?.cancel()
        flushTask = nil
        outbox = []
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

    public func connect() {
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
            ) { [weak self] event in
                Task { @MainActor in self?.handle(event) }
            }
        }
    }

    @discardableResult
    public func addItem(name: String, cost: Int, circleID: Int) -> String {
        let itemID = String(UUID().uuidString.prefix(8)).lowercased()
        append(.addItem, itemID: itemID, circleID: circleID, text: name, value: cost)
        append(.setAssignee, itemID: itemID, circleID: circleID, value: actorPID)
        return itemID
    }

    public func rename(itemID: String, circleID: Int, to name: String) {
        append(.renameItem, itemID: itemID, circleID: circleID, text: name)
    }

    public func setCost(itemID: String, circleID: Int, to cost: Int) {
        append(.setCost, itemID: itemID, circleID: circleID, value: cost)
    }

    public func remove(itemID: String, circleID: Int) {
        append(.removeItem, itemID: itemID, circleID: circleID)
    }

    public func cycle(_ item: SharedBuyItem) {
        append(
            .setStatus,
            itemID: item.id,
            circleID: item.circleID,
            value: SharedBuyStatus.next(after: item.rawStatus).rawValue
        )
    }

    public func assign(_ item: SharedBuyItem, to pid: Int?) {
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
        enqueue(record)
        sendOverBluetooth([change])
        bluetooth.update(digest: SharedBuysDigest.data(of: bluetoothDigestVector))
        updateActivity()
    }

    func seal(_ change: SharedBuyChange, sessionKey: Data, roomID: String) -> RelayRecord? {
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

    /// Arms the reconnect, deferring it while a peer is carrying the session.
    ///
    /// Returning early when peers were present left nothing to re-arm the task: the peer
    /// count handler does not reconnect, so once the peer walked away the device stayed
    /// offline until the app was relaunched. The task is armed either way now, and
    /// re-checks the peer count when it fires.
    func scheduleReconnect() {
        guard isActive, reconnectTask == nil else { return }
        if bluetoothPeers > 0 { note("holding off, bluetooth is carrying") }
        reconnectAttempt = min(reconnectAttempt + 1, 6)
        let backoff = min(pow(2.0, Double(reconnectAttempt)), 30.0)
        let delay = backoff + Double.random(in: 0...1)
        note("reconnect in \(String(format: "%.1f", delay))s")
        reconnectTask = Task { [weak self, delay] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            self.reconnectTask = nil
            guard self.isActive else { return }
            // Still covered by a peer: come back and ask again rather than dropping the
            // only thing that would have reconnected us.
            if self.bluetoothPeers == 0 { self.connect() } else { self.scheduleReconnect() }
        }
    }

    func ingest(_ records: [RelayRecord]) {
        guard let sessionKey, let roomID else { return }
        let contentKey = SharedBuysCrypto.derive(SharedBuysCrypto.opsInfo, from: sessionKey)
        let relayAuthKey = SharedBuysCrypto.derive(SharedBuysCrypto.relayAuthInfo, from: sessionKey)
        var known = Set(changes.map(\.id))
        var added = 0
        for record in records {
            let identifier = "\(record.device)#\(record.seq)"
            guard !known.contains(identifier), let blob = Data(base64URL: record.blob) else { continue }
            // Whoever handed us this record — the relay, or a peer over Bluetooth — is
            // not trusted to have authored it. Check the tag before it enters the log.
            guard let offered = Data(base64URL: record.tag),
                  offered == SharedBuysCrypto.recordTag(
                      deviceID: record.device,
                      seq: record.seq,
                      blob: blob,
                      relayAuthKey: relayAuthKey
                  ) else {
                note("bad tag on \(identifier)")
                continue
            }
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
            // A batch can carry the same record twice — a relay echo, or a `want` reply
            // overlapping the live stream — so the set has to grow as we append.
            known.insert(identifier)
            // A Lamport clock. Without it a fresh device's seq 1 sorts under an
            // established peer's seq 30, and the older edit wins on every screen.
            lastSeq = max(lastSeq, record.seq)
            added += 1
        }
        if added > 0 {
            persist()
            bluetooth.update(digest: SharedBuysDigest.data(of: bluetoothDigestVector))
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

    public func note(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 40 { log.removeLast() }
    }
}
