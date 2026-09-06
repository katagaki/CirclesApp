//
//  SharedBuysCrypto.swift
//  CiRCLES
//

import CryptoKit
import Foundation

enum SharedBuysCrypto {

    static let topicInfo = "circles-buys/v1/topic"
    static let opsInfo = "circles-buys/v1/ops"
    static let relayAuthInfo = "circles-buys/v1/relay-auth"
    static let tagLength = 16

    static func newSessionKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    static func newDeviceID() -> String {
        var bytes = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func roomID(sessionKey: Data) -> String {
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data(topicInfo.utf8),
            using: SymmetricKey(data: sessionKey)
        )
        return Data(mac).prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    static func derive(_ info: String, from sessionKey: Data) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: sessionKey),
            info: Data(info.utf8),
            outputByteCount: 32
        )
    }

    static func helloTag(deviceID: String, timestamp: Int, relayAuthKey: SymmetricKey) -> Data {
        var input = Data("hello".utf8)
        input.append(0)
        input.append(Data(deviceID.utf8))
        input.append(0)
        input.append(bigEndian(UInt64(timestamp)))
        return Data(HMAC<SHA256>.authenticationCode(for: input, using: relayAuthKey)).prefix(tagLength)
    }

    static func recordTag(deviceID: String, seq: Int, blob: Data, relayAuthKey: SymmetricKey) -> Data {
        var input = Data(deviceID.utf8)
        input.append(0)
        input.append(bigEndian(UInt64(seq)))
        input.append(blob)
        return Data(HMAC<SHA256>.authenticationCode(for: input, using: relayAuthKey)).prefix(tagLength)
    }

    static func nonce(deviceID: String, seq: Int) -> Data {
        var value = Data(hex: deviceID) ?? Data(repeating: 0, count: 4)
        value.append(bigEndian(UInt64(seq)))
        return value
    }

    static func associatedData(roomID: String, deviceID: String, seq: Int) -> Data {
        var value = Data(hex: roomID) ?? Data()
        value.append(Data(hex: deviceID) ?? Data())
        value.append(bigEndian(UInt64(seq)))
        return value
    }

    static func seal(
        _ plaintext: Data,
        contentKey: SymmetricKey,
        roomID: String,
        deviceID: String,
        seq: Int
    ) throws -> Data {
        let box = try AES.GCM.seal(
            plaintext,
            using: contentKey,
            nonce: AES.GCM.Nonce(data: nonce(deviceID: deviceID, seq: seq)),
            authenticating: associatedData(roomID: roomID, deviceID: deviceID, seq: seq)
        )
        return box.ciphertext + box.tag
    }

    static func open(
        _ blob: Data,
        contentKey: SymmetricKey,
        roomID: String,
        deviceID: String,
        seq: Int
    ) throws -> Data {
        guard blob.count > 16 else { throw SharedBuysError.malformed }
        let box = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce(deviceID: deviceID, seq: seq)),
            ciphertext: blob.dropLast(16),
            tag: blob.suffix(16)
        )
        return try AES.GCM.open(
            box,
            using: contentKey,
            authenticating: associatedData(roomID: roomID, deviceID: deviceID, seq: seq)
        )
    }

    private static func bigEndian(_ value: UInt64) -> Data {
        var wide = value.bigEndian
        return Data(bytes: &wide, count: 8)
    }
}

enum SharedBuysError: Error {
    case malformed
    case badJoinURL
}

extension Data {
    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else { return nil }
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        self = Data(bytes)
    }

    var base64URL: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URL: String) {
        var text = base64URL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while !text.count.isMultiple(of: 4) { text.append("=") }
        guard let data = Data(base64Encoded: text) else { return nil }
        self = data
    }
}
