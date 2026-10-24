package com.tsubuzaki.circlesgo.sharedbuys

import android.content.Context
import com.google.firebase.messaging.FirebaseMessaging

/**
 * The FCM registration token, cached so a hello can carry it without waiting on Firebase.
 *
 * The token is the only thing the relay learns about this device beyond its room; the
 * payload it wakes us with carries no content at all.
 */
object SharedBuysPush {

    private const val PREFERENCES = "SharedBuys"
    private const val TOKEN_KEY = "PushToken"

    fun token(context: Context): String? =
        context.applicationContext
            .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(TOKEN_KEY, null)

    fun store(context: Context, token: String) {
        context.applicationContext
            .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(TOKEN_KEY, token)
            .apply()
    }

    /** Fetches the token if it is not cached yet, reconnecting once so the relay learns it. */
    fun refresh(context: Context, onFresh: (String) -> Unit) {
        val known = token(context)
        FirebaseMessaging.getInstance().token.addOnSuccessListener { token ->
            if (token.isNullOrEmpty() || token == known) return@addOnSuccessListener
            store(context, token)
            onFresh(token)
        }
    }
}
