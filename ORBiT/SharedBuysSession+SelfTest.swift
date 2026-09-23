import CryptoKit
import Foundation

public extension SharedBuysSession {

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

        checkWire()

        if let sessionKey {
            let tag = SharedBuysProfile.sessionTag(sessionKey: sessionKey)
                .map { String(format: "%02x", $0) }.joined()
            note("ble tag \(tag) window \(SharedBuysProfile.window(at: .now))")
        }

        let notConfused = frames.first.map { SharedBuysHandshake.parse($0) == nil } ?? false
        checkHandshake(notConfused: notConfused)
    }

    /// Runs the handshake test vector both platforms share, and a stranger against it.
    private func checkHandshake(notConfused: Bool) {
        let key = SharedBuysHandshake.key(sessionKey: Data((0..<32).map { UInt8($0) }))
        let challenge = Data((1...8).map { UInt8($0) })
        let nonce = Data((0x11...0x18).map { UInt8($0) })
        let response = SharedBuysHandshake.response(challenge: challenge, nonce: nonce, key: key)
        let confirm = SharedBuysHandshake.confirm(challenge: challenge, response: nonce, key: key)
        let hex = { (data: Data) in data.map { String(format: "%02x", $0) }.joined() }
        let vector = hex(response) == "04111213141516171812f9003d9145f14c"
            && hex(confirm) == "05cff3acad54e390af"
        let stranger = SharedBuysHandshake.key(sessionKey: Data(repeating: 0x5a, count: 32))
        var verified = false
        if case .response(let parsedNonce, let mac) = SharedBuysHandshake.parse(response) {
            verified = SharedBuysHandshake.verifiesResponse(mac, challenge: challenge, response: parsedNonce, key: key)
                && !SharedBuysHandshake.verifiesResponse(
                    mac, challenge: challenge, response: parsedNonce, key: stranger
                )
        }
        note(
            "handshake vector \(vector ? "ok" : "FAILED") " +
            "verify \(verified ? "ok" : "FAILED") " +
            "framing \(notConfused ? "ok" : "FAILED")"
        )
    }

    /// Encodes the note's test vector from scratch and parses it back.
    ///
    /// This walks the whole construction — HKDF, AES-256-GCM, the record tag and the
    /// frame layout — so a change on either platform that moves a byte shows up here
    /// rather than as a peer that silently cannot open anything.
    private func checkWire() {
        let key = Data((0..<32).map { UInt8($0) })
        let room = SharedBuysCrypto.roomID(sessionKey: key)
        let contentKey = SharedBuysCrypto.derive(SharedBuysCrypto.opsInfo, from: key)
        let relayAuthKey = SharedBuysCrypto.derive(SharedBuysCrypto.relayAuthInfo, from: key)
        let plaintext = Data(#"{"a":12345,"k":1,"i":"a1b2c3d4","c":98765,"v":1}"#.utf8)
        guard let blob = try? SharedBuysCrypto.seal(
            plaintext,
            contentKey: contentKey,
            roomID: room,
            deviceID: "a1b2c3d4",
            seq: 42,
            nonce: Data(repeating: 0x11, count: SharedBuysCrypto.nonceLength)
        ) else {
            note("wire vector FAILED to seal")
            return
        }
        let recordTag = SharedBuysCrypto.recordTag(
            deviceID: "a1b2c3d4",
            seq: 42,
            blob: blob,
            relayAuthKey: relayAuthKey
        )
        let record = RelayRecord(
            device: "a1b2c3d4",
            seq: 42,
            blob: blob.base64URL,
            tag: recordTag.base64URL
        )
        guard let frame = SharedBuysWire.changeFrames([record]).first else {
            note("wire vector FAILED to encode")
            return
        }
        let marked = blob.starts(with: SharedBuysCrypto.randomNonceMarker)
        let opened = try? SharedBuysCrypto.open(
            blob,
            contentKey: contentKey,
            roomID: room,
            deviceID: "a1b2c3d4",
            seq: 42
        )
        note("wire \(frame.count)B nonce \(marked ? "ok" : "FAILED") crypto \(opened == plaintext ? "ok" : "FAILED")")

        var rebuilt = "FAILED"
        if case .changes(let records) = SharedBuysWire.decode(frame), let first = records.first {
            rebuilt = first.device == record.device && first.seq == record.seq
                && first.blob == record.blob && first.tag == record.tag ? "ok" : "FAILED"
        }
        let vector = ["a1b2c3d4": 42, "cafebabe": 260]
        var want = "FAILED"
        if let wantFrame = SharedBuysWire.wantFrames(vector).first,
           case .want(let theirs) = SharedBuysWire.decode(wantFrame) {
            want = theirs == vector ? "ok" : "FAILED"
        }
        note("wire round trip changes \(rebuilt) want \(want)")

        // A blobLen larger than what is left must be refused, not sliced.
        let truncated = frame.prefix(frame.count - 1)
        let overrun = SharedBuysWire.decode(Data(truncated)) == nil
        var wrongVersion = Data([0x7F])
        wrongVersion.append(frame.dropFirst())
        let skipped = SharedBuysWire.decode(wrongVersion) == nil
        note("wire bounds \(overrun ? "ok" : "FAILED") version \(skipped ? "ok" : "FAILED")")
    }

}
