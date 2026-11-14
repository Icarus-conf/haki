package com.sleepless_icarus.haki

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/** Same "haki/push" channel as iOS: register for pushes, hand over the chat a notification opened. */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingChat: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel("messages", "Messages", NotificationManager.IMPORTANCE_HIGH)
            )
        }
        pendingChat = chatFrom(intent)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "haki/push")
        channel = ch
        HakiMessagingService.onToken = { t -> runOnUiThread { ch.invokeMethod("token", t) } }
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "register" -> register(result)
                "takePendingChat" -> {
                    result.success(pendingChat)
                    pendingChat = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val chat = chatFrom(intent) ?: return
        pendingChat = chat
        channel?.invokeMethod("open", chat)
    }

    private fun register(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
        }
        val ok = HakiMessagingService.fetchToken(this) { t -> runOnUiThread { channel?.invokeMethod("token", t) } }
        if (ok) result.success(true)
        else result.error("unconfigured", "Firebase isn't set up in this build (add android/app/google-services.json).", null)
    }

    /** FCM puts the data fields in the launch intent's extras; "chat" is JSON like {"u":3}. */
    private fun chatFrom(intent: Intent?): Map<String, Any>? {
        val raw = intent?.getStringExtra("chat") ?: return null
        return try {
            val j = JSONObject(raw)
            j.keys().asSequence().associateWith { j.getInt(it) as Any }
        } catch (e: Exception) {
            null
        }
    }
}
