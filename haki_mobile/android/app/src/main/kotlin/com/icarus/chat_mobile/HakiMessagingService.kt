package com.sleepless_icarus.haki

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Firebase Cloud Messaging. Message pushes carry a notification block the system shows by itself
 * (no names or text, like on iOS). Call pushes are data-only: we show a full-screen "Incoming call"
 * that opens Haki, which reconnects and picks up the ringing call.
 */
class HakiMessagingService : FirebaseMessagingService() {
    companion object {
        var onToken: ((String) -> Unit)? = null

        /** False when this build has no Firebase config (no google-services.json). */
        fun fetchToken(context: Context, done: (String) -> Unit): Boolean {
            if (FirebaseApp.getApps(context).isEmpty()) return false
            FirebaseMessaging.getInstance().token.addOnSuccessListener { done(it) }
            return true
        }
    }

    override fun onNewToken(token: String) {
        onToken?.invoke(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        if (message.data["kind"] != "call") return
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(NotificationChannel("calls", "Calls", NotificationManager.IMPORTANCE_HIGH))
        }
        val open = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra("chat", message.data["chat"])
        val pi = PendingIntent.getActivity(this, 1, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "calls") else Notification.Builder(this)
        builder.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Haki")
            .setContentText("Incoming call")
            .setCategory(Notification.CATEGORY_CALL)
            .setFullScreenIntent(pi, true)
            .setContentIntent(pi)
            .setAutoCancel(true)
        if (Build.VERSION.SDK_INT >= 26) builder.setTimeoutAfter(30_000)
        nm.notify(1001, builder.build())
    }
}
