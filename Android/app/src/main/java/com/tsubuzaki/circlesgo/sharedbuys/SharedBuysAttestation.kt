package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import com.google.android.gms.tasks.Task
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.tsubuzaki.circlesgo.BuildConfig
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Play Integrity evidence for the relay's X-Circles-Attest header.
 *
 * The token provider is the expensive half — it warms up against Google's servers once
 * and then mints a token per request — so it is prepared lazily and kept. It goes stale
 * after about an hour, and the only way that surfaces is a failed request, so a failure
 * drops the provider and prepares a new one before giving up.
 *
 * Returns null on a device with no usable Play services rather than throwing: the relay
 * treats absent evidence as unattested, which is the honest answer for such a device.
 */
object SharedBuysAttestation {

    private val mutex = Mutex()
    private var provider: StandardIntegrityTokenProvider? = null

    suspend fun evidence(context: Context, roomId: String, hello: ByteArray): JsonObject? {
        val project = BuildConfig.PLAY_PROJECT_NUMBER.toLongOrNull() ?: return null
        val hash = SharedBuysCrypto.requestHash(roomId, hello)
        val token = token(context, project, hash) ?: return null
        return buildJsonObject {
            put("t", "playintegrity")
            put("tk", token)
        }
    }

    /** Forgets the warmed-up provider, so the next hello prepares a fresh one. */
    suspend fun invalidate() {
        mutex.withLock { provider = null }
    }

    private suspend fun token(context: Context, project: Long, hash: String): String? {
        repeat(2) {
            val holder = mutex.withLock {
                provider ?: prepare(context, project)?.also { prepared -> provider = prepared }
            } ?: return null
            val request = StandardIntegrityTokenRequest.builder().setRequestHash(hash).build()
            val token = runCatching { holder.request(request).awaitResult().token() }.getOrNull()
            if (token != null) return token
            mutex.withLock { if (provider === holder) provider = null }
        }
        return null
    }

    private suspend fun prepare(context: Context, project: Long): StandardIntegrityTokenProvider? {
        val manager = runCatching { IntegrityManagerFactory.createStandard(context.applicationContext) }
            .getOrNull() ?: return null
        val request = PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(project).build()
        return runCatching { manager.prepareIntegrityToken(request).awaitResult() }.getOrNull()
    }
}

private suspend fun <T> Task<T>.awaitResult(): T = suspendCancellableCoroutine { continuation ->
    addOnSuccessListener { continuation.resume(it) }
    addOnFailureListener { continuation.resumeWithException(it) }
}
