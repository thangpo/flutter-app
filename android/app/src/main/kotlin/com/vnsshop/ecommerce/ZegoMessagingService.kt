package com.vnsshop.ecommerce

import android.content.Intent
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import im.zego.zpns_flutter.internal.utils.ZPNsFCMReceiver

/**
 * Forward FCM to ZPNs/Zego for offline call invitations (app bị kill).
 * Dùng FirebaseMessagingService gốc để tránh phụ thuộc lớp plugin không có sẵn trên Android build.
 */
class ZegoMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // ZPNs (zego_zpns) sẽ tự xử lý registration từ phía Flutter.
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        // Gửi lại data FCM sang ZPNs receiver để CallKit/offline hoạt động.
        try {
            val intent = Intent("com.google.android.c2dm.intent.RECEIVE").apply {
                setPackage(applicationContext.packageName)
                for ((k, v) in message.data) {
                    putExtra(k, v)
                }
                message.notification?.title?.let { putExtra("title", it) }
                message.notification?.body?.let { putExtra("content", it) }
            }
            ZPNsFCMReceiver().onReceive(applicationContext, intent)
        } catch (_: Exception) {
            // ignore
        }
    }
}
