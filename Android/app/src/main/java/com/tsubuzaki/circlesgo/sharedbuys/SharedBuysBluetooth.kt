package com.tsubuzaki.circlesgo.sharedbuys

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
import java.util.UUID

/**
 * One end of one link. The same phone connected both ways is two peers: isCentral is
 * true for a central connected to our server, false for a peripheral we connected to.
 */
data class BluetoothPeer(val address: String, val isCentral: Boolean)

sealed interface BluetoothEvent {
    data class PeerCount(val count: Int) : BluetoothEvent
    data class PeerVerified(val peer: BluetoothPeer, val digest: ByteArray?) : BluetoothEvent
    data class PeerLost(val peer: BluetoothPeer) : BluetoothEvent
    data class Payload(val bytes: ByteArray, val from: BluetoothPeer) : BluetoothEvent
    data class Unavailable(val reason: String) : BluetoothEvent
}

private const val MTU = 247
private const val REFRESH_INTERVAL_MS = 30_000L
private const val MAX_PENDING_RESPONSES = 16
private const val HANDSHAKE_DEADLINE_MS = 10_000L
private const val MAX_WRITE_RETRIES = 5
private const val WRITE_RETRY_DELAY_MS = 50L
private const val MAX_NOTIFY_RETRIES = 5
private const val NOTIFY_RETRY_DELAY_MS = 50L
private const val ADVERTISE_RETRY_DELAY_MS = 500L
private const val ADVERTISE_RETRY_MAX_DELAY_MS = 8_000L
private val CLIENT_CONFIG_UUID: UUID =
    UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

@SuppressLint("MissingPermission")
class SharedBuysBluetooth(private val context: Context) {

    private val manager = context.getSystemService(BluetoothManager::class.java)
    private val adapter get() = manager?.adapter

    private var server: BluetoothGattServer? = null
    private var outbox: BluetoothGattCharacteristic? = null
    private val subscribers = mutableSetOf<BluetoothDevice>()
    private val clients = mutableMapOf<String, BluetoothGatt>()
    private val inboxes = mutableMapOf<String, BluetoothGattCharacteristic>()
    // Kept apart by role. A peer we are both connected to and serving sends us the
    // same message down both paths under one message id; funnelling them into a single
    // buffer let the duplicate indices overwrite each other and complete early.
    private val clientReassemblers = mutableMapOf<String, SharedBuysFraming.Reassembler>()
    private val serverReassemblers = mutableMapOf<String, SharedBuysFraming.Reassembler>()
    private val mtus = mutableMapOf<String, Int>()
    private val verifiedClients = mutableSetOf<String>()
    private val verifiedCentrals = mutableSetOf<String>()
    private val rejectedUntil = mutableMapOf<String, Long>()
    private val pendingNotifies = ArrayDeque<Pair<ByteArray, BluetoothDevice>>()
    private val writeQueues = mutableMapOf<String, ArrayDeque<ByteArray>>()
    private val writing = mutableSetOf<String>()
    private val writeRetries = mutableMapOf<String, Int>()
    private var notifyRetries = 0
    private val peerDigests = mutableMapOf<String, ByteArray>()
    private val handler = Handler(Looper.getMainLooper())
    /** The window whose advertisement the stack has confirmed is on the air. */
    private var advertisedWindow: Long? = null
    /** The window of the advertisement we last handed the stack, until it answers. */
    private var pendingAdvertisedWindow: Long? = null
    private var advertiseAttempts = 0
    /** The room tags a peer may advertise, recomputed only when the window turns. */
    private var tagCache: Pair<Long, List<ByteArray>>? = null

    private var sessionKey: ByteArray? = null
    private var handshakeKey: ByteArray? = null
    /** The challenge we sent each peripheral, until it answers. */
    private val challenges = mutableMapOf<String, ByteArray>()
    /** The challenge each central sent us and the nonce we answered with, until it confirms. */
    private val responses = mutableMapOf<String, Pair<ByteArray, ByteArray>>()
    private var digest: ByteArray = ByteArray(4)
    private var onEvent: ((BluetoothEvent) -> Unit)? = null
    private var messageCounter: Byte = 0

    val peerCount: Int get() = verifiedClients.size + verifiedCentrals.size

    private val requiredPermissions: List<String>
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT
            )
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    fun missingPermissions(): List<String> = requiredPermissions.filter {
        ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
    }

    fun start(sessionKey: ByteArray, digest: ByteArray, onEvent: (BluetoothEvent) -> Unit) {
        this.sessionKey = sessionKey
        this.handshakeKey = SharedBuysHandshake.key(sessionKey)
        this.digest = digest
        this.onEvent = onEvent

        val adapter = adapter
        if (adapter == null || !adapter.isEnabled) {
            onEvent(BluetoothEvent.Unavailable("bluetooth off"))
            return
        }
        val missing = missingPermissions()
        if (missing.isNotEmpty()) {
            onEvent(BluetoothEvent.Unavailable("permission: ${missing.joinToString()}"))
            return
        }
        publishService()
        advertise()
        scan()
        startRefreshing()
    }

    fun stop() {
        handler.removeCallbacks(refresh)
        handler.removeCallbacks(retryAdvertise)
        handler.removeCallbacks(retryNotifies)
        advertisedWindow = null
        pendingAdvertisedWindow = null
        advertiseAttempts = 0
        notifyRetries = 0
        runCatching { adapter?.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback) }
        runCatching { adapter?.bluetoothLeScanner?.stopScan(scanCallback) }
        clients.values.forEach { runCatching { it.close() } }
        clients.clear()
        inboxes.clear()
        subscribers.clear()
        clientReassemblers.clear()
        serverReassemblers.clear()
        mtus.clear()
        verifiedClients.clear()
        verifiedCentrals.clear()
        rejectedUntil.clear()
        pendingNotifies.clear()
        writeQueues.clear()
        writing.clear()
        writeRetries.clear()
        peerDigests.clear()
        challenges.clear()
        responses.clear()
        tagCache = null
        runCatching { server?.close() }
        server = null
        sessionKey = null
        handshakeKey = null
        onEvent = null
    }

    fun update(digest: ByteArray) {
        if (this.digest.contentEquals(digest)) return
        this.digest = digest
        advertise()
    }

    /** Sends to one peer, or to every verified peer when peer is null. */
    fun send(payload: ByteArray, peer: BluetoothPeer? = null) {
        messageCounter = (messageCounter + 1).toByte()
        // Each link negotiates its own MTU, so the payload is cut to fit the peer it is
        // going to rather than to one hardcoded size.
        subscribers.filter {
            verifiedCentrals.contains(it.address) && (peer == null || peer == BluetoothPeer(it.address, true))
        }.forEach { device ->
            SharedBuysFraming.chunks(payload, messageCounter, payloadLimit(device.address))
                .forEach { frame -> notify(frame, device) }
        }
        clients.forEach { (address, gatt) ->
            if (!verifiedClients.contains(address)) return@forEach
            if (peer != null && peer != BluetoothPeer(address, false)) return@forEach
            SharedBuysFraming.chunks(payload, messageCounter, payloadLimit(address))
                .forEach { frame -> enqueueWrite(gatt, frame) }
        }
    }

    /**
     * A GATT client can only have one write in flight. Writing every chunk of a message
     * back to back hands the stack the second one before it has reported the first, and
     * the second is what gets dropped — so a two chunk message never reassembles.
     */
    private fun enqueueWrite(gatt: BluetoothGatt, frame: ByteArray) {
        val address = gatt.device.address
        writeQueues.getOrPut(address) { ArrayDeque() }.addLast(frame)
        pumpWrites(gatt)
    }

    private fun pumpWrites(gatt: BluetoothGatt) {
        val address = gatt.device.address
        if (writing.contains(address)) return
        val queue = writeQueues[address] ?: return
        val inbox = inboxes[address] ?: return
        val frame = queue.removeFirstOrNull() ?: return
        writing.add(address)
        val sent = runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                gatt.writeCharacteristic(
                    inbox,
                    frame,
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                ) == BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                run {
                    inbox.value = frame
                    inbox.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                    gatt.writeCharacteristic(inbox)
                }
            }
        }.getOrDefault(false)
        if (sent) {
            writeRetries.remove(address)
            return
        }
        writing.remove(address)
        // A refused write (the stack is busy) used to drop the chunk, so the message could
        // never reassemble, and nothing pumped the queue again until the next send. The
        // chunk goes back to the front and is retried shortly; one the stack keeps
        // refusing is dropped so the rest of the queue can move.
        val attempts = (writeRetries[address] ?: 0) + 1
        if (attempts > MAX_WRITE_RETRIES) {
            writeRetries.remove(address)
        } else {
            writeRetries[address] = attempts
            queue.addFirst(frame)
        }
        handler.postDelayed({ if (clients[address] === gatt) pumpWrites(gatt) }, WRITE_RETRY_DELAY_MS)
    }

    private fun publishService() {
        val service = BluetoothGattService(
            SharedBuysProfile.SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )
        val inbox = BluetoothGattCharacteristic(
            SharedBuysProfile.INBOX_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        val outboxCharacteristic = BluetoothGattCharacteristic(
            SharedBuysProfile.OUTBOX_UUID,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        outboxCharacteristic.addDescriptor(
            BluetoothGattDescriptor(
                CLIENT_CONFIG_UUID,
                BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
            )
        )
        service.addCharacteristic(inbox)
        service.addCharacteristic(outboxCharacteristic)
        outbox = outboxCharacteristic
        server = manager?.openGattServer(context, serverCallback)?.also { it.addService(service) }
    }

    private fun advertise() {
        val key = sessionKey ?: return
        val advertiser = adapter?.bluetoothLeAdvertiser ?: return
        handler.removeCallbacks(retryAdvertise)
        runCatching { advertiser.stopAdvertising(advertiseCallback) }
        // The window is only claimed once the stack confirms the advertisement is up.
        // Claiming it here meant a refused start — ALREADY_STARTED is easy to hit, since
        // every ingested change restarts advertising to carry the new digest — left the
        // device silently off the air until the window turned, up to 15 minutes later.
        advertisedWindow = null
        pendingAdvertisedWindow = SharedBuysProfile.window()
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .build()
        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(SharedBuysProfile.SERVICE_UUID))
            .setIncludeDeviceName(false)
            .build()
        // A 128 bit service UUID and its service data do not both fit in the 31 byte
        // advertisement, so the room tag and digest go in the scan response. iOS reads
        // the merged record, and puts the same bytes in its local name.
        val scanResponse = AdvertiseData.Builder()
            .addServiceData(
                ParcelUuid(SharedBuysProfile.SERVICE_UUID),
                SharedBuysProfile.advertisement(key, digest)
            )
            .setIncludeDeviceName(false)
            .build()
        val handed = runCatching {
            advertiser.startAdvertising(settings, data, scanResponse, advertiseCallback)
        }.isSuccess
        if (!handed) scheduleAdvertiseRetry()
    }

    /**
     * Tries again after a refused start, backing off so a stack that is out of
     * advertising sets is not hammered.
     */
    private fun scheduleAdvertiseRetry() {
        if (sessionKey == null) return
        advertiseAttempts += 1
        val delay = (ADVERTISE_RETRY_DELAY_MS shl (advertiseAttempts - 1).coerceAtMost(8))
            .coerceAtMost(ADVERTISE_RETRY_MAX_DELAY_MS)
        handler.removeCallbacks(retryAdvertise)
        handler.postDelayed(retryAdvertise, delay)
    }

    private val retryAdvertise = Runnable { if (sessionKey != null) advertise() }

    /**
     * The advertised tag is only valid for its window, so it has to be reissued before
     * the window turns over, or peers stop recognising us as part of the room.
     */
    private fun startRefreshing() {
        handler.removeCallbacks(refresh)
        handler.postDelayed(refresh, REFRESH_INTERVAL_MS)
    }

    private val refresh = object : Runnable {
        override fun run() {
            if (sessionKey == null) return
            if (advertisedWindow != SharedBuysProfile.window()) advertise()
            handler.postDelayed(this, REFRESH_INTERVAL_MS)
        }
    }

    private fun scan() {
        val scanner = adapter?.bluetoothLeScanner ?: return
        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(SharedBuysProfile.SERVICE_UUID))
            .build()
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_BALANCED)
            .build()
        runCatching { scanner.startScan(listOf(filter), settings, scanCallback) }
    }

    private fun shouldConnect(result: ScanResult): Boolean {
        sessionKey ?: return false
        val address = result.device.address
        if (clients.containsKey(address)) return false
        val until = rejectedUntil[address] ?: return true
        return until <= System.currentTimeMillis()
    }

    /**
     * Drops a peripheral and backs it off for a minute.
     *
     * Closing here rather than waiting for the disconnect callback: a connection still
     * pending when it is cancelled may never report one.
     */
    private fun reject(gatt: BluetoothGatt) {
        val address = gatt.device.address
        rejectedUntil[address] = System.currentTimeMillis() + 60_000L
        runCatching { gatt.disconnect() }
        if (clients[address] === gatt) forget(address)
    }

    private fun forget(address: String) {
        clients.remove(address)?.let { runCatching { it.close() } }
        inboxes.remove(address)
        clientReassemblers.remove(address)
        // The MTU belongs to the ACL link, which the server side may still be using:
        // dropping it for a peer still connected to our server collapsed its notify
        // chunks to the 23 byte default.
        if (subscribers.none { it.address == address }) mtus.remove(address)
        val wasVerified = verifiedClients.remove(address)
        writeQueues.remove(address)
        writing.remove(address)
        writeRetries.remove(address)
        peerDigests.remove(address)
        challenges.remove(address)
        onEvent?.invoke(BluetoothEvent.PeerCount(peerCount))
        if (wasVerified) onEvent?.invoke(BluetoothEvent.PeerLost(BluetoothPeer(address, false)))
    }

    private fun forgetCentral(device: BluetoothDevice) {
        subscribers.remove(device)
        if (verifiedCentrals.remove(device.address)) {
            onEvent?.invoke(BluetoothEvent.PeerLost(BluetoothPeer(device.address, true)))
        }
    }

    /**
     * Rejects the peripheral if it has not proved the room key in time.
     *
     * A peer that ignores the challenge — any nearby device of another room, or one that
     * never answers — otherwise held its connection for as long as it stayed in range,
     * and at a busy venue those filled every GATT slot the stack has.
     */
    private fun armHandshakeDeadline(gatt: BluetoothGatt) {
        val address = gatt.device.address
        handler.postDelayed({
            if (clients[address] === gatt && !verifiedClients.contains(address)) reject(gatt)
        }, HANDSHAKE_DEADLINE_MS)
    }

    /**
     * The same deadline for a central connected to our server, which we can disconnect.
     *
     * The server callback also reports links we opened as a client; those are left to
     * the client-side deadline, since cancelling here would drop the shared link.
     */
    private fun armHandshakeDeadline(device: BluetoothDevice) {
        handler.postDelayed({
            val address = device.address
            if (sessionKey != null && !clients.containsKey(address) && !verifiedCentrals.contains(address)) {
                runCatching { server?.cancelConnection(device) }
            }
        }, HANDSHAKE_DEADLINE_MS)
    }

    private fun notify(frame: ByteArray, device: BluetoothDevice) {
        val characteristic = outbox ?: return
        if (pendingNotifies.isNotEmpty()) {
            pendingNotifies.addLast(frame to device)
            return
        }
        characteristic.value = frame
        val sent = runCatching {
            server?.notifyCharacteristicChanged(device, characteristic, false) == true
        }.getOrDefault(false)
        if (!sent) {
            pendingNotifies.addLast(frame to device)
            scheduleNotifyFlush()
        }
    }

    /**
     * Drains the queue, with a timer behind it.
     *
     * onNotificationSent only fires for a notification the stack accepted, so a refused
     * one left nothing to drive the queue again: the first refusal wedged every later
     * notify behind a queue nobody drained, handshake responses included, and no central
     * could verify against us again for the rest of the session. The write path already
     * retried on a delay; this is the same treatment.
     */
    private fun flushNotifies() {
        val characteristic = outbox ?: return
        handler.removeCallbacks(retryNotifies)
        while (pendingNotifies.isNotEmpty()) {
            val (frame, device) = pendingNotifies.first()
            characteristic.value = frame
            val sent = runCatching {
                server?.notifyCharacteristicChanged(device, characteristic, false) == true
            }.getOrDefault(false)
            if (!sent) {
                scheduleNotifyFlush()
                return
            }
            pendingNotifies.removeFirst()
        }
        // Also covers a queue emptied by a disconnect rather than by a send.
        notifyRetries = 0
    }

    private fun scheduleNotifyFlush() {
        val attempts = notifyRetries + 1
        if (attempts > MAX_NOTIFY_RETRIES) {
            // One the stack keeps refusing is dropped so the rest of the queue can move,
            // rather than holding the whole server side silent for one frame.
            notifyRetries = 0
            pendingNotifies.removeFirstOrNull()
            if (pendingNotifies.isEmpty()) return
        } else {
            notifyRetries = attempts
        }
        handler.removeCallbacks(retryNotifies)
        handler.postDelayed(retryNotifies, NOTIFY_RETRY_DELAY_MS)
    }

    private val retryNotifies = Runnable { if (sessionKey != null) flushNotifies() }

    private fun deliverFromServer(address: String, frame: ByteArray) {
        val reassembler = serverReassemblers.getOrPut(address) { SharedBuysFraming.Reassembler() }
        reassembler.accept(frame)?.let {
            onEvent?.invoke(BluetoothEvent.Payload(it, BluetoothPeer(address, true)))
        }
    }

    private fun deliverFromClient(address: String, frame: ByteArray) {
        val reassembler = clientReassemblers.getOrPut(address) { SharedBuysFraming.Reassembler() }
        reassembler.accept(frame)?.let {
            onEvent?.invoke(BluetoothEvent.Payload(it, BluetoothPeer(address, false)))
        }
    }

    private fun acceptedTags(sessionKey: ByteArray): List<ByteArray> {
        val window = SharedBuysProfile.window()
        tagCache?.let { (cachedWindow, tags) -> if (cachedWindow == window) return tags }
        return SharedBuysProfile.acceptedTags(sessionKey, window).also { tagCache = window to it }
    }

    private fun payloadLimit(address: String): Int =
        SharedBuysProfile.payloadLimit(mtus[address] ?: SharedBuysProfile.DEFAULT_ATT_MTU)

    /**
     * Peer state is touched from binder threads and from the app thread both.
     *
     * clients, subscribers, verifiedCentrals and the reassemblers are plain collections,
     * so send() iterating them on the app thread while a disconnect removed from them on
     * a binder thread was a ConcurrentModificationException on a routine walk-away. Every
     * callback hands its work to the main thread, which also means Compose state is
     * mutated where Compose expects it.
     */
    private fun confined(work: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) work() else handler.post(work)
    }

    /**
     * The peripheral half of the handshake: answer a challenge, then check the confirm.
     *
     * Any challenge gets an answer, since a stranger learns nothing from a MAC over a
     * nonce it chose and one we chose; only a central that proves the key in its confirm
     * is let in, and one that fails is disconnected.
     */
    private fun answer(frame: SharedBuysHandshake.Frame, device: BluetoothDevice) {
        val key = handshakeKey ?: return
        val address = device.address
        when (frame) {
            is SharedBuysHandshake.Frame.Challenge -> {
                val nonce = SharedBuysHandshake.nonce()
                if (!responses.containsKey(address) && responses.size >= MAX_PENDING_RESPONSES) {
                    responses.keys.firstOrNull()?.let { responses.remove(it) }
                }
                responses[address] = frame.nonce to nonce
                notify(SharedBuysHandshake.response(frame.nonce, nonce, key), device)
            }
            is SharedBuysHandshake.Frame.Confirm -> {
                val pending = responses.remove(address)
                if (pending == null ||
                    !SharedBuysHandshake.verifiesConfirm(frame.mac, pending.first, pending.second, key)
                ) {
                    runCatching { server?.cancelConnection(device) }
                    return
                }
                verifiedCentrals.add(address)
                onEvent?.invoke(BluetoothEvent.PeerCount(peerCount))
                // We never scanned this one, so its digest is unknown.
                onEvent?.invoke(BluetoothEvent.PeerVerified(BluetoothPeer(address, true), null))
            }
            is SharedBuysHandshake.Frame.Response -> Unit
        }
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) = confined {
            advertisedWindow = pendingAdvertisedWindow
            advertiseAttempts = 0
        }

        override fun onStartFailure(errorCode: Int) = confined {
            advertisedWindow = null
            onEvent?.invoke(BluetoothEvent.Unavailable("advertise failed $errorCode"))
            scheduleAdvertiseRetry()
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) = confined {
            if (!shouldConnect(result)) return@confined
            val address = result.device.address
            if (clients.containsKey(address)) return@confined
            val key = sessionKey ?: return@confined
            // A peer that carries no room bytes is not necessarily a stranger — an iOS
            // app in the background cannot advertise a local name — so it still gets a
            // chance at the handshake. One that carries the wrong room is a stranger,
            // and connecting to it could only end in a failed handshake.
            val advertisement = SharedBuysProfile.advertisement(
                result.scanRecord?.getServiceData(ParcelUuid(SharedBuysProfile.SERVICE_UUID)),
                result.scanRecord?.deviceName
            )
            if (advertisement != null) {
                val tag = advertisement.copyOf(2)
                if (acceptedTags(key).none { it.contentEquals(tag) }) {
                    rejectedUntil[address] = System.currentTimeMillis() + 60_000L
                    return@confined
                }
                peerDigests[address] = SharedBuysProfile.digest(advertisement)
            }
            val gatt = result.device.connectGatt(context, false, gattCallback) ?: return@confined
            clients[address] = gatt
            armHandshakeDeadline(gatt)
        }

        override fun onScanFailed(errorCode: Int) = confined {
            onEvent?.invoke(BluetoothEvent.Unavailable("scan failed $errorCode"))
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) = confined {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                if (!gatt.requestMtu(MTU)) gatt.discoverServices()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                val address = gatt.device.address
                if (clients[address] === gatt) forget(address) else runCatching { gatt.close() }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) = confined {
            // Discovery has to proceed either way; only the size is conditional, since a
            // failed negotiation leaves the link at the 23 byte default.
            if (status == BluetoothGatt.GATT_SUCCESS) mtus[gatt.device.address] = mtu
            gatt.discoverServices()
            Unit
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) = confined {
            val service = gatt.getService(SharedBuysProfile.SERVICE_UUID) ?: return@confined
            service.getCharacteristic(SharedBuysProfile.INBOX_UUID)?.let {
                inboxes[gatt.device.address] = it
            }
            val characteristic = service.getCharacteristic(SharedBuysProfile.OUTBOX_UUID)
            if (characteristic == null) {
                reject(gatt)
                return@confined
            }
            gatt.setCharacteristicNotification(characteristic, true)
            val descriptor = characteristic.getDescriptor(CLIENT_CONFIG_UUID)
            if (descriptor == null) {
                reject(gatt)
                return@confined
            }
            descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            runCatching { gatt.writeDescriptor(descriptor) }
            Unit
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int
        ) = confined {
            if (handshakeKey == null) return@confined
            // Without notifications enabled the peripheral has no way to answer, so the
            // link is dead: drop it now rather than holding a GATT slot until the
            // handshake deadline expires.
            if (status != BluetoothGatt.GATT_SUCCESS) {
                reject(gatt)
                return@confined
            }
            val challenge = SharedBuysHandshake.nonce()
            challenges[gatt.device.address] = challenge
            enqueueWrite(gatt, SharedBuysHandshake.challenge(challenge))
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) = confined {
            writing.remove(gatt.device.address)
            pumpWrites(gatt)
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            val value = characteristic.value?.copyOf() ?: return
            confined { received(gatt, value) }
        }

        private fun received(gatt: BluetoothGatt, value: ByteArray) {
            val address = gatt.device.address
            val frame = SharedBuysHandshake.parse(value)
            if (frame != null) {
                // The central half of the handshake: the peripheral must answer our own
                // challenge, and only then do we prove the key back to it.
                val key = handshakeKey
                val challenge = challenges.remove(address)
                if (key == null || challenge == null || frame !is SharedBuysHandshake.Frame.Response ||
                    !SharedBuysHandshake.verifiesResponse(frame.mac, challenge, frame.nonce, key)
                ) {
                    reject(gatt)
                    return
                }
                enqueueWrite(gatt, SharedBuysHandshake.confirm(challenge, frame.nonce, key))
                verifiedClients.add(address)
                onEvent?.invoke(BluetoothEvent.PeerCount(peerCount))
                onEvent?.invoke(BluetoothEvent.PeerVerified(BluetoothPeer(address, false), peerDigests[address]))
                return
            }
            if (!verifiedClients.contains(address)) return
            deliverFromClient(address, value)
        }
    }

    private val serverCallback = object : BluetoothGattServerCallback() {
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) = confined {
            val frame = SharedBuysHandshake.parse(value)
            if (frame != null) {
                answer(frame, device)
            } else if (verifiedCentrals.contains(device.address)) {
                deliverFromServer(device.address, value)
            }
            if (responseNeeded) {
                server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
            }
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) = confined {
            flushNotifies()
        }

        // The peer drives negotiation when we are the server, so the size arrives here
        // rather than from a request of ours.
        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) = confined {
            mtus[device.address] = mtu
            Unit
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) = confined {
            if (value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
                subscribers.add(device)
            } else {
                forgetCentral(device)
                onEvent?.invoke(BluetoothEvent.PeerCount(peerCount))
            }
            if (responseNeeded) {
                server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
            }
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) = confined {
            if (newState == BluetoothProfile.STATE_CONNECTED) armHandshakeDeadline(device)
            if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                forgetCentral(device)
                serverReassemblers.remove(device.address)
                responses.remove(device.address)
                pendingNotifies.removeAll { it.second.address == device.address }
                onEvent?.invoke(BluetoothEvent.PeerCount(peerCount))
            }
        }
    }
}
