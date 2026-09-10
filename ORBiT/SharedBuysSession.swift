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

    public init() {
        // Read before the first view is built: the app root picks the guest shell from
        // this, and restore() -- which would set it -- does not run until onAppear.
        isGuest = UserDefaults.standard.bool(forKey: Self.guestModeKey)
    }

    public static let joinHost = "buys-join"

    static let guestModeKey = "Guest.IsActive"
    static let guestNicknameKey = "Guest.Nickname"

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

    /// Whether this device is running as a guest.
    ///
    /// A guest has no circle.ms account and no catalog database: they scanned a room
    /// code to help tick things off, and that is all they can do. `append` honours this
    /// by dropping every kind but a status flip. It is not enforceable — a guest holds
    /// the room key, so a modified client could write anything the relay accepts — it
    /// is this app keeping to the role it advertised.
    public var isGuest: Bool = false

    public private(set) var sessionKey: Data?
    public private(set) var deviceID: String = ""
    public private(set) var eventNumber: Int = 0
    public internal(set) var changes: [SharedBuyChange] = [] {
        didSet { foldCache = nil }
    }

    @ObservationIgnored private var foldCache: (
        items: [SharedBuyItem],
        members: [Int: String],
        circles: [Int: SharedBuyCircle]
    )?
    var lastSeq: Int = 0
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

    public var items: [SharedBuyItem] { fold().items }

    public var members: [Int: String] { fold().members }

    /// Circle name and space as the log carries them, for a member with no catalog.
    public var relayedCircles: [Int: SharedBuyCircle] { fold().circles }

    private func fold() -> (
        items: [SharedBuyItem],
        members: [Int: String],
        circles: [Int: SharedBuyCircle]
    ) {
        if let foldCache { return foldCache }
        let folded = (
            items: SharedBuyFold.items(from: changes),
            members: SharedBuyFold.members(from: changes),
            circles: SharedBuyFold.circles(from: changes)
        )
        foldCache = folded
        return folded
    }

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
        // Joining a second room is leaving the first. Without this the previous room's
        // Live Activity survived — `startActivity()` bails while one exists — and went on
        // showing the new room's items under the old room's identity.
        if isActive { leave() }
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

    /// Enters Guest Mode. Survives relaunch, so the app comes back into the guest shell
    /// rather than the login screen.
    public func enterGuestMode() {
        UserDefaults.standard.set(true, forKey: Self.guestModeKey)
        adoptIdentity()
    }

    /// Leaves Guest Mode and the room with it.
    ///
    /// The minted name is dropped too: coming back as a guest later is a new session
    /// with a new member, not a resumption of the old one.
    public func exitGuestMode() {
        leave()
        UserDefaults.standard.removeObject(forKey: Self.guestModeKey)
        UserDefaults.standard.removeObject(forKey: Self.guestNicknameKey)
        isGuest = false
        nickname = ""
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

    /// Adds an item, carrying the circle's identity into the log the first time that
    /// circle appears in the room.
    ///
    /// `circleName` and `circleSpace` come from the caller's catalog database, which a
    /// guest does not have. Relayed once per circle rather than per item: the check is
    /// against the folded circle map, so it is idempotent across a restore and a
    /// second contributor adding from a circle someone else already introduced.
    @discardableResult
    public func addItem(
        name: String,
        cost: Int,
        circleID: Int,
        circleName: String? = nil,
        circleSpace: String? = nil
    ) -> String {
        let itemID = String(UUID().uuidString.prefix(8)).lowercased()
        if let circleName, !circleName.isEmpty, SharedBuyFold.circles(from: changes)[circleID] == nil {
            append(.circleInfo, itemID: "-", circleID: circleID, text: circleName, space: circleSpace)
        }
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

    private func append(
        _ kind: SharedBuyKind,
        itemID: String,
        circleID: Int,
        text: String? = nil,
        value: Int? = nil,
        space: String? = nil
    ) {
        guard let sessionKey, let roomID else { return }
        // A guest holds the room key and could append anything the relay would accept.
        // The restriction is the app honouring its own role, not something the log can
        // enforce -- see `isGuest`. `memberJoined` is how a guest appears in the members
        // list at all, so it is allowed alongside the status flips they are here for.
        guard !isGuest || kind == .setStatus || kind == .memberJoined else { return }
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
                value: value,
                space: space
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

    /// Snapshots the log and writes it away from the caller.
    ///
    /// Encoding every change and writing the file happened inline on whichever thread
    /// tapped an item — O(N) per change and O(N²) across a session, on the main thread.
    /// The snapshot is taken here, where the state is consistent; the encode and the
    /// write happen on the store's own serial executor.
    func persist() {
        guard let sessionKey else { return }
        let snapshot = SharedBuysSnapshot(
            sessionKey: sessionKey,
            deviceID: deviceID,
            eventNumber: eventNumber,
            lastSeq: lastSeq,
            changes: changes
        )
        Task.detached(priority: .utility) { await SharedBuysStore.writer.save(snapshot) }
    }

    public func note(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 40 { log.removeLast() }
    }
}
