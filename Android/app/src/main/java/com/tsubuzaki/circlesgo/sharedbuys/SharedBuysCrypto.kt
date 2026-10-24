package com.tsubuzaki.circlesgo.sharedbuys

import com.google.crypto.tink.subtle.Ed25519Sign
import com.google.crypto.tink.subtle.Ed25519Verify
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.math.BigInteger
import java.nio.ByteBuffer
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.PublicKey
import java.security.SecureRandom
import java.security.interfaces.ECPrivateKey
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.security.spec.ECParameterSpec
import java.security.spec.ECPoint
import java.security.spec.ECPrivateKeySpec
import java.security.spec.ECPublicKeySpec
import javax.crypto.Cipher
import javax.crypto.KeyAgreement
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object SharedBuysCrypto {

    const val TOPIC_INFO = "circles-buys/v1/topic"
    const val OPS_INFO = "circles-buys/v1/ops"
    const val RELAY_AUTH_INFO = "circles-buys/v1/relay-auth"
    const val HANDSHAKE_INFO = "circles-buys/v1/ble-handshake"
    const val REKEY_INFO = "circles-buys/v1/rekey"
    const val PUBLIC_KEY_LENGTH = 65
    private const val REKEY_PLAINTEXT_LENGTH = 36
    const val SIGN_INFO = "circles-buys/v1/sign"
    const val TAG_LENGTH = 16
    const val NONCE_LENGTH = 12
    val RANDOM_NONCE_MARKER = byteArrayOf(0x53, 0x42, 0x32, 0x00)

    private val random = SecureRandom()

    fun newSessionKey(): ByteArray = ByteArray(32).also { random.nextBytes(it) }

    fun newDeviceId(): String = ByteArray(4).also { random.nextBytes(it) }.toHex()

    fun newDeviceAuthKey(): ByteArray = ByteArray(32).also { random.nextBytes(it) }

    fun randomNonce(size: Int): ByteArray = ByteArray(size).also { random.nextBytes(it) }

    fun roomId(sessionKey: ByteArray): String =
        hmac(sessionKey, TOPIC_INFO.toByteArray()).copyOf(16).toHex()

    fun derive(info: String, sessionKey: ByteArray): ByteArray {
        val prk = hmac(ByteArray(32), sessionKey)
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(prk, "HmacSHA256"))
        mac.update(info.toByteArray())
        mac.update(1.toByte())
        return mac.doFinal().copyOf(32)
    }

    fun helloInput(deviceId: String, timestamp: Long): ByteArray {
        val input = ByteBuffer.allocate(5 + 1 + deviceId.length + 1 + 8)
        input.put("hello".toByteArray())
        input.put(0)
        input.put(deviceId.toByteArray())
        input.put(0)
        input.putLong(timestamp)
        return input.array()
    }

    fun helloTag(deviceId: String, timestamp: Long, relayAuthKey: ByteArray): ByteArray =
        hmac(relayAuthKey, helloInput(deviceId, timestamp)).copyOf(TAG_LENGTH)

    /**
     * The client data an attestation is bound to, matching the relay byte for byte.
     *
     * hello is the exact UTF-8 JSON sent in X-Circles-Hello, so the attestation covers
     * every field of it — push token and device key included.
     */
    fun attestInput(roomId: String, hello: ByteArray): ByteArray {
        val input = ByteBuffer.allocate(6 + 1 + roomId.length + 1 + hello.size)
        input.put("attest".toByteArray())
        input.put(0)
        input.put(roomId.toByteArray())
        input.put(0)
        input.put(hello)
        return input.array()
    }

    fun requestHash(roomId: String, hello: ByteArray): String =
        java.security.MessageDigest.getInstance("SHA-256")
            .digest(attestInput(roomId, hello))
            .toBase64Url()

    fun recordTag(deviceId: String, seq: Long, blob: ByteArray, relayAuthKey: ByteArray): ByteArray {
        val input = ByteBuffer.allocate(deviceId.length + 1 + 8 + blob.size)
        input.put(deviceId.toByteArray())
        input.put(0)
        input.putLong(seq)
        input.put(blob)
        return hmac(relayAuthKey, input.array()).copyOf(TAG_LENGTH)
    }

    fun newSigningKey(): ByteArray = Ed25519Sign.KeyPair.newKeyPair().privateKey

    fun publicKey(signingKey: ByteArray): ByteArray =
        Ed25519Sign.KeyPair.newKeyPairFromSeed(signingKey).publicKey

    /**
     * What a record's signature covers: the room, the author's (device, seq) and every
     * payload field but the signature, in a fixed binary layout.
     *
     * Not the JSON or the blob. A peer answering a want re-seals other devices' changes
     * under a fresh nonce and re-encodes the payload, so neither survives forwarding, but
     * these fields do.
     */
    fun signInput(roomId: String, deviceId: String, seq: Long, payload: SharedBuyPayload): ByteArray {
        val bytes = ByteArrayOutputStream()
        val out = DataOutputStream(bytes)
        fun text(value: String) {
            val utf8 = value.toByteArray(Charsets.UTF_8)
            out.writeInt(utf8.size)
            out.write(utf8)
        }
        fun <T> optional(value: T?, write: (T) -> Unit) {
            if (value == null) {
                out.writeByte(0)
            } else {
                out.writeByte(1)
                write(value)
            }
        }
        out.write(SIGN_INFO.toByteArray())
        out.writeByte(0)
        out.write(roomId.fromHex())
        out.write(deviceId.fromHex())
        out.writeLong(seq)
        out.writeLong(payload.actor.toLong())
        out.writeLong(payload.kind.toLong())
        text(payload.itemId)
        out.writeLong(payload.circleId.toLong())
        optional(payload.text) { text(it) }
        optional(payload.value) { out.writeLong(it.toLong()) }
        optional(payload.space) { text(it) }
        optional(payload.clock) { out.writeLong(it) }
        optional(payload.publicKey) { text(it) }
        return bytes.toByteArray()
    }

    fun sign(input: ByteArray, signingKey: ByteArray): ByteArray = Ed25519Sign(signingKey).sign(input)

    fun verifies(signature: ByteArray, input: ByteArray, publicKey: ByteArray): Boolean =
        runCatching { Ed25519Verify(publicKey).verify(signature, input) }.isSuccess

    fun seal(
        plaintext: ByteArray,
        contentKey: ByteArray,
        roomId: String,
        deviceId: String,
        seq: Long,
        suppliedNonce: ByteArray? = null
    ): ByteArray {
        val nonce = suppliedNonce ?: ByteArray(NONCE_LENGTH).also { random.nextBytes(it) }
        require(nonce.size == NONCE_LENGTH)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.ENCRYPT_MODE,
            SecretKeySpec(contentKey, "AES"),
            GCMParameterSpec(128, nonce)
        )
        cipher.updateAAD(associatedData(roomId, deviceId, seq))
        return RANDOM_NONCE_MARKER + nonce + cipher.doFinal(plaintext)
    }

    fun open(
        blob: ByteArray,
        contentKey: ByteArray,
        roomId: String,
        deviceId: String,
        seq: Long
    ): ByteArray {
        val marked = blob.size > RANDOM_NONCE_MARKER.size + NONCE_LENGTH + TAG_LENGTH &&
            blob.copyOfRange(0, RANDOM_NONCE_MARKER.size).contentEquals(RANDOM_NONCE_MARKER)
        val nonce = if (marked) {
            blob.copyOfRange(RANDOM_NONCE_MARKER.size, RANDOM_NONCE_MARKER.size + NONCE_LENGTH)
        } else {
            legacyNonce(deviceId, seq)
        }
        val sealed = if (marked) blob.copyOfRange(RANDOM_NONCE_MARKER.size + NONCE_LENGTH, blob.size) else blob
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            SecretKeySpec(contentKey, "AES"),
            GCMParameterSpec(128, nonce)
        )
        cipher.updateAAD(associatedData(roomId, deviceId, seq))
        return cipher.doFinal(sealed)
    }

    private val p256: ECParameterSpec by lazy { (newAgreementKey().public as ECPublicKey).params }

    fun newAgreementKey(): KeyPair =
        KeyPairGenerator.getInstance("EC")
            .apply { initialize(ECGenParameterSpec("secp256r1"), random) }
            .generateKeyPair()

    fun publicKeyBytes(key: PublicKey): ByteArray {
        val point = (key as ECPublicKey).w
        return byteArrayOf(4) + point.affineX.toFixed(32) + point.affineY.toFixed(32)
    }

    fun agreementPublicKey(bytes: ByteArray): PublicKey {
        require(bytes.size == PUBLIC_KEY_LENGTH && bytes[0] == 4.toByte())
        val point = ECPoint(
            BigInteger(1, bytes.copyOfRange(1, 33)),
            BigInteger(1, bytes.copyOfRange(33, PUBLIC_KEY_LENGTH))
        )
        return KeyFactory.getInstance("EC").generatePublic(ECPublicKeySpec(point, p256))
    }

    fun privateKeyBytes(key: PrivateKey): ByteArray = (key as ECPrivateKey).s.toFixed(32)

    fun privateKey(bytes: ByteArray): PrivateKey =
        KeyFactory.getInstance("EC").generatePrivate(ECPrivateKeySpec(BigInteger(1, bytes), p256))

    fun sealRekey(
        sessionKey: ByteArray,
        ownerDevice: String,
        publicKey: ByteArray,
        roomId: String,
        deviceId: String,
        ephemeral: KeyPair = newAgreementKey(),
        suppliedNonce: ByteArray? = null
    ): ByteArray {
        require(sessionKey.size == 32 && ownerDevice.length == 8)
        val nonce = suppliedNonce ?: randomNonce(NONCE_LENGTH)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.ENCRYPT_MODE,
            SecretKeySpec(rekeyWrapKey(ephemeral.private, agreementPublicKey(publicKey)), "AES"),
            GCMParameterSpec(128, nonce)
        )
        cipher.updateAAD(roomId.fromHex() + deviceId.fromHex())
        return publicKeyBytes(ephemeral.public) + nonce + cipher.doFinal(sessionKey + ownerDevice.fromHex())
    }

    fun openRekey(box: ByteArray, privateKey: PrivateKey, roomId: String, deviceId: String): Pair<ByteArray, String> {
        require(box.size == PUBLIC_KEY_LENGTH + NONCE_LENGTH + REKEY_PLAINTEXT_LENGTH + TAG_LENGTH)
        val nonceEnd = PUBLIC_KEY_LENGTH + NONCE_LENGTH
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            SecretKeySpec(rekeyWrapKey(privateKey, agreementPublicKey(box.copyOfRange(0, PUBLIC_KEY_LENGTH))), "AES"),
            GCMParameterSpec(128, box.copyOfRange(PUBLIC_KEY_LENGTH, nonceEnd))
        )
        cipher.updateAAD(roomId.fromHex() + deviceId.fromHex())
        val plaintext = cipher.doFinal(box.copyOfRange(nonceEnd, box.size))
        return plaintext.copyOfRange(0, 32) to plaintext.copyOfRange(32, REKEY_PLAINTEXT_LENGTH).toHex()
    }

    private fun rekeyWrapKey(privateKey: PrivateKey, publicKey: PublicKey): ByteArray {
        val agreement = KeyAgreement.getInstance("ECDH")
        agreement.init(privateKey)
        agreement.doPhase(publicKey, true)
        return derive(REKEY_INFO, agreement.generateSecret())
    }

    private fun BigInteger.toFixed(size: Int): ByteArray {
        val raw = toByteArray()
        return if (raw.size >= size) raw.copyOfRange(raw.size - size, raw.size) else ByteArray(size - raw.size) + raw
    }

    private fun legacyNonce(deviceId: String, seq: Long): ByteArray =
        ByteBuffer.allocate(12).put(deviceId.fromHex()).putLong(seq).array()

    private fun associatedData(roomId: String, deviceId: String, seq: Long): ByteArray =
        ByteBuffer.allocate(16 + 4 + 8)
            .put(roomId.fromHex())
            .put(deviceId.fromHex())
            .putLong(seq)
            .array()

    fun hmac(key: ByteArray, message: ByteArray): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(key, "HmacSHA256"))
        return mac.doFinal(message)
    }
}

/**
 * Which key, if any, each device in the room signs with.
 *
 * A device's first MEMBER_JOINED decides it: one carrying a public key pins that key, one
 * without marks a device running a build from before signatures, whose records are taken
 * on the room key alone as they always were. A device whose MEMBER_JOINED has not arrived
 * is unknown, and nothing it wrote is adopted yet -- whichever copy reached us first would
 * otherwise win, forged or not. Its records come again, since the version vector never
 * claimed them.
 */
class SharedBuySigners(changes: List<SharedBuyChange>) {

    private sealed interface Signer {
        class Key(val bytes: ByteArray) : Signer
        data object Unsigned : Signer
    }

    private val byDevice = mutableMapOf<String, Signer>()

    init {
        for (change in changes.sortedBy { it.seq }) {
            if (change.payload.kind != SharedBuyKind.MEMBER_JOINED || change.device in byDevice) continue
            signer(change.payload)?.let { byDevice[change.device] = it }
        }
    }

    /** Whether the change may enter the log, learning its device's key if it introduces one. */
    fun admit(change: SharedBuyChange, roomId: String): Boolean =
        when (val known = byDevice[change.device]) {
            is Signer.Key -> verifies(change, roomId, known.bytes)
            Signer.Unsigned -> true
            null -> {
                val announced = if (change.payload.kind == SharedBuyKind.MEMBER_JOINED) {
                    signer(change.payload)
                } else {
                    null
                }
                val admitted = announced != null &&
                    (announced !is Signer.Key || verifies(change, roomId, announced.bytes))
                if (admitted) byDevice[change.device] = announced!!
                admitted
            }
        }

    private fun signer(payload: SharedBuyPayload): Signer? {
        val encoded = payload.publicKey ?: return Signer.Unsigned
        val key = runCatching { encoded.fromBase64Url() }.getOrNull()
        return if (key != null && key.size == 32) Signer.Key(key) else null
    }

    private fun verifies(change: SharedBuyChange, roomId: String, publicKey: ByteArray): Boolean =
        runCatching {
            val signature = change.payload.signature?.fromBase64Url() ?: return false
            SharedBuysCrypto.verifies(
                signature,
                SharedBuysCrypto.signInput(roomId, change.device, change.seq, change.payload),
                publicKey
            )
        }.getOrDefault(false)
}

/** The two keys every record needs, derived once per room rather than per record. */
class SharedBuysKeys(sessionKey: ByteArray) {
    val content: ByteArray = SharedBuysCrypto.derive(SharedBuysCrypto.OPS_INFO, sessionKey)
    val relayAuth: ByteArray = SharedBuysCrypto.derive(SharedBuysCrypto.RELAY_AUTH_INFO, sessionKey)
}

fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

fun String.fromHex(): ByteArray =
    chunked(2).map { it.toInt(16).toByte() }.toByteArray()

fun ByteArray.toBase64Url(): String =
    android.util.Base64.encodeToString(
        this,
        android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP
    )

fun String.fromBase64Url(): ByteArray =
    android.util.Base64.decode(
        this,
        android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP
    )
