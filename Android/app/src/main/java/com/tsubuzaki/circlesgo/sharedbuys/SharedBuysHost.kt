package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

/**
 * The one session in the process.
 *
 * A push arrives with no activity behind it, so the session can no longer belong to
 * MainActivity: the messaging service and the live update need the same log, the same
 * socket and the same store the UI is holding, or two sessions write over each other's
 * snapshot.
 */
object SharedBuysHost {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var session: SharedBuysSession? = null

    @Synchronized
    fun session(context: Context): SharedBuysSession {
        val existing = session
        if (existing != null) return existing
        val created = SharedBuysSession(context.applicationContext, scope)
        session = created
        created.restore()
        return created
    }

    @Synchronized
    fun sessionOrNull(): SharedBuysSession? = session
}
