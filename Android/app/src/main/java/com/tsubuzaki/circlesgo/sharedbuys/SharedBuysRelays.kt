package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import android.util.Log
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Where each feature's relay lives.
 *
 * The address is not in the repository: CI writes Relays.json into assets from the
 * RELAYS_JSON secret, exactly as it writes OpenID.json from OPENID_JSON. A build without
 * that file -- anyone's local checkout -- falls back to the development relay on the
 * host, which is the emulator's alias for the developer's own 127.0.0.1.
 */
object SharedBuysRelays {

    private const val TAG = "SharedBuysRelays"
    private const val ASSET = "Relays.json"

    const val SHARED_BUYS = "sharedBuys"
    const val DEVELOPMENT_BASE_URL = "ws://10.0.2.2:8787"

    private val json = Json { ignoreUnknownKeys = true }

    fun baseUrl(context: Context, featureId: String = SHARED_BUYS): String {
        val configured = runCatching {
            context.assets.open(ASSET).bufferedReader().use { it.readText() }
        }.mapCatching { text ->
            json.parseToJsonElement(text).jsonObject[featureId]?.jsonPrimitive?.content
        }.onFailure {
            Log.i(TAG, "no relay configured for $featureId, using the development relay")
        }.getOrNull()

        return if (configured.isNullOrBlank()) DEVELOPMENT_BASE_URL else webSocketScheme(configured)
    }

    /**
     * Rewrites an http(s) address to its WebSocket equivalent.
     *
     * The published address is written as a URL people can paste into a browser; the
     * socket needs ws/wss. Anything already ws/wss, and anything unrecognised, is left
     * exactly as it was given.
     */
    fun webSocketScheme(baseUrl: String): String = when {
        baseUrl.startsWith("https://") -> "wss://" + baseUrl.removePrefix("https://")
        baseUrl.startsWith("http://") -> "ws://" + baseUrl.removePrefix("http://")
        else -> baseUrl
    }.trimEnd('/')
}
