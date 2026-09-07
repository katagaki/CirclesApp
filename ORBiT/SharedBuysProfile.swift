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

    struct Reassembler {
        private var buffers: [UInt8: [Int: Data]] = [:]

        mutating func accept(_ frame: Data) -> Data? {
            guard frame.count > 4, frame[frame.startIndex] == SharedBuysProfile.frameMagic else { return nil }
            let messageID = frame[frame.startIndex + 1]
            let index = Int(frame[frame.startIndex + 2])
            let count = Int(frame[frame.startIndex + 3])
            guard count > 0, index < count else { return nil }
            var parts = buffers[messageID] ?? [:]
            parts[index] = frame.suffix(from: frame.startIndex + 4)
            guard parts.count == count else {
                buffers[messageID] = parts
                return nil
            }
            buffers[messageID] = nil
            var payload = Data()
            for position in 0..<count {
                guard let part = parts[position] else { return nil }
                payload.append(part)
            }
            return payload
        }
    }
}
