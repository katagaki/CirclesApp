package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import android.net.Uri
import com.tsubuzaki.circlesgo.R
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.Json
import java.util.UUID

class SharedBuysSession(private val context: Context, private val scope: CoroutineScope) {

    private val store = SharedBuysStore(context)
    private val relay = SharedBuysRelay(context, scope)
    private val bluetooth = SharedBuysBluetooth(context)
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false }

    var status by mutableStateOf("idle")
        private set
    var relayBaseUrl by mutableStateOf(SharedBuysRelays.baseUrl(context))
    var actorPid by mutableStateOf(0)
    var nickname by mutableStateOf("")

    /**
     * Whether this device is running as a guest.
     *
     * A guest has no circle.ms account and no catalog database: they scanned a room code
     * to help tick things off, and that is all they can do. append() honours this by
     * dropping every kind but a status flip. It is not enforceable -- a guest holds the
     * room key, so a modified client could write anything the relay accepts -- it is this
     * app keeping to the role it advertised.
     */
    var isGuest by mutableStateOf(false)
        private set
    var isDebugVisible by mutableStateOf(false)
    var bluetoothPeers by mutableStateOf(0)
        private set
    var isBluetoothEnabled by mutableStateOf(true)

    /** Fires whenever the folded list moves, so the Live Update can follow it. */
    var onChanged: (() -> Unit)? = null

    val log = mutableStateListOf<String>()
    val changes = mutableStateListOf<SharedBuyChange>()

    var sessionKey: ByteArray? by mutableStateOf(null)
        private set
    var deviceId by mutableStateOf("")
        private set
    private var deviceAuthKey = SharedBuysCrypto.newDeviceAuthKey()
    private var agreementKey = SharedBuysCrypto.newAgreementKey()
    var ownerDevice: String? by mutableStateOf(null)
        private set
    private var isRekeying = false
    private var signingKey = SharedBuysCrypto.newSigningKey()
    private var eventNumber = 0
    private var lastSeq = 0L
    private var clock = 0L
    private var reconnectAttempt = 0
    private var reconnectJob: kotlinx.coroutines.Job? = null
    private val outbox = mutableListOf<RelayRecord>()
    private var pendingWrite: PendingWrite? = null
    private var writeJob: kotlinx.coroutines.Job? = null
    /** Links we have already sent a want down, so each asks at most once. */
    private val wantedPeers = mutableSetOf<BluetoothPeer>()
    private val sealed = mutableMapOf<String, RelayRecord>()
    private var keyCache: Pair<ByteArray, SharedBuysKeys>? = null
    private var flushJob: kotlinx.coroutines.Job? = null
    /**
     * Batches are opened one at a time, so a device's MEMBER_JOINED is adopted before the
     * records it signs are checked.
     */
    private val ingestLock = kotlinx.coroutines.sync.Mutex()

    val isActive: Boolean get() = sessionKey != null

    val isOwner: Boolean get() = ownerDevice != null && ownerDevice == deviceId

    val canRotateKey: Boolean get() = isOwner && status == "connected"

    val roomId: String? get() = sessionKey?.let { SharedBuysCrypto.roomId(it) }

    /**
     * The fold of the log, kept until the log changes underneath it.
     *
     * items and members were recomputed on every read — per row, per circle, and again
     * inside yourShare and groupTotal — which sorted and folded the whole log well over a
     * hundred times per frame. foldVersion is the observable the getters read, so Compose
     * still recomposes when the log moves.
     */
    private var foldVersion by mutableStateOf(0)
    private var cachedItems: List<SharedBuyItem> = emptyList()
    private var cachedItemsVersion = -1
    private var cachedMembers: Map<Int, String> = emptyMap()
    private var cachedMembersVersion = -1
    private var cachedCircles: Map<Int, SharedBuyCircle> = emptyMap()
    private var cachedCirclesVersion = -1

    private fun invalidateFold() {
        foldVersion += 1
        onChanged?.invoke()
    }

    val items: List<SharedBuyItem>
        get() {
            val version = foldVersion
            if (cachedItemsVersion != version) {
                cachedItems = SharedBuyFold.items(changes)
                cachedItemsVersion = version
            }
            return cachedItems
        }

    val yourShare: Int
        get() = items.filter { it.assignee == actorPid && it.status != SharedBuyStatus.CANCELLED }
            .sumOf { it.cost }

    val groupTotal: Int
        get() = items.filter { it.status != SharedBuyStatus.CANCELLED }.sumOf { it.cost }

    val hasUnsentChanges: Boolean
        get() = status != "connected" && bluetoothPeers == 0 && changes.isNotEmpty()

    val members: Map<Int, String>
        get() {
            val version = foldVersion
            if (cachedMembersVersion != version) {
                cachedMembers = SharedBuyFold.members(changes)
                cachedMembersVersion = version
            }
            return cachedMembers
        }

    /**
     * Circle name and space as the log carries them, for a member with no catalog.
     *
     * Read per section header, so it is cached on foldVersion like items and members.
     */
    val circles: Map<Int, SharedBuyCircle>
        get() {
            val version = foldVersion
            if (cachedCirclesVersion != version) {
                cachedCircles = SharedBuyFold.circles(changes)
                cachedCirclesVersion = version
            }
            return cachedCircles
        }

    val joinUrl: String?
        get() = sessionKey?.let {
            "circles-app://$JOIN_HOST?v=1&e=$eventNumber&k=${it.toBase64Url()}" +
                (ownerDevice?.let { owner -> "&o=$owner" } ?: "")
        }

    /**
     * What we hold with no gap in it, per device.
     *
     * A vector of max(seq) claims everything below the highest sequence number we have
     * seen, so a change learned out of order — over Bluetooth, or from a peer's backlog
     * — buries whatever is still missing underneath it, and the relay withholds the gap
     * forever. The contiguous prefix claims only what is actually complete; anything
     * above a hole is sent again and deduped on ingest.
     */
    private val versionVector: Map<String, Long>
        get() = contiguousPrefix(changes)

    /**
     * What the advertised digest summarises: everything held over Bluetooth, gaps and
     * all.
     *
     * The digest answers "is there anything to exchange at all", so it has to count a
     * change sitting above a hole. The vector we send answers "what may you skip", and
     * must not.
     */
    private val bluetoothDigestVector: Map<String, Long>
        get() = changes.filter { SharedBuyKind.travelsOverBluetooth(it.payload.kind) }
            .groupBy { it.device }
            .mapValues { entry -> entry.value.maxOf { it.seq } }

    /**
     * The highest n for which every sequence number from 1 to n is present. A device we
     * hold nothing contiguous for is left out rather than claimed at 0.
     */
    private fun contiguousPrefix(changes: List<SharedBuyChange>): Map<String, Long> =
        changes.groupBy { it.device }.mapNotNull { entry ->
            val held = entry.value.mapTo(mutableSetOf()) { it.seq }
            var next = 1L
            while (held.contains(next)) next += 1
            if (next > 1L) entry.key to next - 1 else null
        }.toMap()

    fun adoptIdentity() {
        val preferences = context.getSharedPreferences("circles", Context.MODE_PRIVATE)
        isGuest = preferences.getBoolean(GUEST_MODE_KEY, false)
        // A guest has no circle.ms identity to adopt, and the WebCatalog nickname of
        // whoever used this phone before them is not theirs to wear.
        if (isGuest) {
            actorPid = localActorId()
            nickname = guestNickname()
            return
        }
        val storedPid = preferences.getInt("My.LastKnownPID", 0)
        val storedNickname = preferences.getString("My.LastKnownNickname", null)
        actorPid = if (storedPid != 0) storedPid else localActorId()
        if (!storedNickname.isNullOrEmpty()) nickname = storedNickname
        if (nickname.isEmpty()) nickname = context.getString(R.string.buys_shared_you)
    }

    /**
     * The guest's minted name, kept so the same phone is the same member across
     * relaunches and across rooms.
     */
    private fun guestNickname(): String {
        val preferences = context.getSharedPreferences("circles", Context.MODE_PRIVATE)
        val existing = preferences.getString(GUEST_NICKNAME_KEY, null)
        if (!existing.isNullOrEmpty()) return existing
        val minted = SharedBuysGuestName.generate()
        preferences.edit().putString(GUEST_NICKNAME_KEY, minted).apply()
        return minted
    }

    /**
     * Enters Guest Mode. Survives relaunch, so the app comes back into the guest shell
     * rather than the login screen.
     */
    fun enterGuestMode() {
        context.getSharedPreferences("circles", Context.MODE_PRIVATE)
            .edit().putBoolean(GUEST_MODE_KEY, true).apply()
        adoptIdentity()
    }

    /**
     * Leaves Guest Mode and the room with it.
     *
     * The minted name is dropped too: coming back as a guest later is a new session with
     * a new member, not a resumption of the old one.
     */
    fun exitGuestMode() {
        leave()
        context.getSharedPreferences("circles", Context.MODE_PRIVATE)
            .edit().remove(GUEST_MODE_KEY).remove(GUEST_NICKNAME_KEY).apply()
        isGuest = false
        nickname = ""
    }

    /**
     * A stable stand-in identity for someone who is not signed in.
     *
     * Leaving actorPid at 0 made every signed-out member the same actor: members collapsed
     * to a single entry, every item looked assigned to you, and yourShare equalled
     * groupTotal on both phones. Negative so it cannot collide with a real circle.ms PID,
     * and stored so it survives relaunches.
     */
    private fun localActorId(): Int {
        val preferences = context.getSharedPreferences("circles", Context.MODE_PRIVATE)
        val existing = preferences.getInt("My.LocalActorID", 0)
        if (existing != 0) return existing
        val minted = -(1 + kotlin.random.Random.nextInt(Int.MAX_VALUE))
        preferences.edit().putInt("My.LocalActorID", minted).apply()
        return minted
    }

    fun restore() {
        adoptIdentity()
        val snapshot = store.load() ?: return
        sessionKey = snapshot.sessionKey.fromBase64Url()
        deviceId = snapshot.deviceId
        deviceAuthKey = snapshot.deviceAuthKey?.fromBase64Url() ?: SharedBuysCrypto.newDeviceAuthKey()
        agreementKey = runCatching {
            java.security.KeyPair(
                SharedBuysCrypto.agreementPublicKey(snapshot.agreementPublicKey!!.fromBase64Url()),
                SharedBuysCrypto.privateKey(snapshot.agreementKey!!.fromBase64Url())
            )
        }.getOrElse { SharedBuysCrypto.newAgreementKey() }
        ownerDevice = snapshot.ownerDevice
        signingKey = snapshot.signingKey?.fromBase64Url() ?: SharedBuysCrypto.newSigningKey()
        eventNumber = snapshot.eventNumber
        lastSeq = snapshot.lastSeq
        changes.clear()
        sealed.clear()
        changes.addAll(snapshot.changes)
        clock = snapshot.clock ?: (changes.maxOfOrNull { it.order } ?: 0L)
        invalidateFold()
        val announced = SharedBuyFold.memberKeys(changes)[deviceId]
        if (announced?.contentEquals(SharedBuysCrypto.publicKeyBytes(agreementKey.public)) != true) {
            announceAgreementKey()
        }
        note("restored room $roomId as $deviceId")
        SharedBuysLiveUpdateService.start(context)
        // A restored session reported isActive but had no transport behind it: the relay
        // was never reconnected and Bluetooth never started, so the room was dead until
        // the user left and rejoined.
        connect()
        startBluetooth()
    }

    /**
     * Brings the transports back after the process, or the user, went away.
     *
     * Safe to call repeatedly: connect() cancels any pending reconnect before dialling,
     * and startBluetooth() no-ops without a session key or the permissions.
     */
    fun resume() {
        if (!isActive) return
        connect()
        startBluetooth()
    }

    /** Releases the radio and the socket without ending the session. */
    fun pause() {
        stopBluetooth()
        relay.disconnect()
    }

    /** Everything this session holds, for an activity that is going away for good. */
    fun close() {
        reconnectJob?.cancel()
        reconnectJob = null
        flushJob?.cancel()
        flushJob = null
        bluetooth.stop()
        relay.close()
    }

    fun start(eventNumber: Int, nickname: String) {
        val device = SharedBuysCrypto.newDeviceId()
        enter(SharedBuysCrypto.newSessionKey(), device, device, eventNumber, nickname)
        note("started room $roomId as $deviceId")
        SharedBuysLiveUpdateService.start(context)
        connect()
        startBluetooth()
    }

    fun join(uri: Uri, nickname: String) {
        val raw = uri.getQueryParameter("k") ?: return note("bad join link")
        val key = runCatching { raw.fromBase64Url() }.getOrNull()
        if (key == null || key.size != 32) return note("bad join link")
        val owner = uri.getQueryParameter("o")?.takeIf { it.matches(Regex("^[0-9a-f]{8}$")) }
        // Joining a second room is leaving the first.
        if (isActive) leave()
        val event = uri.getQueryParameter("e")?.toIntOrNull() ?: 0
        enter(key, SharedBuysCrypto.newDeviceId(), owner, event, nickname)
        note("joined room $roomId as $deviceId")
        SharedBuysLiveUpdateService.start(context)
        connect()
        startBluetooth()
    }

    private fun enter(key: ByteArray, device: String, owner: String?, event: Int, nickname: String) {
        sessionKey = key
        deviceId = device
        deviceAuthKey = SharedBuysCrypto.newDeviceAuthKey()
        agreementKey = SharedBuysCrypto.newAgreementKey()
        ownerDevice = owner
        eventNumber = event
        signingKey = SharedBuysCrypto.newSigningKey()
        lastSeq = 0
        clock = 0
        changes.clear()
        sealed.clear()
        invalidateFold()
        persist()
        append(SharedBuyKind.MEMBER_JOINED, "-", 0, nickname, actorPid)
        announceAgreementKey()
    }

    private fun announceAgreementKey() {
        val publicKey = SharedBuysCrypto.publicKeyBytes(agreementKey.public).toBase64Url()
        append(SharedBuyKind.MEMBER_KEY, "-", 0, publicKey, null)
    }

    fun rotateKey(removing: Int? = null) {
        if (!canRotateKey) return
        val key = sessionKey ?: return
        val room = roomId ?: return
        val actors = SharedBuyFold.deviceActors(changes)
        val recipients = SharedBuyFold.memberKeys(changes).filter { (device, _) ->
            device != deviceId && (removing == null || actors[device] != removing)
        }
        val newKey = SharedBuysCrypto.newSessionKey()
        val newDevice = SharedBuysCrypto.newDeviceId()
        val carriedItems = items
        val carriedMembers = members
        val carriedCircles = circles
        isRekeying = true
        val records = recipients.entries.sortedBy { it.key }.mapNotNull { (device, publicKey) ->
            val box = runCatching {
                SharedBuysCrypto.sealRekey(newKey, newDevice, publicKey, room, device)
            }.getOrNull() ?: return@mapNotNull null
            append(SharedBuyKind.REKEY, device, 0, box.toBase64Url(), null)?.let { seal(it, key, room) }
        }
        migrate(newKey, newDevice, newDevice, records)
        val kept = recipients.keys.mapNotNull { actors[it] }.toSet()
        carriedMembers.entries.sortedBy { it.key }
            .filter { it.key != actorPid && it.key in kept }
            .forEach { append(SharedBuyKind.MEMBER_JOINED, "-", 0, it.value, it.key, actor = it.key) }
        carriedCircles.values.sortedBy { it.id }.forEach {
            append(SharedBuyKind.CIRCLE_INFO, "-", it.id, it.name, null, it.space)
        }
        carriedItems.forEach { item ->
            val actor = item.lastTouchedBy
            append(SharedBuyKind.ADD_ITEM, item.id, item.circleId, item.name, item.cost, actor = actor)
            if (item.status != SharedBuyStatus.PENDING) {
                append(SharedBuyKind.SET_STATUS, item.id, item.circleId, null, item.status, actor = actor)
            }
            item.assignee?.let {
                append(SharedBuyKind.SET_ASSIGNEE, item.id, item.circleId, null, it, actor = actor)
            }
        }
        isRekeying = false
        note("re-keyed ${records.size} members into room $roomId")
        connect()
        startBluetooth()
    }

    private fun followRekeys(added: List<SharedBuyChange>) {
        val owner = ownerDevice ?: return
        if (isOwner) return
        val rekey = added.firstOrNull {
            it.payload.kind == SharedBuyKind.REKEY && it.payload.itemId == deviceId && it.device == owner
        } ?: return
        val room = roomId ?: return
        val opened = runCatching {
            SharedBuysCrypto.openRekey(rekey.payload.text!!.fromBase64Url(), agreementKey.private, room, deviceId)
        }.getOrNull() ?: return note("could not open re-key")
        isRekeying = true
        migrate(opened.first, SharedBuysCrypto.newDeviceId(), opened.second)
        isRekeying = false
        note("followed re-key into room $roomId")
        connect()
        startBluetooth()
    }

    private fun migrate(key: ByteArray, device: String, owner: String, records: List<RelayRecord> = emptyList()) {
        reconnectJob?.cancel()
        reconnectJob = null
        reconnectAttempt = 0
        flushJob?.cancel()
        flushJob = null
        outbox.clear()
        stopBluetooth()
        relay.disconnect(records)
        status = "idle"
        enter(key, device, owner, eventNumber, nickname)
    }

    fun leave() {
        reconnectJob?.cancel()
        reconnectJob = null
        reconnectAttempt = 0
        flushJob?.cancel()
        flushJob = null
        outbox.clear()
        bluetooth.stop()
        bluetoothPeers = 0
        relay.disconnect()
        sessionKey = null
        deviceAuthKey = SharedBuysCrypto.newDeviceAuthKey()
        signingKey = SharedBuysCrypto.newSigningKey()
        changes.clear()
        sealed.clear()
        invalidateFold()
        lastSeq = 0
        clock = 0
        status = "idle"
        submit(PendingWrite.CLEAR)
        SharedBuysLiveUpdateService.stop(context)
        note("left session")
    }

    fun connect() {
        val key = sessionKey ?: return
        val room = roomId ?: return
        reconnectJob?.cancel()
        reconnectJob = null
        status = "connecting"
        // The token is cached, so the first hello of a cold start carries it; a token
        // minted later reconnects once, and only once, through onFresh.
        SharedBuysPush.refresh(context) { if (isActive) connect() }
        relay.connect(
            SharedBuysRelay.Endpoint(
                relayBaseUrl,
                room,
                deviceId,
                deviceAuthKey,
                key,
                versionVector,
                SharedBuysPush.token(context)
            )
        ) { event -> handle(event) }
    }

    fun startBluetooth() {
        if (!isBluetoothEnabled) return
        val key = sessionKey ?: return
        bluetooth.start(key, SharedBuysDigest.bytes(bluetoothDigestVector)) { event ->
            when (event) {
                is BluetoothEvent.PeerCount -> {
                    bluetoothPeers = event.count
                    note("bluetooth peers ${event.count}")
                }
                is BluetoothEvent.PeerVerified -> handshakeCompleted(event.peer, event.digest)
                is BluetoothEvent.PeerLost -> wantedPeers.remove(event.peer)
                is BluetoothEvent.Payload -> handleBluetooth(event.bytes, event.from)
                is BluetoothEvent.Unavailable -> note("bluetooth: ${event.reason}")
            }
        }
    }

    fun stopBluetooth() {
        bluetooth.stop()
        bluetoothPeers = 0
        wantedPeers.clear()
    }

    fun missingBluetoothPermissions(): List<String> = bluetooth.missingPermissions()

    /**
     * Opens the exchange on a link we connected, unless the peer is already level.
     *
     * Only the connecting side asks first. Both sides asking on every link, and the
     * accepting side never knowing the peer's digest, meant four wants per pair of
     * phones, each answered to everyone in range. The accepting side asks back from
     * handleBluetooth instead, once, and only when the two logs differ.
     */
    private fun handshakeCompleted(peer: BluetoothPeer, peerDigest: ByteArray?) {
        if (peer.isCentral) return
        if (peerDigest != null &&
            peerDigest.contentEquals(SharedBuysDigest.bytes(bluetoothDigestVector))
        ) {
            note("peer is level, skipping want")
            return
        }
        sendWant(peer)
    }

    /**
     * Asks the peer for the status flips we lack.
     *
     * The vector is the gapless prefix of the whole log, not of the Bluetooth subset: a
     * device's first change is always MEMBER_JOINED, which never travels over Bluetooth,
     * so the subset's prefix was empty for everyone and no want was ever sent. A prefix
     * over the whole log is honest — holding every change up to n includes every status
     * flip up to n — and anything above a hole comes again and is deduped on ingest.
     */
    private fun sendWant(peer: BluetoothPeer) {
        wantedPeers.add(peer)
        SharedBuysWire.wantFrames(versionVector).forEach { bluetooth.send(it, peer) }
    }

    private fun handleBluetooth(payload: ByteArray, peer: BluetoothPeer) {
        when (val frame = SharedBuysWire.decode(payload)) {
            is SharedBuysFrame.Want -> {
                // The reply goes to whoever asked, not to every peer in range.
                val missing = changes.filter { change ->
                    SharedBuyKind.travelsOverBluetooth(change.payload.kind) &&
                        change.seq > (frame.vector[change.device] ?: 0L)
                }
                sendOverBluetooth(missing, peer)
                if (peer !in wantedPeers && frame.vector != versionVector) sendWant(peer)
            }
            is SharedBuysFrame.Changes -> ingest(frame.records, viaBluetooth = true)
            null -> Unit
        }
    }

    private fun sendOverBluetooth(outgoing: List<SharedBuyChange>, peer: BluetoothPeer? = null) {
        val eligible = outgoing.filter { SharedBuyKind.travelsOverBluetooth(it.payload.kind) }
        if (eligible.isEmpty() || bluetoothPeers == 0) return
        val key = sessionKey ?: return
        val room = roomId ?: return
        val records = eligible.mapNotNull { seal(it, key, room) }
        if (records.isEmpty()) return
        SharedBuysWire.changeFrames(records).forEach { bluetooth.send(it, peer) }
    }

    fun runSelfTest() {
        val vector = mapOf("aaaaaaaa" to 3L, "bbbbbbbb" to 1L, "cafebabe" to 260L)
        note("digest ${SharedBuysDigest.bytes(vector).toHex()}")

        val payload = ByteArray(500) { (it % 251).toByte() }
        val frames = SharedBuysFraming.chunks(payload, 7)
        val reassembler = SharedBuysFraming.Reassembler()
        var rebuilt: ByteArray? = null
        for (frame in frames.shuffled()) {
            reassembler.accept(frame)?.let { rebuilt = it }
        }
        val ok = rebuilt?.contentEquals(payload) == true
        note("framing ${frames.size} chunks, round trip ${if (ok) "ok" else "FAILED"}")

        sessionKey?.let {
            note("ble tag ${SharedBuysProfile.sessionTag(it).toHex()} window ${SharedBuysProfile.window()}")
        }

        checkHandshake(notConfused = SharedBuysHandshake.parse(frames.first()) == null)
        checkWire()
        checkRekey()
        checkSignatures()
    }

    private fun checkRekey() {
        val room = SharedBuysCrypto.roomId(ByteArray(32) { it.toByte() })
        val newKey = ByteArray(32) { (0xff - it).toByte() }
        val result = runCatching {
            val recipient = SharedBuysCrypto.privateKey(ByteArray(32) { (it + 1).toByte() })
            val ephemeral = java.security.KeyPair(
                SharedBuysCrypto.agreementPublicKey(REKEY_EPHEMERAL_PUBLIC.fromHex()),
                SharedBuysCrypto.privateKey(ByteArray(32) { (0x21 + it).toByte() })
            )
            val box = SharedBuysCrypto.sealRekey(
                newKey,
                "a1b2c3d4",
                REKEY_RECIPIENT_PUBLIC.fromHex(),
                room,
                "cafebabe",
                ephemeral,
                ByteArray(SharedBuysCrypto.NONCE_LENGTH) { 0x11 }
            )
            val vector = box.copyOfRange(box.size - 52, box.size).toHex() == REKEY_SEALED
            val opened = SharedBuysCrypto.openRekey(box, recipient, room, "cafebabe")
            val stranger = runCatching {
                SharedBuysCrypto.openRekey(box, SharedBuysCrypto.newAgreementKey().private, room, "cafebabe")
            }.isFailure
            vector to (opened.first.contentEquals(newKey) && opened.second == "a1b2c3d4" && stranger)
        }.getOrNull()
        note(
            "rekey vector ${if (result?.first == true) "ok" else "FAILED"} " +
                "open ${if (result?.second == true) "ok" else "FAILED"}"
        )
    }

    /**
     * Checks the signature test vector both platforms share, and that a member signing as
     * another device, or a device that never joined, is refused.
     */
    private fun checkSignatures() {
        val room = SharedBuysCrypto.roomId(ByteArray(32) { it.toByte() })
        val payload = SharedBuyPayload(12345, SharedBuyKind.SET_STATUS, "a1b2c3d4", 98765, value = 1)
        val input = SharedBuysCrypto.signInput(room, "a1b2c3d4", 42, payload)
        val seed = ByteArray(32) { (0x20 + it).toByte() }
        val signature = SharedBuysCrypto.sign(input, seed)
        val vector = input.toHex() == "636972636c65732d627579732f76312f7369676e00d82272e2a9501834ab4a2139c8dd043c" +
            "a1b2c3d4000000000000002a00000000000030390000000000000001000000086131623263336434" +
            "00000000000181cd00010000000000000001000000" &&
            SharedBuysCrypto.publicKey(seed).toHex() ==
            "29acbae141bccaf0b22e1a94d34d0bc7361e526d0bfe12c89794bc9322966dd7" &&
            signature.toHex() == "f2d23784ace1922d4c1de1309b8c92dec096802082acc71a40b77c66281fbe63" +
            "3ea7a7f6304f98ba06295e7ecd0b66eac2c4230538613b66c85d4c31c26f200c"

        fun signed(payload: SharedBuyPayload, device: String, seq: Long, key: ByteArray) = SharedBuyChange(
            device,
            seq,
            payload.copy(
                signature = SharedBuysCrypto.sign(
                    SharedBuysCrypto.signInput(room, device, seq, payload),
                    key
                ).toBase64Url()
            )
        )
        val member = SharedBuysCrypto.newSigningKey()
        val forger = SharedBuysCrypto.newSigningKey()
        val joined = SharedBuyPayload(
            1, SharedBuyKind.MEMBER_JOINED, "-", 0, "a",
            publicKey = SharedBuysCrypto.publicKey(member).toBase64Url()
        )
        val signers = SharedBuySigners(emptyList())
        val unknown = !signers.admit(signed(payload, "a1b2c3d4", 2, member), room)
        val pinned = signers.admit(signed(joined, "a1b2c3d4", 1, member), room)
        val genuine = signers.admit(signed(payload, "a1b2c3d4", 2, member), room)
        val forged = !signers.admit(signed(payload, "a1b2c3d4", 3, forger), room)
        val stripped = !signers.admit(SharedBuyChange("a1b2c3d4", 4, payload), room)
        val unsigned = signers.admit(SharedBuyChange("cafebabe", 1, joined.copy(publicKey = null)), room) &&
            signers.admit(SharedBuyChange("cafebabe", 2, payload), room)
        val policy = unknown && pinned && genuine && forged && stripped && unsigned
        note(
            "signature vector ${if (vector) "ok" else "FAILED"} " +
                "policy ${if (policy) "ok" else "FAILED"}"
        )
    }

    /** Runs the handshake test vector both platforms share, and a stranger against it. */
    private fun checkHandshake(notConfused: Boolean) {
        val key = SharedBuysHandshake.key(ByteArray(32) { it.toByte() })
        val challenge = ByteArray(8) { (it + 1).toByte() }
        val nonce = ByteArray(8) { (0x11 + it).toByte() }
        val response = SharedBuysHandshake.response(challenge, nonce, key)
        val confirm = SharedBuysHandshake.confirm(challenge, nonce, key)
        val vector = response.toHex() == "04111213141516171812f9003d9145f14c" &&
            confirm.toHex() == "05cff3acad54e390af"
        val stranger = SharedBuysHandshake.key(ByteArray(32) { 0x5a })
        val parsed = SharedBuysHandshake.parse(response) as? SharedBuysHandshake.Frame.Response
        val verified = parsed != null &&
            SharedBuysHandshake.verifiesResponse(parsed.mac, challenge, parsed.nonce, key) &&
            !SharedBuysHandshake.verifiesResponse(parsed.mac, challenge, parsed.nonce, stranger)
        note(
            "handshake vector ${if (vector) "ok" else "FAILED"} " +
                "verify ${if (verified) "ok" else "FAILED"} " +
                "framing ${if (notConfused) "ok" else "FAILED"}"
        )
    }

    /**
     * Encodes the wire format note's test vector from scratch and parses it back.
     *
     * This walks the whole construction — HKDF, AES-256-GCM, the record tag and the
     * frame layout — so a change on either platform that moves a byte shows up here
     * rather than as a peer that silently cannot open anything.
     */
    private fun checkWire() {
        val key = ByteArray(32) { it.toByte() }
        val room = SharedBuysCrypto.roomId(key)
        val contentKey = SharedBuysCrypto.derive(SharedBuysCrypto.OPS_INFO, key)
        val relayAuthKey = SharedBuysCrypto.derive(SharedBuysCrypto.RELAY_AUTH_INFO, key)
        val plaintext = "{\"a\":12345,\"k\":1,\"i\":\"a1b2c3d4\",\"c\":98765,\"v\":1}".toByteArray()
        val blob = SharedBuysCrypto.seal(
            plaintext,
            contentKey,
            room,
            "a1b2c3d4",
            42,
            ByteArray(SharedBuysCrypto.NONCE_LENGTH) { 0x11 }
        )
        val recordTag = SharedBuysCrypto.recordTag("a1b2c3d4", 42, blob, relayAuthKey)
        val record = RelayRecord("a1b2c3d4", 42, blob.toBase64Url(), recordTag.toBase64Url())
        val frame = SharedBuysWire.changeFrames(listOf(record)).firstOrNull()
        if (frame == null) {
            note("wire vector FAILED to encode")
            return
        }
        val marked = blob.copyOfRange(0, SharedBuysCrypto.RANDOM_NONCE_MARKER.size)
            .contentEquals(SharedBuysCrypto.RANDOM_NONCE_MARKER)
        val opened = runCatching {
            SharedBuysCrypto.open(blob, contentKey, room, "a1b2c3d4", 42)
        }.getOrNull()
        note("wire ${frame.size}B nonce ${if (marked) "ok" else "FAILED"} crypto ${if (opened?.contentEquals(plaintext) == true) "ok" else "FAILED"}")

        val decoded = SharedBuysWire.decode(frame) as? SharedBuysFrame.Changes
        val first = decoded?.records?.firstOrNull()
        val changesOk = first != null && first.device == record.device &&
            first.seq == record.seq && first.blob == record.blob && first.tag == record.tag
        val vector = mapOf("a1b2c3d4" to 42L, "cafebabe" to 260L)
        val wantFrame = SharedBuysWire.wantFrames(vector).firstOrNull()
        val wantOk = wantFrame != null &&
            (SharedBuysWire.decode(wantFrame) as? SharedBuysFrame.Want)?.vector == vector
        note(
            "wire round trip changes ${if (changesOk) "ok" else "FAILED"} " +
                "want ${if (wantOk) "ok" else "FAILED"}"
        )

        // A blobLen larger than what is left must be refused, not sliced.
        val overrun = SharedBuysWire.decode(frame.copyOf(frame.size - 1)) == null
        val wrongVersion = frame.copyOf().also { it[0] = 0x7F }
        val skipped = SharedBuysWire.decode(wrongVersion) == null
        note(
            "wire bounds ${if (overrun) "ok" else "FAILED"} " +
                "version ${if (skipped) "ok" else "FAILED"}"
        )
    }

    /**
     * Adds an item, carrying the circle's identity into the log the first time that
     * circle appears in the room.
     *
     * circleName and circleSpace come from the caller's catalog database, which a guest
     * does not have. Relayed once per circle rather than per item: the check is against
     * the folded circle map, so it is idempotent across a restore and a second
     * contributor adding from a circle someone else already introduced.
     */
    fun addItem(
        name: String,
        cost: Int,
        circleId: Int,
        circleName: String? = null,
        circleSpace: String? = null
    ): String {
        val itemId = UUID.randomUUID().toString().take(8)
        if (!circleName.isNullOrEmpty() && circles[circleId] == null) {
            append(SharedBuyKind.CIRCLE_INFO, "-", circleId, circleName, null, circleSpace)
        }
        append(SharedBuyKind.ADD_ITEM, itemId, circleId, name, cost)
        append(SharedBuyKind.SET_ASSIGNEE, itemId, circleId, null, actorPid)
        return itemId
    }

    fun rename(itemId: String, circleId: Int, name: String) {
        append(SharedBuyKind.RENAME_ITEM, itemId, circleId, name, null)
    }

    fun setCost(itemId: String, circleId: Int, cost: Int) {
        append(SharedBuyKind.SET_COST, itemId, circleId, null, cost)
    }

    fun remove(itemId: String, circleId: Int) {
        append(SharedBuyKind.REMOVE_ITEM, itemId, circleId, null, null)
    }

    fun cycle(item: SharedBuyItem) {
        append(SharedBuyKind.SET_STATUS, item.id, item.circleId, null, SharedBuyStatus.next(item.status))
    }

    private fun append(
        kind: Int,
        itemId: String,
        circleId: Int,
        text: String?,
        value: Int?,
        space: String? = null,
        actor: Int? = null
    ): SharedBuyChange? {
        val key = sessionKey ?: return null
        val room = roomId ?: return null
        // A guest holds the room key and could append anything the relay would accept.
        // The restriction is the app honouring its own role, not something the log can
        // enforce -- see isGuest. MEMBER_JOINED is how a guest appears in the members
        // list at all, so it is allowed alongside the status flips they are here for.
        if (isGuest && kind != SharedBuyKind.SET_STATUS && kind != SharedBuyKind.MEMBER_JOINED &&
            kind != SharedBuyKind.MEMBER_KEY
        ) {
            return null
        }
        lastSeq += 1
        clock += 1
        val publicKey = if (kind == SharedBuyKind.MEMBER_JOINED) {
            SharedBuysCrypto.publicKey(signingKey).toBase64Url()
        } else {
            null
        }
        val unsigned = SharedBuyPayload(actor ?: actorPid, kind, itemId, circleId, text, value, space, clock, publicKey)
        val signature = SharedBuysCrypto.sign(
            SharedBuysCrypto.signInput(room, deviceId, lastSeq, unsigned),
            signingKey
        )
        val change = SharedBuyChange(
            device = deviceId,
            seq = lastSeq,
            payload = unsigned.copy(signature = signature.toBase64Url())
        )
        changes.add(change)
        invalidateFold()
        persist()
        seal(change, key, room)?.let { if (!isRekeying) enqueue(it) }
        sendOverBluetooth(listOf(change))
        bluetooth.update(SharedBuysDigest.bytes(bluetoothDigestVector))
        return change
    }

    /** Holds a record briefly so a burst of edits leaves as one frame. */
    private fun enqueue(record: RelayRecord) {
        outbox.add(record)
        if (outbox.size >= MAX_RECORDS_PER_FRAME) {
            flushOutbox()
            return
        }
        if (flushJob != null) return
        flushJob = scope.launch {
            kotlinx.coroutines.delay(COALESCE_WINDOW_MS)
            flushJob = null
            flushOutbox()
        }
    }

    private fun flushOutbox() {
        flushJob?.cancel()
        flushJob = null
        if (outbox.isEmpty()) return
        val records = outbox.toList()
        outbox.clear()
        relay.send(records) { event -> handle(event) }
    }

    /** Seals each change once, rather than on every want reply and every reconnect. */
    private fun seal(change: SharedBuyChange, key: ByteArray, room: String): RelayRecord? =
        sealed[change.id] ?: sealFresh(change, key, room)?.also { sealed[change.id] = it }

    private fun sealFresh(change: SharedBuyChange, key: ByteArray, room: String): RelayRecord? =
        runCatching {
            val keys = keys(key)
            val plaintext = json.encodeToString(change.payload).toByteArray()
            val blob = SharedBuysCrypto.seal(plaintext, keys.content, room, change.device, change.seq)
            val tag = SharedBuysCrypto.recordTag(change.device, change.seq, blob, keys.relayAuth)
            RelayRecord(change.device, change.seq, blob.toBase64Url(), tag.toBase64Url())
        }.getOrNull()

    private fun handle(event: RelayEvent) {
        when (event) {
            is RelayEvent.Connected -> {
                status = "connected"
                reconnectAttempt = 0
                note("connected")
            }
            is RelayEvent.Held -> {
                // Our own history coming back from the relay means a save was lost;
                // never reuse a sequence number it already holds. held carries no tag, so
                // it is capped at what a room can hold: a relay that lies cannot push
                // lastSeq out of reach and strand every later write on this device.
                val held = event.seq.coerceIn(0L, MAX_STORED_RECORDS)
                lastSeq = maxOf(lastSeq, held)
                resend(held)
            }
            is RelayEvent.Records -> ingest(event.records)
            // The relay refuses writes once a room holds 500 records, and closes the
            // socket that tried. Reconnecting only re-sends the refused change and is
            // closed again, every 30 seconds for the rest of the room's life, so a full
            // room waits for the next resume instead.
            is RelayEvent.Failed -> {
                status = "offline (${event.reason})"
                note("failed: ${event.reason}")
                if (event.reason != STORAGE_FULL_SLUG && event.reason != UNATTESTED_SLUG) {
                    scheduleReconnect()
                }
            }
            is RelayEvent.Closed -> {
                status = "offline (closed ${event.code})"
                note("closed ${event.code}")
                if (event.code != STORAGE_FULL_CODE) scheduleReconnect()
            }
        }
    }

    /**
     * Arms the reconnect.
     *
     * Nearby peers never defer it. Bluetooth only carries status flips, so holding the
     * relay off while a peer was in range stranded every added item, rename, cost and
     * assignment on this phone for as long as the two stayed together.
     */
    private fun scheduleReconnect() {
        if (!isActive || reconnectJob != null) return
        reconnectAttempt = minOf(reconnectAttempt + 1, 6)
        val delayMs = (minOf(Math.pow(2.0, reconnectAttempt.toDouble()), 30.0) * 1000).toLong() +
            (0..1000).random()
        note("reconnect in ${delayMs / 1000.0}s")
        reconnectJob = scope.launch {
            kotlinx.coroutines.delay(delayMs)
            reconnectJob = null
            if (!isActive) return@launch
            connect()
        }
    }

    /**
     * Uploads the changes this device authored that the relay does not hold yet.
     *
     * above is the gapless prefix the relay reported after hello. Re-sending the whole
     * history on every reconnect re-sealed and re-uploaded changes the relay only threw
     * away as duplicates. Pages are frames the relay will accept, spaced out so a long
     * history stays under its rate limit.
     */
    private fun resend(above: Long) {
        val key = sessionKey ?: return
        val room = roomId ?: return
        val pages = pages(
            changes.filter { it.device == deviceId && it.seq > above }.mapNotNull { seal(it, key, room) }
        )
        scope.launch {
            pages.forEachIndexed { index, page ->
                relay.send(page) { event -> handle(event) }
                if (index < pages.lastIndex) kotlinx.coroutines.delay(RESEND_PAGE_DELAY_MS)
            }
        }
    }

    /**
     * Opens incoming records away from the thread that delivered them.
     *
     * The Bluetooth path used to derive two keys, open GCM, mutate Compose state and
     * write SharedPreferences inline on a binder callback, blocking the BLE stack the
     * whole time. Opening is pure work over the batch, so it moves to a worker; only the
     * append comes back to the main thread. Batches are opened one at a time, against the
     * signers the log held when the batch began.
     */
    private fun ingest(records: List<RelayRecord>, viaBluetooth: Boolean = false) {
        val key = sessionKey ?: return
        val room = roomId ?: return
        val keys = keys(key)
        scope.launch(kotlinx.coroutines.Dispatchers.Main) {
            ingestLock.withLock {
                if (sessionKey?.contentEquals(key) != true) return@withLock
                val known = changes.mapTo(mutableSetOf()) { it.id }
                val fresh = records.filter { "${it.device}#${it.seq}" !in known }
                if (fresh.isEmpty()) return@withLock
                val signers = SharedBuySigners(changes.toList())
                val unopenable = mutableListOf<String>()
                val opened = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) {
                    open(fresh, keys, room, signers, viaBluetooth, unopenable)
                }
                if (sessionKey?.contentEquals(key) != true) return@withLock
                unopenable.forEach { note("could not open or verify $it") }
                adopt(opened)
            }
        }
    }

    /**
     * Opens a batch in (device, seq) order, so a MEMBER_JOINED pins its key before the
     * records it signs are checked.
     *
     * Bluetooth only ever carries status flips, so anything else arriving that way is
     * refused: it is how a member nearby would otherwise announce a key of their own for
     * a device we have not heard join yet.
     */
    private fun open(
        records: List<RelayRecord>,
        keys: SharedBuysKeys,
        room: String,
        signers: SharedBuySigners,
        viaBluetooth: Boolean,
        unopenable: MutableList<String>
    ): List<SharedBuyChange> =
        records.sortedWith(compareBy({ it.device }, { it.seq })).mapNotNull { record ->
            open(record, keys, room)?.takeIf {
                (!viaBluetooth || SharedBuyKind.travelsOverBluetooth(it.payload.kind)) &&
                    signers.admit(it, room)
            }.also { if (it == null) unopenable.add("${record.device}#${record.seq}") }
        }

    /** The room's record keys, derived once per session key instead of twice per record. */
    private fun keys(sessionKey: ByteArray): SharedBuysKeys {
        keyCache?.let { (cachedFor, keys) -> if (cachedFor.contentEquals(sessionKey)) return keys }
        return SharedBuysKeys(sessionKey).also { keyCache = sessionKey to it }
    }

    /** Verifies and decrypts one record. Pure, so it is safe on any thread. */
    private fun open(record: RelayRecord, keys: SharedBuysKeys, room: String): SharedBuyChange? {
        // Whoever handed us this record — the relay, or a peer over Bluetooth — is not
        // trusted to have authored it. Check the tag before it enters the log.
        val authentic = runCatching {
            SharedBuysCrypto.recordTag(
                record.device,
                record.seq,
                record.blob.fromBase64Url(),
                keys.relayAuth
            ).contentEquals(record.tag.fromBase64Url())
        }.getOrDefault(false)
        if (!authentic) return null
        val payload = runCatching {
            val blob = record.blob.fromBase64Url()
            val plaintext = SharedBuysCrypto.open(blob, keys.content, room, record.device, record.seq)
            json.decodeFromString<SharedBuyPayload>(String(plaintext))
        }.getOrNull() ?: return null
        return SharedBuyChange(record.device, record.seq, payload)
    }

    /** Appends what was opened, re-checking against a log that may have moved meanwhile. */
    private fun adopt(opened: List<SharedBuyChange>) {
        if (opened.isEmpty()) return
        val known = changes.mapTo(mutableSetOf()) { it.id }
        val added = mutableListOf<SharedBuyChange>()
        for (change in opened) {
            // A batch can carry the same record twice — a relay echo, or a want reply
            // overlapping the live stream — so the set has to grow as we append.
            if (!known.add(change.id)) continue
            changes.add(change)
            // A Lamport clock. Without it a fresh device's first change sorts under an
            // established peer's thirtieth, and the older edit wins on every screen.
            clock = maxOf(clock, change.order)
            // Our own change coming back means a save was lost; never reuse its seq.
            if (change.device == deviceId) lastSeq = maxOf(lastSeq, change.seq)
            added.add(change)
        }
        if (added.isNotEmpty()) {
            invalidateFold()
            persist()
            bluetooth.update(SharedBuysDigest.bytes(bluetoothDigestVector))
            note("received ${added.size}")
            followRekeys(added)
        }
    }

    private enum class PendingWrite { SAVE, CLEAR }

    /**
     * Marks the session as needing a save.
     *
     * One writer drains the latest request, so saves can neither land out of order — an
     * older snapshot overwriting a newer one rolled lastSeq back, and the next change
     * reused a sequence number the relay already held — nor outlive a leave() and bring
     * the room back on the next launch. A burst of changes collapses into one write, and
     * the snapshot is taken when the write starts, not per change.
     */
    private fun persist() {
        if (sessionKey == null) return
        submit(PendingWrite.SAVE)
    }

    private fun submit(write: PendingWrite) {
        pendingWrite = write
        if (writeJob != null) return
        writeJob = scope.launch {
            while (true) {
                val next = pendingWrite ?: break
                pendingWrite = null
                val snapshot = if (next == PendingWrite.SAVE) snapshot() ?: continue else null
                kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                    if (snapshot != null) store.save(snapshot) else store.clear()
                }
            }
            writeJob = null
        }
    }

    private fun snapshot(): SharedBuysSnapshot? {
        val key = sessionKey ?: return null
        return SharedBuysSnapshot(
            sessionKey = key.toBase64Url(),
            deviceId = deviceId,
            deviceAuthKey = deviceAuthKey.toBase64Url(),
            signingKey = signingKey.toBase64Url(),
            eventNumber = eventNumber,
            lastSeq = lastSeq,
            changes = changes.toList(),
            clock = clock,
            agreementKey = SharedBuysCrypto.privateKeyBytes(agreementKey.private).toBase64Url(),
            agreementPublicKey = SharedBuysCrypto.publicKeyBytes(agreementKey.public).toBase64Url(),
            ownerDevice = ownerDevice
        )
    }

    private fun note(message: String) {
        log.add(0, message)
        if (log.size > 40) log.removeAt(log.size - 1)
    }

    companion object {
        /** The host of the join deep link, shared by the QR code and the scanner. */
        const val JOIN_HOST = "buys-join"

        const val GUEST_MODE_KEY = "Guest.IsActive"
        private const val GUEST_NICKNAME_KEY = "Guest.Nickname"

        /**
         * How long an outbound record waits for company before it is sent.
         *
         * The relay's bucket is 20 messages per 10 seconds and addItem alone emits two
         * changes, so a frame per change put ten quick adds over the limit and earned a
         * rate-limit close. A quarter second is under the threshold of feeling laggy and
         * collapses a burst of typing into one frame.
         */
        private const val COALESCE_WINDOW_MS = 250L
        private const val RESEND_PAGE_DELAY_MS = 600L
        private const val STORAGE_FULL_SLUG = "storage"
        private const val STORAGE_FULL_CODE = 4005
        private const val REKEY_RECIPIENT_PUBLIC =
            "04515c3d6eb9e396b904d3feca7f54fdcd0cc1e997bf375dca515ad0a6c3b4035f" +
                "4536be3a50f318fbf9a5475902a221502bef0d57e08c53b2cc0a56f17d9f9354"
        private const val REKEY_EPHEMERAL_PUBLIC =
            "041f140146bfb1b251f84f4ddbe0d4cdcfd77afd984a9520e35794021f8312bb9e" +
                "ec995a08b1fa7704df3dcc0b50a9665263fb7711f95f9f8a449c5096e47c892b"
        private const val REKEY_SEALED =
            "4968b067252cb291c8edd8244e1269fd7740abbf41ebf4e842663ebb" +
                "0b89fbce886e51c8036b9e64d95c57379e5bcf35fac8aba9"
        private const val MAX_STORED_RECORDS = 500L

    }
}
