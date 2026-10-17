package com.tsubuzaki.circlesgo.sharedbuys

import java.nio.ByteBuffer
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

object SharedBuysProfile {

    val SERVICE_UUID: UUID = UUID.fromString("A7C1F2E0-5B3D-4E8A-9F16-3C2D8E4B7A90")
    val INBOX_UUID: UUID = UUID.fromString("A7C1F2E1-5B3D-4E8A-9F16-3C2D8E4B7A90")
    val OUTBOX_UUID: UUID = UUID.fromString("A7C1F2E2-5B3D-4E8A-9F16-3C2D8E4B7A90")

    const val ADVERTISEMENT_WINDOW_SECONDS = 900L
    const val MAX_PAYLOAD_PER_CHUNK = 160
    const val FRAME_MAGIC: Byte = 0x01
    const val ADVERTISEMENT_LENGTH = 6
    const val FRAME_HEADER_LENGTH = 4
    const val DEFAULT_ATT_MTU = 23

    /**
     * The body a chunk may carry over a link with the given ATT MTU.
     *
     * Never larger than MAX_PAYLOAD_PER_CHUNK, and never smaller than one byte, so a
     * miserly link produces many small chunks instead of silent truncation. Three bytes
     * of the MTU belong to the ATT write header.
     */
    fun payloadLimit(mtu: Int): Int =
        maxOf(1, minOf(MAX_PAYLOAD_PER_CHUNK, mtu - 3 - FRAME_HEADER_LENGTH))

    fun window(epochSeconds: Long = System.currentTimeMillis() / 1000): Long =
        epochSeconds / ADVERTISEMENT_WINDOW_SECONDS

    fun sessionTag(sessionKey: ByteArray, window: Long = window()): ByteArray {
        val input = ByteBuffer.allocate(3 + 8).put("ble".toByteArray()).putLong(window).array()
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(sessionKey, "HmacSHA256"))
        return mac.doFinal(input).copyOf(2)
    }

    fun acceptedTags(sessionKey: ByteArray, window: Long = window()): List<ByteArray> =
        listOf(window - 1, window, window + 1).map { sessionTag(sessionKey, it) }

    /**
     * The bytes a peer needs before it is worth connecting: the rolling tag that scopes
     * the advertisement to this room, and the digest of what the sender holds.
     *
     * Without the tag every nearby CiRCLES user connects and then fails the handshake,
     * which at a venue is a stream of connections that can only fail. The tag rotates
     * with the 15 minute window, so it scopes discovery without making a device
     * trackable across the day.
     */
    fun advertisement(sessionKey: ByteArray, digest: ByteArray): ByteArray =
        (sessionTag(sessionKey) + digest.copyOf(4)).copyOf(ADVERTISEMENT_LENGTH)

    /** iOS cannot advertise service data, so it carries the same bytes as a local name. */
    fun localName(sessionKey: ByteArray, digest: ByteArray): String =
        advertisement(sessionKey, digest).toHex()

    /** Reads the advertisement out of whichever field the peer's platform could use. */
    fun advertisement(serviceData: ByteArray?, localName: String?): ByteArray? {
        if (serviceData != null && serviceData.size == ADVERTISEMENT_LENGTH) return serviceData
        if (localName == null || localName.length != ADVERTISEMENT_LENGTH * 2) return null
        return runCatching { localName.fromHex() }.getOrNull()
            ?.takeIf { it.size == ADVERTISEMENT_LENGTH }
    }

    fun digest(advertisement: ByteArray): ByteArray = advertisement.copyOfRange(2, advertisement.size)
}

/**
 * Proves both ends of a link hold the room key, over fresh nonces.
 *
 * The old handshake was the advertisement's two tag bytes, which every scanner in range
 * can read, so anyone could replay them and be taken for a member. Now the central sends
 * a random challenge, the peripheral answers with its own nonce and a MAC over both, and
 * the central confirms with a MAC under a different label, so neither answer can be
 * reflected back as the other. Every frame fits the 20 bytes a link at the default MTU
 * carries.
 */
object SharedBuysHandshake {

    const val CHALLENGE_MAGIC: Byte = 0x03
    const val RESPONSE_MAGIC: Byte = 0x04
    const val CONFIRM_MAGIC: Byte = 0x05
    const val NONCE_LENGTH = 8
    const val MAC_LENGTH = 8

    sealed interface Frame {
        class Challenge(val nonce: ByteArray) : Frame
        class Response(val nonce: ByteArray, val mac: ByteArray) : Frame
        class Confirm(val mac: ByteArray) : Frame
    }

    fun key(sessionKey: ByteArray): ByteArray =
        SharedBuysCrypto.derive(SharedBuysCrypto.HANDSHAKE_INFO, sessionKey)

    fun nonce(): ByteArray = SharedBuysCrypto.randomNonce(NONCE_LENGTH)

    fun challenge(nonce: ByteArray): ByteArray = byteArrayOf(CHALLENGE_MAGIC) + nonce

    fun response(challenge: ByteArray, nonce: ByteArray, key: ByteArray): ByteArray =
        byteArrayOf(RESPONSE_MAGIC) + nonce + mac("resp", challenge, nonce, key)

    fun confirm(challenge: ByteArray, response: ByteArray, key: ByteArray): ByteArray =
        byteArrayOf(CONFIRM_MAGIC) + mac("conf", challenge, response, key)

    fun verifiesResponse(mac: ByteArray, challenge: ByteArray, response: ByteArray, key: ByteArray): Boolean =
        java.security.MessageDigest.isEqual(mac, mac("resp", challenge, response, key))

    fun verifiesConfirm(mac: ByteArray, challenge: ByteArray, response: ByteArray, key: ByteArray): Boolean =
        java.security.MessageDigest.isEqual(mac, mac("conf", challenge, response, key))

    /** Reads a handshake frame, told apart from chunk frames (0x01) by first byte and exact length. */
    fun parse(frame: ByteArray): Frame? {
        if (frame.isEmpty()) return null
        return when {
            frame[0] == CHALLENGE_MAGIC && frame.size == 1 + NONCE_LENGTH ->
                Frame.Challenge(frame.copyOfRange(1, frame.size))
            frame[0] == RESPONSE_MAGIC && frame.size == 1 + NONCE_LENGTH + MAC_LENGTH ->
                Frame.Response(
                    frame.copyOfRange(1, 1 + NONCE_LENGTH),
                    frame.copyOfRange(1 + NONCE_LENGTH, frame.size)
                )
            frame[0] == CONFIRM_MAGIC && frame.size == 1 + MAC_LENGTH ->
                Frame.Confirm(frame.copyOfRange(1, frame.size))
            else -> null
        }
    }

    private fun mac(label: String, challenge: ByteArray, response: ByteArray, key: ByteArray): ByteArray =
        SharedBuysCrypto.hmac(key, label.toByteArray() + challenge + response).copyOf(MAC_LENGTH)
}

object SharedBuysDigest {

    fun value(vector: Map<String, Long>): UInt {
        var hash = 2166136261u
        for (key in vector.keys.sorted()) {
            for (byte in key.toByteArray()) {
                hash = (hash xor (byte.toUByte().toUInt())) * 16777619u
            }
            val seq = (vector[key] ?: 0L).toUInt()
            for (shift in 0 until 32 step 8) {
                hash = (hash xor ((seq shr shift) and 0xFFu)) * 16777619u
            }
        }
        return hash
    }

    fun bytes(vector: Map<String, Long>): ByteArray {
        val hash = value(vector)
        return byteArrayOf(
            ((hash shr 24) and 0xFFu).toByte(),
            ((hash shr 16) and 0xFFu).toByte(),
            ((hash shr 8) and 0xFFu).toByte(),
            (hash and 0xFFu).toByte()
        )
    }
}

object SharedBuysFraming {

    /**
     * Splits a payload into chunks that fit limit bytes of body each.
     *
     * limit comes from what the link actually negotiated, not from a constant: on a
     * connection stuck at the 23 byte default MTU, a 160 byte chunk was truncated to 20
     * bytes on the wire, the 4 byte header still parsed, reassembly "succeeded", and the
     * result was corrupt ciphertext with nothing to point at.
     */
    fun chunks(
        payload: ByteArray,
        messageId: Byte,
        limit: Int = SharedBuysProfile.MAX_PAYLOAD_PER_CHUNK
    ): List<ByteArray> {
        if (payload.isEmpty() || limit <= 0) return emptyList()
        val slices = payload.toList().chunked(limit)
        // The chunk index and count are single bytes, so a message needing more than 255
        // chunks cannot be described by this header at all. Sending it anyway wrapped
        // the index and spliced unrelated chunks together on the far side.
        if (slices.size > 255) return emptyList()
        val count = slices.size.toByte()
        return slices.mapIndexed { index, slice ->
            ByteBuffer.allocate(4 + slice.size)
                .put(SharedBuysProfile.FRAME_MAGIC)
                .put(messageId)
                .put(index.toByte())
                .put(count)
                .put(slice.toByteArray())
                .array()
        }
    }

    /**
     * Partial messages, held until every chunk of one arrives.
     *
     * The message id is a byte, so it wraps every 256 sends and a partial message can
     * meet a later, unrelated one under the same id. Buffers are therefore bounded and
     * expiring: a partial that never completes cannot survive to corrupt a reuse of its
     * id, and a peer that walks out of range mid-message cannot leak memory.
     */
    class Reassembler {
        private class Partial(val count: Int) {
            val parts = mutableMapOf<Int, ByteArray>()
            var touched = 0L
        }

        private val buffers = mutableMapOf<Byte, Partial>()

        fun accept(frame: ByteArray, now: Long = System.currentTimeMillis()): ByteArray? {
            if (frame.size <= 4 || frame[0] != SharedBuysProfile.FRAME_MAGIC) return null
            val messageId = frame[1]
            val index = frame[2].toUByte().toInt()
            val count = frame[3].toUByte().toInt()
            if (count == 0 || index >= count) return null

            buffers.entries.removeAll { now - it.value.touched >= LIFETIME_MS }
            // A different chunk count under a known id means the id was reused rather
            // than continued, so the old parts are stale.
            var partial = buffers[messageId]
            if (partial == null || partial.count != count) {
                partial = Partial(count)
                buffers[messageId] = partial
            }
            partial.parts[index] = frame.copyOfRange(4, frame.size)
            partial.touched = now

            if (partial.parts.size != count) {
                if (buffers.size > MAX_PARTIALS) {
                    buffers.minByOrNull { it.value.touched }?.let { buffers.remove(it.key) }
                }
                return null
            }
            buffers.remove(messageId)
            val output = ByteArray(partial.parts.values.sumOf { it.size })
            var at = 0
            for (position in 0 until count) {
                val part = partial.parts[position] ?: return null
                part.copyInto(output, at)
                at += part.size
            }
            return output
        }

        companion object {
            const val MAX_PARTIALS = 4
            const val LIFETIME_MS = 10_000L
        }
    }
}
