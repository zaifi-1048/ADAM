package com.example.ai_voice_chat

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class ADAMForegroundService : Service() {

    companion object {
        private const val TAG      = "ADAM_Service"
        const val CHANNEL_ID       = "adam_wake_word_channel"
        const val NOTIFICATION_ID  = 2001
        var isRunning              = false
        var instance: ADAMForegroundService? = null

        // ── Launch URL from foreground service context ──
        // Foreground services CAN start activities on Android 10+
        fun launchUrl(url: String): Boolean {
            val svc = instance ?: return false
            return try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                intent.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                )
                svc.startActivity(intent)
                Log.d(TAG, "✅ Service launched: $url")
                true
            } catch (e: Exception) {
                Log.e(TAG, "❌ Service launch failed: $url → $e")
                false
            }
        }

        fun requestPopupPermission(context: android.content.Context) {
            try {
                // Open Vivo/Android "Display over other apps" settings
                val intent = Intent(
                    android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${context.packageName}")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Cannot open overlay settings: $e")
            }
        }

        // ── Bring ADAM to front from service context ──
        fun bringToFront(): Boolean {
            val svc = instance ?: return false
            return try {
                val intent = Intent(svc.applicationContext, MainActivity::class.java)
                intent.addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                svc.startActivity(intent)
                Log.d(TAG, "✅ Service brought ADAM to front")
                true
            } catch (e: Exception) {
                Log.e(TAG, "❌ Service bringToFront failed: $e")
                false
            }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        instance  = this
        Log.d(TAG, "ADAM Foreground Service created")
        createNotificationChannel()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "ADAM Foreground Service started")
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "ADAM Wake Word",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "ADAM is listening for wake word"
            setShowBadge(false)
            enableLights(false)
            enableVibration(false)
            setSound(null, null)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pi = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ADAM is listening")
            .setContentText("Say \"Hey ADAM\" to activate")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setSilent(true)
            .build()
    }

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "ADAM::BackgroundListeningLock"
            )
            wakeLock?.acquire()
            Log.d(TAG, "WakeLock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock failed: $e")
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        val restartIntent = Intent(applicationContext, ADAMForegroundService::class.java)
        val pi = PendingIntent.getService(
            this, 1, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        (getSystemService(ALARM_SERVICE) as AlarmManager).set(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + 1000,
            pi
        )
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        isRunning = false
        instance  = null
        try { if (wakeLock?.isHeld == true) wakeLock?.release() } catch (_: Exception) {}
        Log.d(TAG, "ADAM Foreground Service destroyed")
        super.onDestroy()
    }
}