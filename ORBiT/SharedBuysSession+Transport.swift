import Foundation

@MainActor
public extension SharedBuysSession {

    private static var resendPageDelay: Duration { .milliseconds(600) }

    var isActive: Bool { sessionKey != nil }

    var roomID: String? {
        guard let sessionKey else { return nil }
        return SharedBuysCrypto.roomID(sessionKey: sessionKey)
    }

    func applyPushToken(_ token: Data, environment: String) {
        let encoded = token.map { String(format: "%02x", $0) }.joined()
        guard pushToken != encoded || pushEnvironment != environment else { return }
        pushToken = encoded
        pushEnvironment = environment
        if isActive { connect() }
    }

    // MARK: Relay

    /// Holds a record briefly so a burst of edits leaves as one frame.
    internal func enqueue(_ record: RelayRecord) {
        outbox.append(record)
        guard outbox.count < Self.recordsPerFrame else {
            flushOutbox()
            return
        }
        guard flushTask == nil else { return }
        flushTask = Task {
            try? await Task.sleep(for: Self.coalesceWindow)
            guard !Task.isCancelled else { return }
            self.flushTask = nil
            self.flushOutbox()
        }
    }

    internal func flushOutbox() {
        flushTask?.cancel()
        flushTask = nil
        guard !outbox.isEmpty else { return }
        let records = outbox
        outbox = []
        Task { await relay.send(records: records) }
    }

    /// Uploads the changes this device authored that the relay does not hold yet.
    ///
    /// `seq` is the gapless prefix the relay reported after hello. Re-sending the whole
    /// history on every reconnect re-sealed and re-uploaded changes the relay only threw
    /// away as duplicates. Each page is sealed as it is sent, in frames the relay will
    /// accept.
    internal func resend(above seq: Int) {
        guard let sessionKey, let roomID else { return }
        let mine = changes.filter { $0.device == deviceID && $0.seq > seq }
        guard !mine.isEmpty else { return }
        Task {
            for start in stride(from: 0, to: mine.count, by: Self.recordsPerFrame) {
                let page = mine[start..<min(start + Self.recordsPerFrame, mine.count)]
                let records = page.compactMap {
                    self.seal($0, sessionKey: sessionKey, roomID: roomID)
                }
                guard !records.isEmpty else { continue }
                await self.relay.send(records: records)
                if start + Self.recordsPerFrame < mine.count {
                    try? await Task.sleep(for: Self.resendPageDelay)
                }
            }
        }
    }

    // MARK: Bluetooth

    /// What the advertised digest summarises: everything held over Bluetooth, gaps and
    /// all.
    ///
    /// The digest answers "is there anything to exchange at all", so it has to count a
    /// change sitting above a hole. The vector we send answers "what may you skip", and
    /// must not.
    internal var bluetoothDigestVector: [String: Int] {
        changes.reduce(into: [String: Int]()) { result, change in
            guard change.payload.kind?.travelsOverBluetooth == true else { return }
            result[change.device] = max(result[change.device] ?? 0, change.seq)
        }
    }

    /// Settles the relay address and the feature switch.
    ///
    /// A `nil` `baseURL` — the fetch failed, or the record carries no address — keeps
    /// whatever `relayBaseURL` already holds rather than blocking the feature: offline
    /// and local development both land here.
    public func applyRelayConfig(baseURL: String?, isFeatureEnabled: Bool) {
        self.isFeatureEnabled = isFeatureEnabled
        if let baseURL, !baseURL.isEmpty {
            relayBaseURL = Self.webSocketScheme(baseURL)
        }
        isRelayConfigured = true
        if !isFeatureEnabled {
            // The switch is off, so stop talking — but keep the log and the snapshot. A
            // room that comes back when the switch flips on again is worth more than the
            // few bytes reclaimed by clearing it.
            note("shared buys disabled by remote configuration")
            isConnectDeferred = false
            stopBluetooth()
            serializeRelay { [relay] in await relay.disconnect() }
            status = .idle
            return
        }
        if isConnectDeferred {
            isConnectDeferred = false
            connect()
        }
    }

    /// Rewrites an http(s) address to its WebSocket equivalent.
    ///
    /// The published address is written as a URL that can be pasted into a browser, and
    /// `URLSessionWebSocketTask` wants ws/wss. Anything already ws/wss, and anything
    /// unrecognised, is left exactly as it was given.
    static func webSocketScheme(_ baseURL: String) -> String {
        var rewritten = baseURL
        if rewritten.hasPrefix("https://") {
            rewritten = "wss://" + rewritten.dropFirst("https://".count)
        } else if rewritten.hasPrefix("http://") {
            rewritten = "ws://" + rewritten.dropFirst("http://".count)
        }
        while rewritten.hasSuffix("/") { rewritten.removeLast() }
        return rewritten
    }

    func startBluetooth() {
        guard isBluetoothEnabled, let sessionKey else { return }
        bluetooth.start(
            sessionKey: sessionKey,
            digest: SharedBuysDigest.data(of: bluetoothDigestVector)
        ) { [weak self] event in
            guard let self else { return }
            switch event {
            case .peerCount(let count):
                self.bluetoothPeers = count
                self.note("bluetooth peers \(count)")
            case .peerVerified(let peer, let digest):
                self.handshakeCompleted(with: peer, digest: digest)
            case .peerLost(let peer):
                self.wantedPeers.remove(peer)
            case .payload(let payload, let peer):
                self.handleBluetooth(payload, from: peer)
            case .unavailable(let reason):
                self.bluetoothNote = reason
                self.note("bluetooth: \(reason)")
            }
        }
    }

    func stopBluetooth() {
        bluetooth.stop()
        bluetoothPeers = 0
        wantedPeers.removeAll()
    }

    /// Opens the exchange on a link we connected, unless the peer is already level.
    ///
    /// Only the connecting side asks first. Both sides asking on every link, and the
    /// accepting side never knowing the peer's digest, meant four wants per pair of
    /// phones, each answered to everyone in range. The accepting side asks back from
    /// `handleBluetooth` instead, once, and only when the two logs differ.
    internal func handshakeCompleted(with peer: BluetoothPeer, digest: Data?) {
        guard case .peripheral = peer else { return }
        guard digest != SharedBuysDigest.data(of: bluetoothDigestVector) else {
            note("peer is level, skipping want")
            return
        }
        sendWant(to: peer)
    }

    /// Asks the peer for the status flips we lack.
    ///
    /// The vector is the gapless prefix of the whole log, not of the Bluetooth subset: a
    /// device's first change is always `memberJoined`, which never travels over
    /// Bluetooth, so the subset's prefix was empty for everyone and no want was ever
    /// sent. A prefix over the whole log is honest — holding every change up to `n`
    /// includes every status flip up to `n` — and anything above a hole comes again and
    /// is deduped on ingest.
    internal func sendWant(to peer: BluetoothPeer) {
        wantedPeers.insert(peer)
        for frame in SharedBuysWire.wantFrames(versionVector) {
            bluetooth.send(frame, to: peer)
        }
    }

    internal func handleBluetooth(_ payload: Data, from peer: BluetoothPeer) {
        guard let frame = SharedBuysWire.decode(payload) else { return }
        switch frame {
        case .want(let theirs):
            // The reply goes to whoever asked, not to every peer in range.
            let missing = changes.filter {
                $0.payload.kind?.travelsOverBluetooth == true && $0.seq > (theirs[$0.device] ?? 0)
            }
            sendOverBluetooth(missing, to: peer)
            if !wantedPeers.contains(peer), theirs != versionVector { sendWant(to: peer) }
        case .changes(let records):
            ingest(records)
        }
    }

    internal func sendOverBluetooth(_ outgoing: [SharedBuyChange], to peer: BluetoothPeer? = nil) {
        let eligible = outgoing.filter { $0.payload.kind?.travelsOverBluetooth == true }
        guard !eligible.isEmpty, bluetoothPeers > 0, let sessionKey, let roomID else { return }
        let records = eligible.compactMap { seal($0, sessionKey: sessionKey, roomID: roomID) }
        guard !records.isEmpty else { return }
        for frame in SharedBuysWire.changeFrames(records) {
            bluetooth.send(frame, to: peer)
        }
    }
}
