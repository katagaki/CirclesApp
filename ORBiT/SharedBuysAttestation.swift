import CryptoKit
import DeviceCheck
import Foundation

/// One device's App Attest evidence for the authenticated upgrade.
struct SharedBuysEvidence: Sendable {
    let keyID: String
    var attestation: String?
    var assertion: String?

    var frame: [String: Any] {
        var value: [String: Any] = ["t": "appattest", "k": Data(base64Encoded: keyID)?.base64URL ?? keyID]
        if let attestation { value["o"] = attestation }
        if let assertion { value["s"] = assertion }
        return value
    }
}

/// App Attest evidence for the relay's upgrade request.
///
/// The first hello from an install carries an attestation object, which asks Apple to
/// certify a fresh Secure Enclave key; every later hello carries a cheap assertion
/// signed by that key. The relay refuses a second attestation for a key whose counter
/// has already moved, so the enrolled flag has to survive launches — and has to be
/// cleared when the relay rejects us, or an install whose enrollment never landed
/// would sign assertions against a key the relay has never heard of.
actor SharedBuysAttestation {

    static let shared = SharedBuysAttestation()

    private let service = DCAppAttestService.shared
    private let defaults = UserDefaults(suiteName: "group.com.tsubuzaki.CiRCLES") ?? .standard
    private let keyIDDefault = "sharedBuysAttestKeyID"
    private let enrolledDefault = "sharedBuysAttestEnrolled"

    /// Whether this device can attest at all.
    ///
    /// False in the Simulator, on Mac — Catalyst included — and in most app extensions,
    /// so every caller has to treat absent evidence as normal rather than as a failure.
    var isSupported: Bool { service.isSupported }

    private var keyID: String? {
        get { defaults.string(forKey: keyIDDefault) }
        set { defaults.set(newValue, forKey: keyIDDefault) }
    }

    private var isEnrolled: Bool {
        get { defaults.bool(forKey: enrolledDefault) }
        set { defaults.set(newValue, forKey: enrolledDefault) }
    }

    /// Builds the `at` object for a hello, or nil when this device cannot attest.
    func evidence(roomID: String, deviceID: String, timestamp: Int) async -> SharedBuysEvidence? {
        guard service.isSupported else { return nil }
        let hash = SharedBuysCrypto.clientDataHash(
            deviceID: deviceID,
            timestamp: timestamp,
            roomID: roomID
        )
        guard let key = await key() else { return nil }
        if isEnrolled {
            guard let assertion = try? await service.generateAssertion(key, clientDataHash: hash) else {
                // The enclave no longer holds this key, so the next hello enrolls a new one.
                invalidate()
                return nil
            }
            return SharedBuysEvidence(keyID: key, assertion: assertion.base64URL)
        }
        guard let object = try? await service.attestKey(key, clientDataHash: hash) else { return nil }
        isEnrolled = true
        return SharedBuysEvidence(keyID: key, attestation: object.base64URL)
    }

    /// Drops the old key so the next connection can enroll with a fresh attestation.
    ///
    /// Called when the relay answers a hello with an auth failure: the stored key may
    /// be one it never accepted, and assertions against it can only keep failing.
    func invalidate() {
        reset()
    }

    /// Drops the key as well, for when the key itself is what the relay rejected.
    func reset() {
        isEnrolled = false
        keyID = nil
    }

    private func key() async -> String? {
        if let existing = keyID { return existing }
        guard let generated = try? await service.generateKey() else { return nil }
        keyID = generated
        isEnrolled = false
        return generated
    }
}
