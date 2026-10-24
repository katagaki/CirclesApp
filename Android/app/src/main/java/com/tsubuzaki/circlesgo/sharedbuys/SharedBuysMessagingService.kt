package com.tsubuzaki.circlesgo.sharedbuys

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * The wake-up path.
 *
 * The relay holds no key, so the message it sends carries no content — only that
 * something changed. Everything the user reads is folded here, from the log, after the
 * catch-up lands.
 */
class SharedBuysMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        SharedBuysPush.store(this, token)
        val session = SharedBuysHost.sessionOrNull() ?: return
        if (session.isActive) session.connect()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        if (message.data["t"] != "sync") return
        val session = SharedBuysHost.session(applicationContext)
        if (!session.isActive) return
        SharedBuysLiveUpdateService.start(applicationContext)
        session.resume()
    }
}
