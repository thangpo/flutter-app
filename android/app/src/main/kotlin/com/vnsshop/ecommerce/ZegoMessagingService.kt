package com.vnsshop.ecommerce

import com.google.firebase.messaging.RemoteMessage
import im.zego.zpns_flutter.internal.utils.ZPNsFCMReceiver
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService

/**
 * Forward FCM to ZPNs/Zego for offline call invitations while keeping default firebase_messaging behaviour.
 */
class ZegoMessagingService : FlutterFirebaseMessagingService() {

    private val zpnsReceiver = ZPNsFCMReceiver()

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // ZPNs handles push registration from Flutter; nothing extra to do here.
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        // Bridge the FCM data to ZPNs receiver so CallKit/offline invitations work when app is killed.
        try {
            val intent = message.toIntent().apply {
                action = "com.google.android.c2dm.intent.RECEIVE"
                setPackage(packageName)
            }
            zpnsReceiver.onReceive(applicationContext, intent)
        } catch (_: Exception) {
            // ignore; firebase_messaging already handled the message via super
        }
    }
}
