package com.vnsshop.ecommerce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver

/**
 * Nhận broadcast FCM từ ZEGOCLOUD (action: com.zegocloud.zegouikit.call.fcm)
 * rồi forward lại cho FirebaseMessagingReceiver của FlutterFire.
 */
class ZegoFcmProxyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            // Copy extras sang intent mới, đổi action về MESSAGING_EVENT.
            val forwardIntent = Intent(intent)
            forwardIntent.setClass(context, FlutterFirebaseMessagingReceiver::class.java)
            forwardIntent.action = "com.google.firebase.MESSAGING_EVENT"
            forwardIntent.setPackage(context.packageName)
            context.sendBroadcast(forwardIntent)
        } catch (_: Exception) {
        }

        // Ghi log nhẹ nhàng (logcat) để biết đã nhận broadcast.
        try {
            val message = RemoteMessage(intent.extras ?: return)
            android.util.Log.i(
                "ZegoFcmProxy",
                "received broadcast, keys=${message.data.keys}"
            )
        } catch (_: Exception) {
        }
    }
}
