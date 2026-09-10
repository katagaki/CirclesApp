import Foundation

/// The binary frame both apps speak over Bluetooth.
///
/// `version ‖ type ‖ count`, then a body per type. Records carry the same sealed blob
/// the relay stores, so `(device, seq)` dedup stays transport-agnostic. JSON cost 163
/// bytes for a single status flip — two chunks — where this costs 97.
enum SharedBuysWire {

    static let version: UInt8 = 0x01
    static let changesType: UInt8 = 0x01
    static let wantType: UInt8 = 0x02
    static let headerLength = 3
    static let deviceLength = 4
    static let wantEntryLength = 12

    enum Frame {
        case changes([RelayRecord])
        case want([String: Int])
    }

    // MARK: Encoding

    /// Frames holding the records, packed so each one still fits a single chunk.
    static func changeFrames(_ records: [RelayRecord]) -> [Data] {
        pack(records.compactMap(body(of:)), type: changesType)
    }

    /// Frames holding the version vector, packed so each one still fits a single chunk.
    static func wantFrames(_ vector: [String: Int]) -> [Data] {
        let bodies = vector.sorted { $0.key < $1.key }.compactMap { entry -> Data? in
            guard let device = Data(hex: entry.key), device.count == deviceLength, entry.value > 0
            else { return nil }
            var body = device
            body.append(bigEndian(UInt64(entry.value)))
            return body
        }
        return pack(bodies, type: wantType)
    }

    private static func body(of record: RelayRecord) -> Data? {
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
    private static func pack(_ bodies: [Data], type: UInt8) -> [Data] {
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
        guard bytes.count >= headerLength, bytes[0] == version else { return nil }
        let count = Int(bytes[2])
        switch bytes[1] {
        case changesType: return changes(in: bytes, count: count)
        case wantType: return want(in: bytes, count: count)
        default: return nil
        }
    }

    private static func changes(in bytes: [UInt8], count: Int) -> Frame? {
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

    private static func want(in bytes: [UInt8], count: Int) -> Frame? {
        var vector: [String: Int] = [:]
        var offset = headerLength
        for _ in 0..<count {
            guard offset + wantEntryLength <= bytes.count else { return nil }
            let device = hex(bytes[offset..<offset + deviceLength])
            guard let seq = sequence(in: bytes, at: offset + deviceLength) else { return nil }
            vector[device] = max(vector[device] ?? 0, seq)
            offset += wantEntryLength
        }
        return .want(vector)
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
