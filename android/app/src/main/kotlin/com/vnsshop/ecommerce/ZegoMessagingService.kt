package com.vnsshop.ecommerce

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.zegocloud.uikit.prebuilt.call.invitation.ZegoUIKitPrebuiltCallInvitationService

/**
 * Forwards FCM messages/tokens to ZEGOCLOUD so call invitations can wake the app when killed.
 */
class ZegoMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        ZegoUIKitPrebuiltCallInvitationService.onToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        ZegoUIKitPrebuiltCallInvitationService.onReceiveRemoteMessage(message)
    }
}
