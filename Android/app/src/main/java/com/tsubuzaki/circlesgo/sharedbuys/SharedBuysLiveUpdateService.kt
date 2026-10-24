package com.tsubuzaki.circlesgo.sharedbuys

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.tsubuzaki.circlesgo.MainActivity
import com.tsubuzaki.circlesgo.R

/**
 * The Live Update: an ongoing notification that follows the shared list for as long as
 * the session runs, and goes away with it.
 *
 * It is a foreground service because the session outlives the activity — a push can
 * arrive with the app swiped away, and the sync that answers it needs a socket the
 * platform will not kill mid-catch-up.
 */
class SharedBuysLiveUpdateService : Service() {

    private var session: SharedBuysSession? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val current = session ?: SharedBuysHost.session(this).also { session = it }
        startForeground(NOTIFICATION_ID, notification(this, current))
        if (!current.isActive) {
            stopSelf()
            return START_NOT_STICKY
        }
        current.onChanged = { refresh() }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        session?.onChanged = null
        session = null
    }

    private fun refresh() {
        val current = session ?: return
        if (!current.isActive) {
            stopSelf()
            return
        }
        NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, notification(this, current))
    }

    companion object {

        const val NOTIFICATION_ID = 4801

        fun start(context: Context) {
            val intent = Intent(context, SharedBuysLiveUpdateService::class.java)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SharedBuysLiveUpdateService::class.java))
            NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
        }

        private fun channel(context: Context) {
            val channel = NotificationChannel(
                context.getString(R.string.shared_buys_channel_id),
                context.getString(R.string.shared_buys_channel_name),
                NotificationManager.IMPORTANCE_LOW
            )
            channel.setShowBadge(false)
            NotificationManagerCompat.from(context).createNotificationChannel(channel)
        }

        private fun notification(context: Context, session: SharedBuysSession): Notification {
            channel(context)
            val mine = session.items.filter {
                it.assignee == session.actorPid && !it.isRemoved && it.status != SharedBuyStatus.CANCELLED
            }
            val bought = mine.count { it.status == SharedBuyStatus.BOUGHT }
            val next = mine.firstOrNull { it.status == SharedBuyStatus.PENDING }
            val title = next?.name ?: context.getString(R.string.shared_buys_live_done)
            val text = if (next != null) {
                context.getString(R.string.shared_buys_live_next, next.cost, bought, mine.size)
            } else {
                context.getString(R.string.shared_buys_live_progress, bought, mine.size)
            }
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_IMMUTABLE
            )
            val builder = NotificationCompat.Builder(context, context.getString(R.string.shared_buys_channel_id))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(open)
                .setOngoing(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_PROGRESS)
                .setPriority(NotificationCompat.PRIORITY_LOW)
            if (Build.VERSION.SDK_INT >= 36 && mine.isNotEmpty()) {
                builder.setStyle(
                    NotificationCompat.ProgressStyle()
                        .setProgress(bought)
                        .setProgressSegments(
                            mine.map { NotificationCompat.ProgressStyle.Segment(1) }
                        )
                )
            } else if (mine.isNotEmpty()) {
                builder.setProgress(mine.size, bought, false)
            }
            return builder.build()
        }
    }
}
