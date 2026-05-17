package com.example.ai_voice_chat

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val DIALER_CHANNEL   = "com.example.ai_voice_chat/dialer"
    private val WHATSAPP_CHANNEL = "com.example.ai_voice_chat/whatsapp"
    private val SERVICE_CHANNEL  = "com.example.ai_voice_chat/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Dialer channel ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIALER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "makeCall" -> {
                        val number  = call.argument<String>("number") ?: ""
                        val simSlot = call.argument<Int>("simSlot") ?: 0
                        try {
                            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                            if (simSlot > 0) {
                                val slot = simSlot - 1
                                intent.putExtra("com.android.phone.extra.slot", slot)
                                intent.putExtra("simSlot",   slot)
                                intent.putExtra("simIndex",  slot)
                                intent.putExtra("slot",      slot)
                                intent.putExtra("com.samsung.android.phone.extra.slot", slot)
                                intent.putExtra("android.intent.extra.SIM_SLOT", slot)
                                intent.putExtra("com.huawei.android.phone.extra.slot", slot)
                            }
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            Handler(Looper.getMainLooper()).postDelayed({
                                try {
                                    val back = Intent(this, MainActivity::class.java)
                                    back.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                                 Intent.FLAG_ACTIVITY_NEW_TASK or
                                                 Intent.FLAG_ACTIVITY_SINGLE_TOP
                                    startActivity(back)
                                } catch (_: Exception) {}
                            }, 600)
                            result.success(true)
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", "CALL_PHONE not granted", null)
                        } catch (e: Exception) {
                            result.error("CALL_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── WhatsApp channel ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepareAutoSend"      -> { WhatsAppAccessibilityService.shouldAutoSend      = true; result.success(true) }
                    "prepareAutoVoiceCall" -> { WhatsAppAccessibilityService.shouldAutoVoiceCall = true; result.success(true) }
                    "prepareAutoVideoCall" -> { WhatsAppAccessibilityService.shouldAutoVideoCall = true; result.success(true) }
                    "autoSend"             -> { WhatsAppAccessibilityService.shouldAutoSend      = true; result.success(true) }
                    "autoVoiceCall"        -> { WhatsAppAccessibilityService.shouldAutoVoiceCall = true; result.success(true) }
                    "autoVideoCall"        -> { WhatsAppAccessibilityService.shouldAutoVideoCall = true; result.success(true) }
                    "isAccessibilityEnabled" -> result.success(WhatsAppAccessibilityService.instance != null)
                    else -> result.notImplemented()
                }
            }

        // ── Foreground Service channel ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startService" -> {
                        try {
                            val intent = Intent(this, ADAMForegroundService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SERVICE_ERROR", e.message, null)
                        }
                    }

                    "stopService" -> {
                        try {
                            stopService(Intent(this, ADAMForegroundService::class.java))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SERVICE_ERROR", e.message, null)
                        }
                    }

                    "isRunning" -> result.success(ADAMForegroundService.isRunning)

                    "bringToFront" -> {
                        try {
                            // Use foreground service for reliable bring-to-front
                            val ok = ADAMForegroundService.bringToFront()
                            if (!ok) {
                                // Fallback to MainActivity
                                val i = Intent(this, MainActivity::class.java)
                                i.addFlags(
                                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                    Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                                )
                                startActivity(i)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BRING_ERROR", e.message, null)
                        }
                    }

                    "setFlashlight" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        try {
                            val camManager = getSystemService(android.hardware.camera2.CameraManager::class.java)
                            val camId = camManager.cameraIdList[0]
                            camManager.setTorchMode(camId, on)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FLASH_ERROR", e.message, null)
                        }
                    }

                    "setVolume" -> {
                        val action = call.argument<String>("action") ?: "up"
                        try {
                            val audio = getSystemService(android.media.AudioManager::class.java)
                            when (action) {
                                "up"     -> audio.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_RAISE, android.media.AudioManager.FLAG_SHOW_UI)
                                "down"   -> audio.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_LOWER, android.media.AudioManager.FLAG_SHOW_UI)
                                "mute"   -> audio.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_MUTE, android.media.AudioManager.FLAG_SHOW_UI)
                                "unmute" -> audio.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_UNMUTE, android.media.AudioManager.FLAG_SHOW_UI)
                                "max"    -> audio.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, audio.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC), android.media.AudioManager.FLAG_SHOW_UI)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("VOLUME_ERROR", e.message, null)
                        }
                    }

                    "setAlarm" -> {
                        val hour   = call.argument<Int>("hour")    ?: 7
                        val minute = call.argument<Int>("minute")  ?: 0
                        val msg    = call.argument<String>("message") ?: "ADAM Alarm"
                        try {
                            val intent = Intent(android.provider.AlarmClock.ACTION_SET_ALARM).apply {
                                putExtra(android.provider.AlarmClock.EXTRA_HOUR, hour)
                                putExtra(android.provider.AlarmClock.EXTRA_MINUTES, minute)
                                putExtra(android.provider.AlarmClock.EXTRA_MESSAGE, msg)
                                putExtra(android.provider.AlarmClock.EXTRA_SKIP_UI, true)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ALARM_ERROR", e.message, null)
                        }
                    }

                    // ── Launch external URLs ──
                    // Routes through foreground service which has
                    // explicit permission to start activities on Android 10+
                    "launchUrl" -> {
                        val url = call.argument<String>("url") ?: ""
                        try {
                            // 1. Try accessibility service (bypasses Vivo restrictions)
                            if (WhatsAppAccessibilityService.launchUrl(url)) {
                                result.success(true)
                                return@setMethodCallHandler
                            }
                            // 2. Try foreground service
                            if (ADAMForegroundService.launchUrl(url)) {
                                result.success(true)
                                return@setMethodCallHandler
                            }
                            // 3. Fallback to MainActivity
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                                           Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LAUNCH_ERROR", "Could not launch: $url — ${e.message}", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}