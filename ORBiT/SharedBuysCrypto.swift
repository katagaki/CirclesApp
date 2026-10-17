import CryptoKit
import Foundation

enum SharedBuysCrypto {

    static let topicInfo = "circles-buys/v1/topic"
    static let opsInfo = "circles-buys/v1/ops"
    static let relayAuthInfo = "circles-buys/v1/relay-auth"
    static let handshakeInfo = "circles-buys/v1/ble-handshake"
    static let deviceInfo = "circles-buys/v1/device"
    static let deviceIDLength = 16
    static let signInfo = "circles-buys/v1/sign"
    static let tagLength = 16
    static let nonceLength = 12
    static let randomNonceMarker = Data([0x53, 0x42, 0x32, 0x00])

    static func newSessionKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    /// The device's ID is a hash of its device key, so the relay registers the ID only
    /// under that key and a member who has seen the ID cannot claim it first.
    static func deviceID(deviceAuthKey: Data) -> String {
        var input = Data(deviceInfo.utf8)
        input.append(0)
        input.append(deviceAuthKey)
        return Data(SHA256.hash(data: input)).prefix(deviceIDLength)
            .map { String(format: "%02x", $0) }.joined()
    }

    static func newDeviceAuthKey() -> Data { randomBytes(count: 32) }

    static func randomNonce(count: Int) -> Data { randomBytes(count: count) }

    static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
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

    static func helloInput(deviceID: String, timestamp: Int) -> Data {
        var input = Data("hello".utf8)
        input.append(0)
        input.append(Data(deviceID.utf8))
        input.append(0)
        input.append(bigEndian(UInt64(timestamp)))
        return input
    }

    static func helloTag(deviceID: String, timestamp: Int, relayAuthKey: SymmetricKey) -> Data {
        let input = helloInput(deviceID: deviceID, timestamp: timestamp)
        return Data(HMAC<SHA256>.authenticationCode(for: input, using: relayAuthKey)).prefix(tagLength)
    }

    /// The client data an attestation is bound to, matching the relay byte for byte.
    ///
    /// `hello` is the exact UTF-8 JSON sent in `X-Circles-Hello`, so the attestation
    /// covers every field of it — push token and device key included.
    static func attestInput(roomID: String, hello: Data) -> Data {
        var input = Data("attest".utf8)
        input.append(0)
        input.append(Data(roomID.utf8))
        input.append(0)
        input.append(hello)
        return input
    }

    static func clientDataHash(roomID: String, hello: Data) -> Data {
        Data(SHA256.hash(data: attestInput(roomID: roomID, hello: hello)))
    }

    static func recordTag(deviceID: String, seq: Int, blob: Data, relayAuthKey: SymmetricKey) -> Data {
        var input = Data(deviceID.utf8)
        input.append(0)
        input.append(bigEndian(UInt64(seq)))
        input.append(blob)
        return Data(HMAC<SHA256>.authenticationCode(for: input, using: relayAuthKey)).prefix(tagLength)
    }

    static func newSigningKey() -> Data { Curve25519.Signing.PrivateKey().rawRepresentation }

    static func publicKey(signingKey: Data) -> Data? {
        try? Curve25519.Signing.PrivateKey(rawRepresentation: signingKey).publicKey.rawRepresentation
    }

    /// What a record's signature covers: the room, the author's `(device, seq)` and every
    /// payload field but the signature, in a fixed binary layout.
    ///
    /// Not the JSON or the blob. A peer answering a `want` re-seals other devices' changes
    /// under a fresh nonce and re-encodes the payload, so neither survives forwarding, but
    /// these fields do.
    static func signInput(roomID: String, deviceID: String, seq: Int, payload: SharedBuyPayload) -> Data {
        var input = Data(signInfo.utf8)
        input.append(0)
        input.append(Data(hex: roomID) ?? Data())
        input.append(Data(hex: deviceID) ?? Data())
        input.append(bigEndian(UInt64(seq)))
        func integer(_ value: Int) { input.append(bigEndian(UInt64(bitPattern: Int64(value)))) }
        func text(_ value: String) {
            let bytes = Data(value.utf8)
            var length = UInt32(bytes.count).bigEndian
            input.append(Data(bytes: &length, count: 4))
            input.append(bytes)
        }
        func optional<T>(_ value: T?, _ write: (T) -> Void) {
            guard let value else { return input.append(0) }
            input.append(1)
            write(value)
        }
        integer(payload.actor)
        integer(payload.rawKind)
        text(payload.itemID)
        integer(payload.circleID)
        optional(payload.text, text)
        optional(payload.value, integer)
        optional(payload.space, text)
        optional(payload.clock, integer)
        optional(payload.publicKey, text)
        return input
    }

    static func sign(_ input: Data, signingKey: Data) -> Data? {
        try? Curve25519.Signing.PrivateKey(rawRepresentation: signingKey).signature(for: input)
    }

    static func verifies(_ signature: Data, input: Data, publicKey: Data) -> Bool {
        guard let key = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey) else { return false }
        return key.isValidSignature(signature, for: input)
    }

    static func rollingTag(sessionKey: Data, window: Int) -> Data {
        var input = Data("ble".utf8)
        input.append(bigEndian(UInt64(bitPattern: Int64(window))))
        let mac = HMAC<SHA256>.authenticationCode(for: input, using: SymmetricKey(data: sessionKey))
        return Data(mac).prefix(2)
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
        seq: Int,
        nonce suppliedNonce: Data? = nil
    ) throws -> Data {
        let nonce = suppliedNonce ?? randomBytes(count: nonceLength)
        guard nonce.count == nonceLength else { throw SharedBuysError.malformed }
        let box = try AES.GCM.seal(
            plaintext,
            using: contentKey,
            nonce: AES.GCM.Nonce(data: nonce),
            authenticating: associatedData(roomID: roomID, deviceID: deviceID, seq: seq)
        )
        return randomNonceMarker + nonce + box.ciphertext + box.tag
    }

    static func open(
        _ blob: Data,
        contentKey: SymmetricKey,
        roomID: String,
        deviceID: String,
        seq: Int
    ) throws -> Data {
        guard blob.count > tagLength else { throw SharedBuysError.malformed }
        let nonce: Data
        let sealed: Data
        if blob.starts(with: randomNonceMarker) {
            let nonceStart = randomNonceMarker.count
            let ciphertextStart = nonceStart + nonceLength
            guard blob.count > ciphertextStart + tagLength else { throw SharedBuysError.malformed }
            nonce = Data(blob[nonceStart..<ciphertextStart])
            sealed = Data(blob.dropFirst(ciphertextStart))
        } else {
            // Existing rooms used device + sequence as the nonce. Retain read support so
            // an upgrade can ingest their history, but never author another legacy blob.
            nonce = legacyNonce(deviceID: deviceID, seq: seq)
            sealed = blob
        }
        let box = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: sealed.dropLast(tagLength),
            tag: sealed.suffix(tagLength)
        )
        return try AES.GCM.open(
            box,
            using: contentKey,
            authenticating: associatedData(roomID: roomID, deviceID: deviceID, seq: seq)
        )
    }

    private static func legacyNonce(deviceID: String, seq: Int) -> Data {
        var value = Data(hex: deviceID) ?? Data(repeating: 0, count: 4)
        value.append(bigEndian(UInt64(seq)))
        return value
    }

    private static func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    private static func bigEndian(_ value: UInt64) -> Data {
        var wide = value.bigEndian
        return Data(bytes: &wide, count: 8)
    }
}

/// The two keys every record needs, derived once per room rather than per record.
struct SharedBuysKeys: Sendable {
    let content: SymmetricKey
    let relayAuth: SymmetricKey

    init(sessionKey: Data) {
        content = SharedBuysCrypto.derive(SharedBuysCrypto.opsInfo, from: sessionKey)
        relayAuth = SharedBuysCrypto.derive(SharedBuysCrypto.relayAuthInfo, from: sessionKey)
    }
}

/// Which key, if any, each device in the room signs with.
///
/// A device's first `memberJoined` decides it: one carrying a public key pins that key,
/// one without marks a device running a build from before signatures, whose records are
/// taken on the room key alone as they always were. A device whose `memberJoined` has not
/// arrived is unknown, and nothing it wrote is adopted yet — whichever copy reached us
/// first would otherwise win, forged or not. Its records come again, since the version
/// vector never claimed them.
struct SharedBuySigners: Sendable {

    private enum Signer: Sendable {
        case key(Data)
        case unsigned
    }

    private var byDevice: [String: Signer] = [:]

    init(changes: [SharedBuyChange]) {
        for change in changes.sorted(by: { $0.seq < $1.seq })
        where change.payload.kind == .memberJoined && byDevice[change.device] == nil {
            byDevice[change.device] = Self.signer(announcedBy: change.payload)
        }
    }

    /// Whether the change may enter the log, learning its device's key if it introduces one.
    mutating func admit(_ change: SharedBuyChange, roomID: String) -> Bool {
        switch byDevice[change.device] {
        case .key(let key):
            return Self.verifies(change, roomID: roomID, publicKey: key)
        case .unsigned:
            return true
        case nil:
            guard change.payload.kind == .memberJoined,
                  let signer = Self.signer(announcedBy: change.payload) else { return false }
            if case .key(let key) = signer, !Self.verifies(change, roomID: roomID, publicKey: key) {
                return false
            }
            byDevice[change.device] = signer
            return true
        }
    }

    private static func signer(announcedBy payload: SharedBuyPayload) -> Signer? {
        guard let encoded = payload.publicKey else { return .unsigned }
        guard let key = Data(base64URL: encoded), key.count == 32 else { return nil }
        return .key(key)
    }

    private static func verifies(_ change: SharedBuyChange, roomID: String, publicKey: Data) -> Bool {
        guard let encoded = change.payload.signature, let signature = Data(base64URL: encoded) else {
            return false
        }
        let input = SharedBuysCrypto.signInput(
            roomID: roomID,
            deviceID: change.device,
            seq: change.seq,
            payload: change.payload
        )
        return SharedBuysCrypto.verifies(signature, input: input, publicKey: publicKey)
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
