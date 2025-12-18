package com.vnsshop.ecommerce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.google.firebase.messaging.RemoteMessage
import com.hiennv.flutter_callkit_incoming.CallkitConstants
import com.hiennv.flutter_callkit_incoming.CallkitNotificationManager
import com.hiennv.flutter_callkit_incoming.CallkitSoundPlayerManager
import com.hiennv.flutter_callkit_incoming.Data
import com.hiennv.flutter_callkit_incoming.addCall
import com.hiennv.flutter_callkit_incoming.getDataActiveCalls
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingUtils
import java.util.Locale

/**
 * Show CallKit (notification full-screen) for incoming 1-1 call when app is background/killed.
 *
 * Why: In killed-state, Dart background isolate can receive FCM but MethodChannel for
 * flutter_callkit_incoming may hang -> no UI. Native receiver avoids depending on Flutter engine.
 */
class CallInviteMessagingReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return

        val remoteMessage = try {
            RemoteMessage(extras)
        } catch (_: Exception) {
            return
        }

        val data = remoteMessage.data
        if (data.isNullOrEmpty()) return

        // Only handle 1-1 call invite
        val type = (data["type"] ?: "").trim()
        if (type != "call_invite") return

        // Avoid duplicates when app is in foreground (foreground flow is already good)
        if (FlutterFirebaseMessagingUtils.isApplicationForeground(context)) return

        val callIdRaw = (data["call_id"] ?: data["id"] ?: data["callId"] ?: "").trim()
        if (callIdRaw.isEmpty()) return

        val callerName = (data["caller_name"] ?: data["name"] ?: "Cuộc gọi đến").toString()
        val avatar = (data["caller_avatar"] ?: data["avatar"] ?: "").toString()
        val media = (data["media"] ?: data["media_type"] ?: "audio").toString()
            .lowercase(Locale.ROOT)
        val isVideo = media == "video"

        val systemId = makeSystemUuidFromServerId(callIdRaw)

        // Debounce: if call already in ACTIVE_CALLS, skip showing again.
        try {
            val active = getDataActiveCalls(context)
            if (active.any { it.id.equals(systemId, ignoreCase = true) }) return
        } catch (_: Exception) {
        }

        val b = Bundle()
        b.putString(CallkitConstants.EXTRA_CALLKIT_ID, systemId)
        b.putString(CallkitConstants.EXTRA_CALLKIT_NAME_CALLER, callerName)
        b.putString(CallkitConstants.EXTRA_CALLKIT_APP_NAME, "VNShop247")
        b.putString(CallkitConstants.EXTRA_CALLKIT_HANDLE, callerName)
        b.putString(CallkitConstants.EXTRA_CALLKIT_AVATAR, avatar)
        b.putInt(CallkitConstants.EXTRA_CALLKIT_TYPE, if (isVideo) 1 else 0)
        b.putLong(CallkitConstants.EXTRA_CALLKIT_DURATION, 60000L)
        b.putString(CallkitConstants.EXTRA_CALLKIT_TEXT_ACCEPT, "Nghe")
        b.putString(CallkitConstants.EXTRA_CALLKIT_TEXT_DECLINE, "Từ chối")

        // Match app's CallKit config
        b.putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_CUSTOM_NOTIFICATION, true)
        b.putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_SHOW_FULL_LOCKED_SCREEN, true)
        b.putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_SHOW_CALL_ID, true)
        b.putString(CallkitConstants.EXTRA_CALLKIT_RINGTONE_PATH, "system_ringtone_default")
        b.putString(
            CallkitConstants.EXTRA_CALLKIT_INCOMING_CALL_NOTIFICATION_CHANNEL_NAME,
            "incoming_calls"
        )
        b.putString(
            CallkitConstants.EXTRA_CALLKIT_MISSED_CALL_NOTIFICATION_CHANNEL_NAME,
            "missed_calls"
        )

        val extra = HashMap<String, Any?>()
        for ((k, v) in data) {
            extra[k] = v
        }
        // Normalize for Flutter routing
        extra["call_id"] = callIdRaw
        extra["media"] = media
        b.putSerializable(CallkitConstants.EXTRA_CALLKIT_EXTRA, extra)
        b.putSerializable(CallkitConstants.EXTRA_CALLKIT_HEADERS, HashMap<String, Any?>())

        val appCtx = context.applicationContext ?: context
        try {
            val sound = CallkitSoundPlayerManager(appCtx)
            val nm = CallkitNotificationManager(appCtx, sound)
            nm.createNotificationChanel(b)
            nm.showIncomingNotification(b)
            // Persist ACTIVE_CALLS so Accept/activeCalls() works consistently.
            addCall(appCtx, Data.fromBundle(b), false)
        } catch (_: Exception) {
            // swallow; can't log to server from here reliably
        }
    }

    private fun makeSystemUuidFromServerId(rawInput: String): String {
        val raw = rawInput.trim()
        val uuidRegex = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
        if (uuidRegex.matches(raw)) return raw.lowercase(Locale.ROOT)

        val bytes = IntArray(16) { 0 }
        val codes = if (raw.isEmpty()) "callkit-empty".toCharArray() else raw.toCharArray()
        for (i in codes.indices) {
            val code = codes[i].code
            val idx = i % 16
            bytes[idx] = (bytes[idx] + code + i) and 0xFF
        }
        return bytesToUuid(bytes)
    }

    private fun bytesToUuid(b: IntArray): String {
        fun two(n: Int): String = n.toString(16).padStart(2, '0')
        val hex = buildString(32) {
            for (v in b) append(two(v))
        }
        return "${hex.substring(0, 8)}-" +
            "${hex.substring(8, 12)}-" +
            "${hex.substring(12, 16)}-" +
            "${hex.substring(16, 20)}-" +
            "${hex.substring(20, 32)}"
    }
}

