package com.example.ai_voice_chat

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class WhatsAppAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "ADAM_WA"
        var instance: WhatsAppAccessibilityService? = null
        var shouldAutoSend      = false
        var shouldAutoVoiceCall = false
        var shouldAutoVideoCall = false

        // ── Accessibility services can launch activities even on Vivo ──
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
                Log.d(TAG, "✅ Accessibility launched: $url")
                true
            } catch (e: Exception) {
                Log.e(TAG, "❌ Accessibility launch failed: $e")
                false
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "✅ ADAM_WA Service connected")
        val info = serviceInfo ?: AccessibilityServiceInfo()
        info.eventTypes =
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
            AccessibilityEvent.TYPE_VIEW_FOCUSED
        info.packageNames = arrayOf("com.whatsapp", "com.whatsapp.w4b")
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags =
            AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
            AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 50
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val pkg = event?.packageName?.toString() ?: return
        if (!pkg.contains("whatsapp")) return
        if (!shouldAutoSend && !shouldAutoVoiceCall && !shouldAutoVideoCall) return

        // Debounce — act 600ms after last event
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({ performAction() }, 600)
    }

    private fun performAction() {
        val root = rootInActiveWindow ?: run {
            Log.e(TAG, "ADAM_WA: root is null — retrying in 500ms")
            handler.postDelayed({ performAction() }, 500)
            return
        }

        val success = when {
            shouldAutoSend      -> tapSend(root)
            shouldAutoVoiceCall -> tapVoiceCall(root)
            shouldAutoVideoCall -> tapVideoCall(root)
            else -> false
        }

        if (!success) {
            Log.e(TAG, "ADAM_WA: Action failed — retrying in 500ms")
            handler.postDelayed({ performAction() }, 500)
        }
    }

    // ── Send: confirmed ID on this device ──
    private fun tapSend(root: AccessibilityNodeInfo): Boolean {
        // Primary: confirmed working ID
        if (clickById(root, "com.whatsapp:id/send", "send")) return true

        // Fallbacks
        val ids = listOf(
            "com.whatsapp:id/conversation_send_button",
            "com.whatsapp:id/entry_send_button",
            "com.whatsapp.w4b:id/send",
        )
        for (id in ids) { if (clickById(root, id, "send")) return true }
        return clickByDesc(root, listOf("Send", "send"), "send")
    }

    // ── Voice call: confirmed by description on this device ──
    private fun tapVoiceCall(root: AccessibilityNodeInfo): Boolean {
        // Primary: confirmed working — no ID, just description
        if (clickByDesc(root, listOf("Voice call", "voice call"), "voiceCall")) return true

        // Fallbacks with ID
        val ids = listOf(
            "com.whatsapp:id/conversation_header_call",
            "com.whatsapp:id/voice_call_btn",
            "com.whatsapp:id/call_icon",
            "com.whatsapp.w4b:id/conversation_header_call",
        )
        for (id in ids) { if (clickById(root, id, "voiceCall")) return true }
        return false
    }

    // ── Video call: confirmed by description on this device ──
    private fun tapVideoCall(root: AccessibilityNodeInfo): Boolean {
        // Primary: confirmed working — no ID, just description
        if (clickByDesc(root, listOf("Video call", "video call"), "videoCall")) return true

        // Fallbacks with ID
        val ids = listOf(
            "com.whatsapp:id/conversation_header_video_call",
            "com.whatsapp:id/video_call_btn",
            "com.whatsapp.w4b:id/conversation_header_video_call",
        )
        for (id in ids) { if (clickById(root, id, "videoCall")) return true }
        return false
    }

    private fun clickById(root: AccessibilityNodeInfo, id: String, action: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByViewId(id)
        if (!nodes.isNullOrEmpty()) {
            for (node in nodes) {
                if (node.isEnabled) {
                    val ok = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    if (ok) {
                        Log.d(TAG, "ADAM_WA: ✅ $action clicked by id: $id")
                        clearFlag(action)
                        if (action == "send") bringAdamToFront()
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun clickByDesc(
        node: AccessibilityNodeInfo?,
        targets: List<String>,
        action: String
    ): Boolean {
        if (node == null) return false
        val desc = node.contentDescription?.toString() ?: ""
        val text = node.text?.toString() ?: ""
        if (targets.any { desc.equals(it, true) || text.equals(it, true) } && node.isEnabled) {
            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            Log.d(TAG, "ADAM_WA: ✅ $action clicked by desc: '$desc'")
            clearFlag(action)
            if (action == "send") bringAdamToFront()
            return true
        }
        for (i in 0 until node.childCount) {
            if (clickByDesc(node.getChild(i), targets, action)) return true
        }
        return false
    }

    private fun clearFlag(action: String) {
        when (action) {
            "send"      -> shouldAutoSend      = false
            "voiceCall" -> shouldAutoVoiceCall = false
            "videoCall" -> shouldAutoVideoCall = false
        }
    }

    private fun bringAdamToFront() {
        handler.postDelayed({
            try {
                val i = Intent(applicationContext, MainActivity::class.java)
                i.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                          Intent.FLAG_ACTIVITY_NEW_TASK or
                          Intent.FLAG_ACTIVITY_SINGLE_TOP
                startActivity(i)
                Log.d(TAG, "ADAM_WA: ✅ ADAM brought to front")
            } catch (e: Exception) {
                Log.e(TAG, "ADAM_WA: bring to front failed: $e")
            }
        }, 1000)
    }

    override fun onInterrupt() { handler.removeCallbacksAndMessages(null) }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        instance = null
        super.onDestroy()
    }
}