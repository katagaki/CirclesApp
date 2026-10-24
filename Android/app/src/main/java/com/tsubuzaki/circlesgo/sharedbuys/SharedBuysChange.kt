package com.tsubuzaki.circlesgo.sharedbuys

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

object SharedBuyKind {
    const val ADD_ITEM = 0
    const val SET_STATUS = 1
    const val SET_ASSIGNEE = 2
    const val SET_COST = 3
    const val REMOVE_ITEM = 4
    const val MEMBER_JOINED = 5
    const val RENAME_ITEM = 6

    /**
     * Circle name and space, relayed once per circle so a member without the catalog
     * database can still read the list.
     *
     * A guest joins by scanning a code and never downloads the catalog, so
     * database.circles() returns nothing and every section header would read
     * "Unknown circle 12345". The contributor who first adds an item from a circle
     * carries that circle's name and space into the log alongside it, so the guest
     * reads the header off the log instead. Sent once per circle per room.
     */
    const val CIRCLE_INFO = 7
    const val MEMBER_KEY = 8
    const val REKEY = 9

    /**
     * Whether this kind is carried over the peer-to-peer Bluetooth path.
     *
     * Bluetooth frames are chunked at 160 bytes and reassembled by hand, so the
     * transport is only dependable for small, self-contained payloads. Item names,
     * costs and images travel over the relay exclusively; on-site we only exchange
     * status flips, which is what makes the list useful while walking a venue.
     */
    fun travelsOverBluetooth(kind: Int): Boolean = kind == SET_STATUS

    /**
     * Whether this build can interpret the kind at all.
     *
     * An unknown kind is folded as a no-op on both platforms. Without this it was parked
     * in the deferred map instead, waiting for an addItem that would never make it
     * applicable, and the map grew for the life of the session.
     */
    fun isKnown(kind: Int): Boolean = kind in ADD_ITEM..REKEY
}

object SharedBuyStatus {
    const val PENDING = 0
    const val BOUGHT = 1
    const val CANCELLED = 2

    fun next(status: Int): Int = when (status) {
        PENDING -> BOUGHT
        BOUGHT -> CANCELLED
        else -> PENDING
    }
}

@Serializable
data class SharedBuyPayload(
    @SerialName("a") val actor: Int,
    @SerialName("k") val kind: Int,
    @SerialName("i") val itemId: String,
    @SerialName("c") val circleId: Int,
    @SerialName("t") val text: String? = null,
    @SerialName("v") val value: Int? = null,
    /**
     * The circle's space, as spaceName() renders it. Only CIRCLE_INFO sets it.
     *
     * A separate field rather than a delimiter inside text: a circle name is
     * user-supplied and may contain anything, so any separator would eventually be part
     * of a name. Optional, so it costs nothing on the other six kinds -- explicitNulls
     * is off, so nil is omitted rather than encoded as null.
     */
    @SerialName("s") val space: String? = null,
    /**
     * The Lamport clock the change was written at, which is what orders the fold.
     *
     * Bumping seq to act as the clock left holes in each device's own numbering, so the
     * gapless prefix the relay and Bluetooth sync by stopped at the first jump and every
     * reconnect fetched almost the whole room again. seq now counts only this device's
     * changes. Absent on changes written before the split, which order by seq as they
     * always did.
     */
    @SerialName("l") val clock: Long? = null,
    /**
     * The author's Ed25519 public key, base64url. Only MEMBER_JOINED carries it.
     *
     * A device's first MEMBER_JOINED pins its key for the rest of the room: every later
     * record from that device must carry a signature the key verifies, so a member
     * holding the room key can no longer write as somebody else's device.
     */
    @SerialName("p") val publicKey: String? = null,
    /**
     * Ed25519 over SharedBuysCrypto.signInput, base64url. Absent from older builds, whose
     * devices stay unsigned for the life of the room.
     */
    @SerialName("g") val signature: String? = null
)

@Serializable
data class SharedBuyChange(
    val device: String,
    val seq: Long,
    val payload: SharedBuyPayload
) {
    val id: String get() = "$device#$seq"

    /** Where the change sits in the fold. */
    val order: Long get() = payload.clock ?: seq
}

/** A circle as the shared log describes it, for a member who cannot look it up. */
data class SharedBuyCircle(
    val id: Int,
    val name: String,
    val space: String?
)

data class SharedBuyItem(
    val id: String,
    val circleId: Int,
    val name: String,
    val cost: Int,
    val status: Int,
    val assignee: Int?,
    val isRemoved: Boolean,
    val lastTouchedBy: Int
)

object SharedBuyFold {

    fun items(changes: List<SharedBuyChange>): List<SharedBuyItem> {
        val byId = mutableMapOf<String, SharedBuyItem>()
        val order = mutableListOf<String>()
        val deferred = mutableMapOf<String, MutableList<SharedBuyChange>>()

        for (change in changes.sortedWith(compareBy({ it.order }, { it.device }))) {
            val payload = change.payload
            when {
                payload.kind == SharedBuyKind.ADD_ITEM -> {
                    if (!byId.containsKey(payload.itemId)) order.add(payload.itemId)
                    byId[payload.itemId] = SharedBuyItem(
                        id = payload.itemId,
                        circleId = payload.circleId,
                        name = payload.text.orEmpty(),
                        cost = payload.value ?: 0,
                        status = SharedBuyStatus.PENDING,
                        assignee = null,
                        isRemoved = false,
                        lastTouchedBy = payload.actor
                    )
                    // A mutation can land before the addItem it targets: Bluetooth carries
                    // status flips but never the item itself, so a peer can learn that
                    // something was bought before the relay delivers what it is. Replay
                    // whatever was parked on this item, in the same order it was folded.
                    deferred.remove(payload.itemId)?.forEach { apply(it, byId) }
                }
                // Log metadata, not an item mutation. Without this they fall through to
                // the deferred branch and are parked against an itemId that never arrives.
                payload.kind == SharedBuyKind.MEMBER_JOINED -> Unit
                payload.kind == SharedBuyKind.CIRCLE_INFO -> Unit
                payload.kind == SharedBuyKind.MEMBER_KEY -> Unit
                payload.kind == SharedBuyKind.REKEY -> Unit
                !SharedBuyKind.isKnown(payload.kind) -> Unit
                !byId.containsKey(payload.itemId) ->
                    deferred.getOrPut(payload.itemId) { mutableListOf() }.add(change)
                else -> apply(change, byId)
            }
        }
        return order.mapNotNull { byId[it] }.filter { !it.isRemoved }
    }

    private fun apply(change: SharedBuyChange, byId: MutableMap<String, SharedBuyItem>) {
        val payload = change.payload
        val current = byId[payload.itemId] ?: return
        byId[payload.itemId] = when (payload.kind) {
            SharedBuyKind.SET_STATUS -> current.copy(
                status = payload.value ?: SharedBuyStatus.PENDING,
                lastTouchedBy = payload.actor
            )
            SharedBuyKind.SET_ASSIGNEE ->
                current.copy(assignee = payload.value, lastTouchedBy = payload.actor)
            SharedBuyKind.SET_COST ->
                current.copy(cost = payload.value ?: 0, lastTouchedBy = payload.actor)
            SharedBuyKind.RENAME_ITEM ->
                current.copy(name = payload.text.orEmpty(), lastTouchedBy = payload.actor)
            SharedBuyKind.REMOVE_ITEM -> current.copy(isRemoved = true)
            else -> return
        }
    }

    /**
     * Circle name and space per circle ID, as the log carries them.
     *
     * Only ever a fallback for a member holding the catalog database, which is both
     * richer and current; for a guest it is the only source there is.
     */
    fun circles(changes: List<SharedBuyChange>): Map<Int, SharedBuyCircle> {
        val result = mutableMapOf<Int, SharedBuyCircle>()
        for (change in changes.sortedWith(compareBy({ it.order }, { it.device }))) {
            if (change.payload.kind == SharedBuyKind.CIRCLE_INFO) {
                result[change.payload.circleId] = SharedBuyCircle(
                    id = change.payload.circleId,
                    name = change.payload.text.orEmpty(),
                    space = change.payload.space
                )
            }
        }
        return result
    }

    fun memberKeys(changes: List<SharedBuyChange>): Map<String, ByteArray> {
        val result = mutableMapOf<String, ByteArray>()
        for (change in changes.sortedBy { it.seq }) {
            if (change.payload.kind != SharedBuyKind.MEMBER_KEY) continue
            val key = runCatching { change.payload.text?.fromBase64Url() }.getOrNull() ?: continue
            result[change.device] = key
        }
        return result
    }

    fun deviceActors(changes: List<SharedBuyChange>): Map<String, Int> {
        val result = mutableMapOf<String, Int>()
        for (change in changes.sortedBy { it.seq }) {
            if (change.payload.kind == SharedBuyKind.MEMBER_JOINED) {
                result.putIfAbsent(change.device, change.payload.actor)
            }
        }
        return result
    }

    fun members(changes: List<SharedBuyChange>): Map<Int, String> {
        val result = mutableMapOf<Int, String>()
        for (change in changes.sortedWith(compareBy({ it.order }, { it.device }))) {
            if (change.payload.kind == SharedBuyKind.MEMBER_JOINED) {
                result[change.payload.actor] = change.payload.text.orEmpty()
            }
        }
        return result
    }
}
