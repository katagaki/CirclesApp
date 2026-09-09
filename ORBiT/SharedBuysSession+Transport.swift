//
//  SharedBuysSession+Transport.swift
//  CiRCLES
//

import Foundation

/// The two ways a change leaves this device: the relay, and a peer over Bluetooth.
///
/// Both paths carry the same sealed records, so they are kept together and away from the
/// session's own bookkeeping.
@MainActor
public extension SharedBuysSession {

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

    /// Uploads every change this device authored, in frames the relay will accept.
    ///
    /// Taking the first 32 and discarding the rest left later changes with no path to
    /// the server at all: `resend()` only runs on connect, and always re-took the same
    /// 32. Each page is sealed as it is sent, so a long backlog no longer pays the whole
    /// seal cost — encode, two derivations and AES-GCM per change — before transmitting
    /// any of it.
    internal func resend() {
        guard let sessionKey, let roomID else { return }
        let mine = changes.filter { $0.device == deviceID }
        guard !mine.isEmpty else { return }
        Task {
            for start in stride(from: 0, to: mine.count, by: Self.recordsPerFrame) {
                let page = mine[start..<min(start + Self.recordsPerFrame, mine.count)]
                let records = page.compactMap {
                    self.seal($0, sessionKey: sessionKey, roomID: roomID)
                }
                guard !records.isEmpty else { continue }
                await self.relay.send(records: records)
            }
        }
    }

    // MARK: Bluetooth

    /// The version vector covering only what Bluetooth carries.
    ///
    /// The full vector counts relay-only changes, so advertising it to a peer would
    /// claim we hold status flips whose sequence numbers sit below a name or cost we
    /// happened to receive over the relay. The peer would then filter those flips out
    /// of its reply and they would never arrive. The peer-to-peer path has to reason
    /// about its own subset of the log.
    var bluetoothVersionVector: [String: Int] {
        Self.contiguousPrefix(of: changes.filter { $0.payload.kind?.travelsOverBluetooth == true })
    }

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

    func startBluetooth() {
        guard isBluetoothEnabled, let sessionKey else { return }
        bluetooth.start(sessionKey: sessionKey, digest: SharedBuysDigest.data(of: bluetoothDigestVector)) { event in
            switch event {
            case .peerCount(let count):
                self.bluetoothPeers = count
                self.note("bluetooth peers \(count)")
            case .peerVerified(let digest):
                self.handshakeCompleted(peerDigest: digest)
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

    /// A peer that advertised our own digest holds the same Bluetooth-eligible log, so
    /// there is nothing for a version vector exchange to turn up.
    internal func handshakeCompleted(peerDigest: Data?) {
        guard peerDigest != SharedBuysDigest.data(of: bluetoothDigestVector) else {
            note("peer is level, skipping want")
            return
        }
        sendWant()
    }

    internal func sendWant() {
        for frame in SharedBuysWire.wantFrames(bluetoothVersionVector) {
            bluetooth.send(frame)
        }
    }

    internal func handleBluetooth(_ payload: Data) {
        guard let frame = SharedBuysWire.decode(payload) else { return }
        switch frame {
        case .want(let theirs):
            let missing = changes.filter {
                $0.payload.kind?.travelsOverBluetooth == true && $0.seq > (theirs[$0.device] ?? 0)
            }
            sendOverBluetooth(missing)
        case .changes(let records):
            ingest(records)
        }
    }

    internal func sendOverBluetooth(_ outgoing: [SharedBuyChange]) {
        let eligible = outgoing.filter { $0.payload.kind?.travelsOverBluetooth == true }
        guard !eligible.isEmpty, bluetoothPeers > 0, let sessionKey, let roomID else { return }
        let records = eligible.compactMap { seal($0, sessionKey: sessionKey, roomID: roomID) }
        guard !records.isEmpty else { return }
        for frame in SharedBuysWire.changeFrames(records) {
            bluetooth.send(frame)
        }
    }
}
