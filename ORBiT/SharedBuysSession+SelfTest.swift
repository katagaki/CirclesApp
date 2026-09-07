//
//  SharedBuysSession+SelfTest.swift
//  CiRCLES
//

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

        if let sessionKey {
            let tag = SharedBuysProfile.sessionTag(sessionKey: sessionKey)
                .map { String(format: "%02x", $0) }.joined()
            note("ble tag \(tag) window \(SharedBuysProfile.window(at: .now))")

            let handshake = SharedBuysProfile.handshake(sessionKey: sessionKey)
            let accepted = SharedBuysProfile.accepts(handshake: handshake, sessionKey: sessionKey)
            let stranger = Data(repeating: 0x5a, count: sessionKey.count)
            let rejected = !SharedBuysProfile.accepts(handshake: handshake, sessionKey: stranger)
            let notConfused = frames.first.map { SharedBuysProfile.handshakeTag(in: $0) == nil } ?? false
            note(
                "handshake \(handshake.count)B " +
                "accept \(accepted ? "ok" : "FAILED") " +
                "reject \(rejected ? "ok" : "FAILED") " +
                "framing \(notConfused ? "ok" : "FAILED")"
            )
        }
    }

}
