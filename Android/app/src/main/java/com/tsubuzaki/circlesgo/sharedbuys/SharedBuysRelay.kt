package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.ResponseException
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.client.plugins.websocket.webSocketSession
import io.ktor.websocket.Frame
import io.ktor.websocket.close
import io.ktor.websocket.readText
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.consumeEach
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.long
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

data class RelayRecord(val device: String, val seq: Long, val blob: String, val tag: String)

sealed interface RelayEvent {
    data object Connected : RelayEvent
    data class Records(val records: List<RelayRecord>) : RelayEvent

    /** How much of this device's own history the relay holds, as a gapless prefix. */
    data class Held(val seq: Long) : RelayEvent
    data class Failed(val reason: String) : RelayEvent

    /**
     * The relay closed the socket cleanly.
     *
     * consumeEach returns normally on a close frame and runCatching succeeds, so a clean
     * close used to fire no event at all: when the room's 48 hour alarm closed sockets
     * with 1001, iOS reconnected and Android sat at "connected", dark, until the app was
     * restarted.
     */
    data class Closed(val code: Int) : RelayEvent
}

class SharedBuysRelay(private val context: Context, private val scope: CoroutineScope) {

    data class Endpoint(
        val baseUrl: String,
        val roomId: String,
        val deviceId: String,
        val deviceAuthKey: ByteArray,
        val sessionKey: ByteArray,
        val vector: Map<String, Long>,
        val pushToken: String? = null
    )

    private val client = HttpClient(OkHttp) {
        expectSuccess = true
        install(WebSockets)
    }
    private val json = Json { ignoreUnknownKeys = true }
    private var session: io.ktor.websocket.WebSocketSession? = null
    private var job: Job? = null
    private var sentEvidence = false
    private var suppressClose = false

    fun connect(endpoint: Endpoint, onEvent: (RelayEvent) -> Unit) {
        disconnect()
        job = scope.launch {
            runCatching {
                suppressClose = false
                val hello = helloFrame(endpoint).toByteArray(Charsets.UTF_8)
                val evidence = SharedBuysAttestation.evidence(context, endpoint.roomId, hello)
                sentEvidence = evidence != null
                val socket = client.webSocketSession("${endpoint.baseUrl}/r/${endpoint.roomId}") {
                    headers.append("X-Circles-Hello", hello.toBase64Url())
                    evidence?.let {
                        headers.append("X-Circles-Attest", it.toString().toByteArray(Charsets.UTF_8).toBase64Url())
                    }
                }
                session = socket
                onEvent(RelayEvent.Connected)
                var lastPongAt = 0L
                var heldSeen = false
                val heartbeat = launch {
                    while (true) {
                        kotlinx.coroutines.delay(HEARTBEAT_INTERVAL_MS)
                        val sentAt = System.currentTimeMillis()
                        socket.send(Frame.Text("ping"))
                        kotlinx.coroutines.delay(HEARTBEAT_TIMEOUT_MS)
                        if (lastPongAt < sentAt) {
                            socket.close()
                            return@launch
                        }
                    }
                }
                socket.incoming.consumeEach { frame ->
                    if (frame is Frame.Text) {
                        val text = frame.readText()
                        if (text == "pong") lastPongAt = System.currentTimeMillis()
                        else heldSeen = handle(text, heldSeen, onEvent)
                    }
                }
                heartbeat.cancel()
                if (!suppressClose) {
                    onEvent(RelayEvent.Closed(socket.closeReason.await()?.code?.toInt() ?: 1006))
                }
            }.onFailure {
                if (it !is kotlinx.coroutines.CancellationException) {
                    val refusal = (it as? ResponseException)?.let { error -> REFUSAL_SLUGS[error.response.status.value] }
                    val code = refusal?.let(::errorSlug) ?: it.message ?: "socket error"
                    onEvent(RelayEvent.Failed(code))
                }
            }
        }
    }

    fun disconnect(records: List<RelayRecord> = emptyList()) {
        job?.cancel()
        job = null
        val socket = session
        session = null
        if (socket != null) {
            scope.launch {
                runCatching {
                    pages(records).forEach { socket.send(Frame.Text(opsFrame(it))) }
                    socket.close()
                }
            }
        }
    }

    /**
     * Disconnects and releases the HTTP client.
     *
     * The Ktor client owns an OkHttp connection pool and its dispatcher threads; leaving
     * it open leaked both on every activity recreation, a rotation included.
     */
    fun close() {
        disconnect()
        runCatching { client.close() }
    }

    fun send(records: List<RelayRecord>, onEvent: (RelayEvent) -> Unit = {}) {
        val socket = session
        if (socket == null) {
            onEvent(RelayEvent.Failed("no socket"))
            return
        }
        if (records.isEmpty()) return
        val frames = pages(records).map(::opsFrame)
        scope.launch {
            for (frame in frames) {
                val sent = runCatching { socket.send(Frame.Text(frame)) }
                    .onFailure { onEvent(RelayEvent.Failed("send: ${it.message}")) }
                if (sent.isFailure) break
            }
        }
    }

    private fun opsFrame(records: List<RelayRecord>): String =
        buildJsonObject {
            put("t", "ops")
            put("o", kotlinx.serialization.json.buildJsonArray {
                records.forEach { record ->
                    add(buildJsonObject {
                        put("d", record.device)
                        put("n", record.seq)
                        put("b", record.blob)
                        put("a", record.tag)
                    })
                }
            })
        }.toString()

    /**
     * Whether the room key may be handed to this relay.
     *
     * The hello frame registers a room by uploading relayAuthKey, the same key that
     * backs every recordTag. Over ws:// anyone on the path recovers it and can forge
     * records for any device, so the key only travels over TLS — or to a development
     * server on this machine, which includes the emulator's alias for its host. A relay
     * that has not seen the key answers a hello with CLOSE_UNKNOWN_ROOM, which is a
     * diagnosable failure rather than a silent leak.
     */
    private fun allowsKeyUpload(baseUrl: String): Boolean {
        val url = runCatching { java.net.URI(baseUrl) }.getOrNull() ?: return false
        val scheme = url.scheme?.lowercase() ?: return false
        if (scheme == "wss" || scheme == "https") return true
        val host = url.host?.lowercase() ?: return false
        return host in listOf("localhost", "127.0.0.1", "::1", "10.0.2.2")
    }

    private fun helloFrame(endpoint: Endpoint): String {
        val relayAuthKey = SharedBuysCrypto.derive(
            SharedBuysCrypto.RELAY_AUTH_INFO,
            endpoint.sessionKey
        )
        val timestamp = System.currentTimeMillis() / 1000
        val tag = SharedBuysCrypto.helloTag(endpoint.deviceId, timestamp, relayAuthKey)
        val deviceTag = SharedBuysCrypto.helloTag(endpoint.deviceId, timestamp, endpoint.deviceAuthKey)
        return buildJsonObject {
            put("t", "hello")
            put("d", endpoint.deviceId)
            put("v", buildJsonObject {
                endpoint.vector.forEach { (device, seq) -> put(device, seq) }
            })
            if (allowsKeyUpload(endpoint.baseUrl)) put("k", relayAuthKey.toBase64Url())
            put("ts", timestamp)
            put("a", tag.toBase64Url())
            put("x", endpoint.deviceAuthKey.toBase64Url())
            put("da", deviceTag.toBase64Url())
            endpoint.pushToken?.let { token ->
                put("p", buildJsonObject {
                    put("pl", "fcm")
                    put("tk", token)
                })
            }
        }.toString()
    }

    /**
     * Maps a relay error slug, taking the permanent case out of the retry loop.
     *
     * UNATTESTED_SLUG replaces attest when we sent no attestation and the relay demanded
     * one: Play has nothing to say about this device, so reconnecting would be refused
     * identically every 30 seconds for the rest of the room's life. The close that
     * follows is swallowed so the session sees one terminal event. Only a refused
     * attestation drops the warmed-up provider; a bad or stale hello says nothing about it.
     */
    private fun errorSlug(code: String): String {
        if (code != "attest") return code
        scope.launch { SharedBuysAttestation.invalidate() }
        if (sentEvidence) return code
        suppressClose = true
        return UNATTESTED_SLUG
    }

    /** Handles one frame, returning whether the relay has reported what it holds. */
    private fun handle(text: String, heldSeen: Boolean, onEvent: (RelayEvent) -> Unit): Boolean {
        val frame = runCatching { json.parseToJsonElement(text).jsonObject }.getOrNull()
            ?: return heldSeen
        when ((frame["t"] as? JsonPrimitive)?.content) {
            "held" -> {
                val seq = runCatching { frame["n"]?.jsonPrimitive?.long }.getOrNull() ?: 0L
                onEvent(RelayEvent.Held(seq))
                return true
            }
            "ops" -> {
                // A relay that predates held answers the hello with ops alone, so it is
                // treated as holding nothing and gets everything re-sent.
                if (!heldSeen) onEvent(RelayEvent.Held(0L))
                // Parsed per record: a seq wider than Int used to throw out of the whole
                // mapNotNull, unwind consumeEach and tear the socket down, rather than
                // costing the one record that carried it.
                val records = frame["o"]?.jsonArray.orEmpty().mapNotNull { element ->
                    runCatching {
                        val entry = element.jsonObject
                        RelayRecord(
                            entry["d"]?.jsonPrimitive?.content ?: return@runCatching null,
                            entry["n"]?.jsonPrimitive?.long ?: return@runCatching null,
                            entry["b"]?.jsonPrimitive?.content ?: return@runCatching null,
                            entry["a"]?.jsonPrimitive?.content ?: return@runCatching null
                        )
                    }.getOrNull()
                }
                onEvent(RelayEvent.Records(records))
                return true
            }
            "err" -> onEvent(RelayEvent.Failed(errorSlug(frame["c"]?.jsonPrimitive?.content ?: "error")))
        }
        return heldSeen
    }
}

private fun List<kotlinx.serialization.json.JsonElement>?.orEmpty() =
    this ?: emptyList()

    private fun JsonObject.stringOrNull(key: String): String? =
    (this[key] as? JsonPrimitive)?.content

const val UNATTESTED_SLUG = "unattested"

/** Upgrade refusals by status: 403 is the attestation, 401 the hello itself. */
private val REFUSAL_SLUGS = mapOf(401 to "auth", 403 to "attest", 429 to "rate")

private const val HEARTBEAT_INTERVAL_MS = 240_000L
private const val HEARTBEAT_TIMEOUT_MS = 30_000L

/** The relay closes a socket whose text frame is larger than this (MAX_FRAME_BYTES). */
private const val MAX_FRAME_BYTES = 4096

/** The relay refuses a frame carrying more than this (MAX_RECORDS_PER_FRAME). */
const val MAX_RECORDS_PER_FRAME = 32

/**
 * Records grouped into frames the relay accepts, by count and by encoded size.
 *
 * A signed status flip is around 300 bytes once encoded, so 32 of them are more than
 * twice what one frame may carry, and the relay would close the socket for it.
 */
fun pages(records: List<RelayRecord>): List<List<RelayRecord>> {
    val frameOverhead = "{\"t\":\"ops\",\"o\":[]}".length
    val recordOverhead = "{\"d\":\"\",\"n\":,\"b\":\"\",\"a\":\"\"},".length
    val result = mutableListOf<List<RelayRecord>>()
    var page = mutableListOf<RelayRecord>()
    var size = frameOverhead
    for (record in records) {
        val cost = recordOverhead + record.device.length + record.seq.toString().length +
            record.blob.length + record.tag.length
        if (page.isNotEmpty() && (size + cost > MAX_FRAME_BYTES || page.size == MAX_RECORDS_PER_FRAME)) {
            result.add(page)
            page = mutableListOf()
            size = frameOverhead
        }
        page.add(record)
        size += cost
    }
    if (page.isNotEmpty()) result.add(page)
    return result
}
