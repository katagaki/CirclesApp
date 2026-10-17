package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class SharedBuysSnapshot(
    val sessionKey: String,
    val deviceId: String,
    val deviceAuthKey: String? = null,
    val signingKey: String? = null,
    val eventNumber: Int,
    val lastSeq: Long,
    val changes: List<SharedBuyChange>,
    val clock: Long? = null,
    val agreementKey: String? = null,
    val agreementPublicKey: String? = null,
    val ownerDevice: String? = null
)

class SharedBuysStore(context: Context) {

    private val preferences =
        context.getSharedPreferences("shared_buys", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false }

    fun load(): SharedBuysSnapshot? {
        val raw = preferences.getString("snapshot", null) ?: return null
        return runCatching { json.decodeFromString<SharedBuysSnapshot>(raw) }.getOrNull()
    }

    fun save(snapshot: SharedBuysSnapshot) {
        preferences.edit().putString("snapshot", json.encodeToString(snapshot)).apply()
    }

    fun clear() {
        preferences.edit().remove("snapshot").apply()
    }
}
