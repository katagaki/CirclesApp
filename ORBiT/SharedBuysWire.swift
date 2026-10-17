import Foundation

/// The binary frame both apps speak over Bluetooth.
///
/// `version ‖ type ‖ count`, then a body per type. Records carry the same sealed blob
/// the relay stores, so `(device, seq)` dedup stays transport-agnostic. JSON cost 163
/// bytes for a single status flip — two chunks — where this costs 97.
enum SharedBuysWire {

    static let changesType: UInt8 = 0x01
    static let wantType: UInt8 = 0x02
    static let headerLength = 3

    /// Version 1 carries the 4-byte IDs older clients drew at random, version 2 the
    /// 16-byte IDs derived from a device key. The layout is otherwise the same, and each
    /// length keeps to its own version so a client that only knows version 1 still
    /// trades legacy records with us.
    static let deviceLengths: [UInt8: Int] = [0x01: 4, 0x02: SharedBuysCrypto.deviceIDLength]
    static let versions: [UInt8] = deviceLengths.keys.sorted()

    enum Frame {
        case changes([RelayRecord])
        case want([String: Int], deviceLength: Int)
    }

    static func deviceLength(of device: String) -> Int { device.utf8.count / 2 }

    // MARK: Encoding

    /// Frames holding the records, packed so each one still fits a single chunk.
    static func changeFrames(_ records: [RelayRecord]) -> [Data] {
        versions.flatMap { version in
            let length = deviceLengths[version]!
            return pack(records.compactMap { body(of: $0, deviceLength: length) }, version: version, type: changesType)
        }
    }

    /// Frames holding the version vector, packed so each one still fits a single chunk.
    ///
    /// A want only speaks for devices whose ID length matches its version, so every
    /// version sends at least one frame. An empty one, `count` 0, means "send me
    /// everything": packing nothing produced no frame at all, and a peer holding
    /// nothing never asked.
    static func wantFrames(_ vector: [String: Int]) -> [Data] {
        versions.flatMap { version -> [Data] in
            let length = deviceLengths[version]!
            let bodies = vector.sorted { $0.key < $1.key }.compactMap { entry -> Data? in
                guard let device = Data(hex: entry.key), device.count == length, entry.value > 0
                else { return nil }
                var body = device
                body.append(bigEndian(UInt64(entry.value)))
                return body
            }
            guard !bodies.isEmpty else { return [Data([version, wantType, 0])] }
            return pack(bodies, version: version, type: wantType)
        }
    }

    private static func body(of record: RelayRecord, deviceLength: Int) -> Data? {
        guard let device = Data(hex: record.device), device.count == deviceLength,
              record.seq > 0,
              let blob = Data(base64URL: record.blob),
              blob.count > SharedBuysCrypto.tagLength, blob.count <= Int(UInt16.max),
              let tag = Data(base64URL: record.tag), tag.count == SharedBuysCrypto.tagLength
        else { return nil }
        var body = device
        body.append(bigEndian(UInt64(record.seq)))
        body.append(UInt8(truncatingIfNeeded: blob.count >> 8))
        body.append(UInt8(truncatingIfNeeded: blob.count))
        body.append(blob)
        body.append(tag)
        return body
    }

    /// A record spanning more than one chunk still gets its own frame: the chunk layer
    /// splits it, rather than the body being silently dropped.
    private static func pack(_ bodies: [Data], version: UInt8, type: UInt8) -> [Data] {
        let limit = SharedBuysProfile.maxPayloadPerChunk - headerLength
        var frames: [Data] = []
        var group: [Data] = []
        var size = 0

        func flush() {
            guard !group.isEmpty else { return }
            var frame = Data([version, type, UInt8(group.count)])
            for body in group { frame.append(body) }
            frames.append(frame)
            group = []
            size = 0
        }

        for body in bodies {
            if !group.isEmpty, size + body.count > limit || group.count == 255 { flush() }
            group.append(body)
            size += body.count
        }
        flush()
        return frames
    }

    // MARK: Decoding

    static func decode(_ payload: Data) -> Frame? {
        let bytes = [UInt8](payload)
        // A frame of another version is skipped, not parsed: the layout behind the
        // header is what changes, so guessing at it would fold garbage into the log.
        guard bytes.count >= headerLength, let deviceLength = deviceLengths[bytes[0]] else { return nil }
        let count = Int(bytes[2])
        switch bytes[1] {
        case changesType: return changes(in: bytes, count: count, deviceLength: deviceLength)
        case wantType: return want(in: bytes, count: count, deviceLength: deviceLength)
        default: return nil
        }
    }

    private static func changes(in bytes: [UInt8], count: Int, deviceLength: Int) -> Frame? {
        var records: [RelayRecord] = []
        var offset = headerLength
        for _ in 0..<count {
            guard offset + deviceLength + 8 + 2 <= bytes.count else { return nil }
            let device = hex(bytes[offset..<offset + deviceLength])
            offset += deviceLength
            guard let seq = sequence(in: bytes, at: offset) else { return nil }
            offset += 8
            let blobLength = Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
            offset += 2
            // The length is a peer's claim about a buffer we hold: check it against
            // what is actually left before slicing.
            guard blobLength > SharedBuysCrypto.tagLength,
                  offset + blobLength + SharedBuysCrypto.tagLength <= bytes.count
            else { return nil }
            let blob = Data(bytes[offset..<offset + blobLength])
            offset += blobLength
            let tag = Data(bytes[offset..<offset + SharedBuysCrypto.tagLength])
            offset += SharedBuysCrypto.tagLength
            records.append(
                RelayRecord(device: device, seq: seq, blob: blob.base64URL, tag: tag.base64URL)
            )
        }
        return .changes(records)
    }

    private static func want(in bytes: [UInt8], count: Int, deviceLength: Int) -> Frame? {
        var vector: [String: Int] = [:]
        var offset = headerLength
        for _ in 0..<count {
            guard offset + deviceLength + 8 <= bytes.count else { return nil }
            let device = hex(bytes[offset..<offset + deviceLength])
            guard let seq = sequence(in: bytes, at: offset + deviceLength) else { return nil }
            vector[device] = max(vector[device] ?? 0, seq)
            offset += deviceLength + 8
        }
        return .want(vector, deviceLength: deviceLength)
    }

    private static func sequence(in bytes: [UInt8], at offset: Int) -> Int? {
        guard offset + 8 <= bytes.count else { return nil }
        var value: UInt64 = 0
        for index in 0..<8 { value = value << 8 | UInt64(bytes[offset + index]) }
        guard value > 0, value <= UInt64(Int.max) else { return nil }
        return Int(value)
    }

    private static func hex(_ bytes: ArraySlice<UInt8>) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func bigEndian(_ value: UInt64) -> Data {
        var wide = value.bigEndian
        return Data(bytes: &wide, count: 8)
    }
}
