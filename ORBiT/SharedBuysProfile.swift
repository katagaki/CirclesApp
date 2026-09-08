//
//  SharedBuysProfile.swift
//  CiRCLES
//

import CoreBluetooth
import Foundation

enum SharedBuysProfile {

    nonisolated(unsafe) static let serviceUUID = CBUUID(string: "A7C1F2E0-5B3D-4E8A-9F16-3C2D8E4B7A90")
    nonisolated(unsafe) static let inboxUUID = CBUUID(string: "A7C1F2E1-5B3D-4E8A-9F16-3C2D8E4B7A90")
    nonisolated(unsafe) static let outboxUUID = CBUUID(string: "A7C1F2E2-5B3D-4E8A-9F16-3C2D8E4B7A90")

    static let advertisementWindow: TimeInterval = 900.0
    static let maxPayloadPerChunk = 160
    static let frameMagic: UInt8 = 0x01
    static let handshakeMagic: UInt8 = 0x02
    static let advertisementLength = 6

    static func sessionTag(sessionKey: Data, at date: Date = .now) -> Data {
        SharedBuysCrypto.rollingTag(sessionKey: sessionKey, window: window(at: date))
    }

    static func window(at date: Date) -> Int {
        Int(date.timeIntervalSince1970 / advertisementWindow)
    }

    static func handshake(sessionKey: Data, at date: Date = .now) -> Data {
        var frame = Data([handshakeMagic])
        frame.append(sessionTag(sessionKey: sessionKey, at: date))
        return frame
    }

    static func handshakeTag(in frame: Data) -> Data? {
        guard frame.count == 3, frame[frame.startIndex] == handshakeMagic else { return nil }
        return Data(frame.dropFirst())
    }

    static func accepts(handshake frame: Data, sessionKey: Data, at date: Date = .now) -> Bool {
        guard let tag = handshakeTag(in: frame) else { return false }
        return acceptedTags(sessionKey: sessionKey, at: date).contains(tag)
    }

    static func acceptedTags(sessionKey: Data, at date: Date = .now) -> [Data] {
        let current = window(at: date)
        return [current - 1, current, current + 1].map {
            SharedBuysCrypto.rollingTag(sessionKey: sessionKey, window: $0)
        }
    }

    // MARK: Advertisement

    /// The bytes a peer needs before it is worth connecting: the rolling tag that scopes
    /// the advertisement to this room, and the digest of what the sender holds.
    ///
    /// Without the tag every nearby CiRCLES user connects and then fails the handshake,
    /// which at a venue is a stream of connections that can only fail. The tag rotates
    /// with the 15 minute window, so it scopes discovery without making a device
    /// trackable across the day.
    static func advertisement(sessionKey: Data, digest: Data, at date: Date = .now) -> Data {
        var value = sessionTag(sessionKey: sessionKey, at: date)
        value.append(digest.prefix(4))
        while value.count < advertisementLength { value.append(0) }
        return value.prefix(advertisementLength)
    }

    /// iOS cannot advertise service data, so it carries the same bytes as a local name.
    static func localName(sessionKey: Data, digest: Data, at date: Date = .now) -> String {
        advertisement(sessionKey: sessionKey, digest: digest, at: date)
            .map { String(format: "%02x", $0) }.joined()
    }

    /// Reads the advertisement out of whichever field the peer's platform could use.
    static func advertisement(serviceData: Data?, localName: String?) -> Data? {
        if let serviceData, serviceData.count == advertisementLength { return serviceData }
        guard let localName, localName.count == advertisementLength * 2,
              let value = Data(hex: localName), value.count == advertisementLength
        else { return nil }
        return value
    }

    static func digest(in advertisement: Data) -> Data {
        Data(advertisement.dropFirst(2))
    }

    static func accepts(advertisement: Data, sessionKey: Data, at date: Date = .now) -> Bool {
        guard advertisement.count == advertisementLength else { return false }
        return acceptedTags(sessionKey: sessionKey, at: date).contains(Data(advertisement.prefix(2)))
    }
}

enum SharedBuysDigest {

    static func value(of vector: [String: Int]) -> UInt32 {
        var hash: UInt32 = 2166136261
        for key in vector.keys.sorted() {
            for byte in Array(key.utf8) {
                hash = (hash ^ UInt32(byte)) &* 16777619
            }
            let seq = UInt32(truncatingIfNeeded: vector[key] ?? 0)
            for shift in stride(from: 0, to: 32, by: 8) {
                hash = (hash ^ ((seq >> UInt32(shift)) & 0xFF)) &* 16777619
            }
        }
        return hash
    }

    static func data(of vector: [String: Int]) -> Data {
        var value = value(of: vector).bigEndian
        return Data(bytes: &value, count: 4)
    }
}

enum SharedBuysFraming {

    static func chunks(of payload: Data, messageID: UInt8) -> [Data] {
        guard !payload.isEmpty else { return [] }
        let limit = SharedBuysProfile.maxPayloadPerChunk
        var slices: [Data] = []
        var index = payload.startIndex
        while index < payload.endIndex {
            let end = payload.index(index, offsetBy: limit, limitedBy: payload.endIndex) ?? payload.endIndex
            slices.append(payload[index..<end])
            index = end
        }
        let count = UInt8(min(slices.count, 255))
        return slices.enumerated().map { offset, slice in
            var frame = Data([SharedBuysProfile.frameMagic, messageID, UInt8(offset), count])
            frame.append(slice)
            return frame
        }
    }

    /// Partial messages, held until every chunk of one arrives.
    ///
    /// The message id is a byte, so it wraps every 256 sends and a partial message can
    /// meet a later, unrelated one under the same id. Buffers are therefore bounded and
    /// expiring: a partial that never completes cannot survive to corrupt a reuse of its
    /// id, and a peer that walks out of range mid-message cannot leak memory.
    struct Reassembler {
        static let maxPartials = 4
        static let lifetime: TimeInterval = 10.0

        private struct Partial {
            var parts: [Int: Data]
            var count: Int
            var touched: Date
        }

        private var buffers: [UInt8: Partial] = [:]

        mutating func accept(_ frame: Data, at now: Date = .now) -> Data? {
            guard frame.count > 4, frame[frame.startIndex] == SharedBuysProfile.frameMagic else { return nil }
            let messageID = frame[frame.startIndex + 1]
            let index = Int(frame[frame.startIndex + 2])
            let count = Int(frame[frame.startIndex + 3])
            guard count > 0, index < count else { return nil }

            buffers = buffers.filter { now.timeIntervalSince($0.value.touched) < Self.lifetime }
            var partial = buffers[messageID] ?? Partial(parts: [:], count: count, touched: now)
            // A different chunk count under a known id means the id was reused rather
            // than continued, so the old parts are stale.
            if partial.count != count { partial = Partial(parts: [:], count: count, touched: now) }
            partial.parts[index] = frame.suffix(from: frame.startIndex + 4)
            partial.touched = now

            guard partial.parts.count == count else {
                buffers[messageID] = partial
                if buffers.count > Self.maxPartials,
                   let oldest = buffers.min(by: { $0.value.touched < $1.value.touched })?.key {
                    buffers[oldest] = nil
                }
                return nil
            }
            buffers[messageID] = nil
            var payload = Data()
            for position in 0..<count {
                guard let part = partial.parts[position] else { return nil }
                payload.append(part)
            }
            return payload
        }
    }
}
