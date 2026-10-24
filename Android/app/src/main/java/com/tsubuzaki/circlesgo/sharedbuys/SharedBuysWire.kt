package com.tsubuzaki.circlesgo.sharedbuys

import java.nio.ByteBuffer

sealed interface SharedBuysFrame {
    data class Changes(val records: List<RelayRecord>) : SharedBuysFrame
    data class Want(val vector: Map<String, Long>) : SharedBuysFrame
}

/**
 * The binary frame both apps speak over Bluetooth.
 *
 * `version ‖ type ‖ count`, then a body per type. Records carry the same sealed blob
 * the relay stores, so `(device, seq)` dedup stays transport-agnostic. JSON cost 163
 * bytes for a single status flip — two chunks — where this costs 97.
 */
object SharedBuysWire {

    const val VERSION: Byte = 0x01
    const val CHANGES_TYPE: Byte = 0x01
    const val WANT_TYPE: Byte = 0x02
    const val HEADER_LENGTH = 3
    const val DEVICE_LENGTH = 4
    const val WANT_ENTRY_LENGTH = 12

    /** Frames holding the records, packed so each one still fits a single chunk. */
    fun changeFrames(records: List<RelayRecord>): List<ByteArray> =
        pack(records.mapNotNull { body(it) }, CHANGES_TYPE)

    /**
     * Frames holding the version vector, packed so each one still fits a single chunk.
     *
     * An empty vector is still one frame, count 0, meaning "send me everything": packing
     * nothing produced no frame at all, and a peer holding nothing never asked.
     */
    fun wantFrames(vector: Map<String, Long>): List<ByteArray> {
        val bodies = vector.entries.sortedBy { it.key }.mapNotNull { entry ->
            val device = runCatching { entry.key.fromHex() }.getOrNull()
            if (device == null || device.size != DEVICE_LENGTH || entry.value <= 0L) {
                null
            } else {
                ByteBuffer.allocate(WANT_ENTRY_LENGTH).put(device).putLong(entry.value).array()
            }
        }
        if (bodies.isEmpty()) return listOf(byteArrayOf(VERSION, WANT_TYPE, 0))
        return pack(bodies, WANT_TYPE)
    }

    private fun body(record: RelayRecord): ByteArray? = runCatching {
        val device = record.device.fromHex()
        val blob = record.blob.fromBase64Url()
        val tag = record.tag.fromBase64Url()
        if (device.size != DEVICE_LENGTH || record.seq <= 0L) return null
        if (blob.size <= SharedBuysCrypto.TAG_LENGTH || blob.size > 0xFFFF) return null
        if (tag.size != SharedBuysCrypto.TAG_LENGTH) return null
        ByteBuffer.allocate(DEVICE_LENGTH + 8 + 2 + blob.size + tag.size)
            .put(device)
            .putLong(record.seq)
            .putShort(blob.size.toShort())
            .put(blob)
            .put(tag)
            .array()
    }.getOrNull()

    /**
     * A record spanning more than one chunk still gets its own frame: the chunk layer
     * splits it, rather than the body being silently dropped.
     */
    private fun pack(bodies: List<ByteArray>, type: Byte): List<ByteArray> {
        val limit = SharedBuysProfile.MAX_PAYLOAD_PER_CHUNK - HEADER_LENGTH
        val frames = mutableListOf<ByteArray>()
        var group = mutableListOf<ByteArray>()
        var size = 0

        fun flush() {
            if (group.isEmpty()) return
            val buffer = ByteBuffer.allocate(HEADER_LENGTH + size)
                .put(VERSION)
                .put(type)
                .put(group.size.toByte())
            group.forEach { buffer.put(it) }
            frames.add(buffer.array())
            group = mutableListOf()
            size = 0
        }

        for (body in bodies) {
            if (group.isNotEmpty() && (size + body.size > limit || group.size == 255)) flush()
            group.add(body)
            size += body.size
        }
        flush()
        return frames
    }

    fun decode(payload: ByteArray): SharedBuysFrame? {
        // A frame of another version is skipped, not parsed: the layout behind the
        // header is what changes, so guessing at it would fold garbage into the log.
        if (payload.size < HEADER_LENGTH || payload[0] != VERSION) return null
        val count = payload[2].toUByte().toInt()
        return when (payload[1]) {
            CHANGES_TYPE -> changes(payload, count)
            WANT_TYPE -> want(payload, count)
            else -> null
        }
    }

    private fun changes(payload: ByteArray, count: Int): SharedBuysFrame? {
        val records = mutableListOf<RelayRecord>()
        var offset = HEADER_LENGTH
        repeat(count) {
            if (offset + DEVICE_LENGTH + 8 + 2 > payload.size) return null
            val device = payload.copyOfRange(offset, offset + DEVICE_LENGTH).toHex()
            offset += DEVICE_LENGTH
            val seq = sequence(payload, offset) ?: return null
            offset += 8
            val blobLength =
                (payload[offset].toUByte().toInt() shl 8) or payload[offset + 1].toUByte().toInt()
            offset += 2
            // The length is a peer's claim about a buffer we hold: check it against
            // what is actually left before slicing.
            if (blobLength <= SharedBuysCrypto.TAG_LENGTH) return null
            if (offset + blobLength + SharedBuysCrypto.TAG_LENGTH > payload.size) return null
            val blob = payload.copyOfRange(offset, offset + blobLength)
            offset += blobLength
            val tag = payload.copyOfRange(offset, offset + SharedBuysCrypto.TAG_LENGTH)
            offset += SharedBuysCrypto.TAG_LENGTH
            records.add(RelayRecord(device, seq, blob.toBase64Url(), tag.toBase64Url()))
        }
        return SharedBuysFrame.Changes(records)
    }

    private fun want(payload: ByteArray, count: Int): SharedBuysFrame? {
        val vector = mutableMapOf<String, Long>()
        var offset = HEADER_LENGTH
        repeat(count) {
            if (offset + WANT_ENTRY_LENGTH > payload.size) return null
            val device = payload.copyOfRange(offset, offset + DEVICE_LENGTH).toHex()
            val seq = sequence(payload, offset + DEVICE_LENGTH) ?: return null
            vector[device] = maxOf(vector[device] ?: 0L, seq)
            offset += WANT_ENTRY_LENGTH
        }
        return SharedBuysFrame.Want(vector)
    }

    private fun sequence(payload: ByteArray, offset: Int): Long? {
        if (offset + 8 > payload.size) return null
        var value = 0L
        for (index in 0 until 8) {
            value = (value shl 8) or payload[offset + index].toUByte().toLong()
        }
        // Anything past 2^63-1 arrives negative, which no counter of ours produced.
        return if (value > 0L) value else null
    }
}
