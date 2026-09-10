import CryptoKit
import Foundation

@MainActor
public extension SharedBuysSession {

    /// Opens incoming records away from the actor that received them.
    ///
    /// Opening is pure work over the batch — two key derivations and a GCM open per
    /// record — so it runs off the main actor and only the append comes back.
    internal func ingest(_ records: [RelayRecord]) {
        guard let sessionKey, let roomID else { return }
        let known = Set(changes.map(\.id))
        let fresh = records.filter { !known.contains("\($0.device)#\($0.seq)") }
        guard !fresh.isEmpty else { return }
        Task.detached(priority: .userInitiated) {
            let opened = fresh.compactMap {
                Self.open($0, sessionKey: sessionKey, roomID: roomID)
            }
            let rejected = fresh.count - opened.count
            await MainActor.run { self.adopt(opened, rejected: rejected) }
        }
    }

    /// Verifies and decrypts one record. Pure, so it is safe anywhere.
    internal nonisolated static func open(
        _ record: RelayRecord,
        sessionKey: Data,
        roomID: String
    ) -> SharedBuyChange? {
        guard let blob = Data(base64URL: record.blob) else { return nil }
        let relayAuthKey = SharedBuysCrypto.derive(SharedBuysCrypto.relayAuthInfo, from: sessionKey)
        // Whoever handed us this record — the relay, or a peer over Bluetooth — is not
        // trusted to have authored it. Check the tag before it enters the log.
        guard let offered = Data(base64URL: record.tag),
              offered == SharedBuysCrypto.recordTag(
                  deviceID: record.device,
                  seq: record.seq,
                  blob: blob,
                  relayAuthKey: relayAuthKey
              ) else { return nil }
        let contentKey = SharedBuysCrypto.derive(SharedBuysCrypto.opsInfo, from: sessionKey)
        guard let plaintext = try? SharedBuysCrypto.open(
            blob,
            contentKey: contentKey,
            roomID: roomID,
            deviceID: record.device,
            seq: record.seq
        ), let payload = try? JSONDecoder().decode(SharedBuyPayload.self, from: plaintext) else {
            return nil
        }
        return SharedBuyChange(device: record.device, seq: record.seq, payload: payload)
    }

    /// Appends what was opened, re-checking against a log that may have moved meanwhile.
    internal func adopt(_ opened: [SharedBuyChange], rejected: Int) {
        var known = Set(changes.map(\.id))
        var added = 0
        for change in opened {
            // A batch can carry the same record twice — a relay echo, or a `want` reply
            // overlapping the live stream — so the set has to grow as we append.
            guard known.insert(change.id).inserted else { continue }
            changes.append(change)
            // A Lamport clock. Without it a fresh device's seq 1 sorts under an
            // established peer's seq 30, and the older edit wins on every screen.
            lastSeq = max(lastSeq, change.seq)
            added += 1
        }
        if rejected > 0 { note("dropped \(rejected) unopenable") }
        if added > 0 {
            persist()
            bluetooth.update(digest: SharedBuysDigest.data(of: bluetoothDigestVector))
            updateActivity()
            note("received \(added)")
        }
    }
}
