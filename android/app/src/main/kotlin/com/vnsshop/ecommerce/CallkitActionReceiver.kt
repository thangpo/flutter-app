package com.vnsshop.ecommerce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.hiennv.flutter_callkit_incoming.CallkitConstants

/**
 * Receives CallKit actions broadcasted by flutter_callkit_incoming (ACCEPT/DECLINE/ENDED/TIMEOUT)
 * and ensures the app is launched with the call payload so Flutter can route to CallScreen.
 *
 * Needed because on some devices, the plugin's TransparentActivity may not reliably bring
 * the app to foreground from killed-state.
 */
class CallkitActionReceiver : BroadcastReceiver() {
    companion object {
        private const val EXTRA_CALLKIT_INCOMING_DATA = "EXTRA_CALLKIT_INCOMING_DATA"
        private const val EXTRA_CALLKIT_CALL_DATA = "EXTRA_CALLKIT_CALL_DATA"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        // Only care about accept/start -> open app
        val shouldOpen = action.endsWith(CallkitConstants.ACTION_CALL_ACCEPT) ||
            action.endsWith(CallkitConstants.ACTION_CALL_START)
        if (!shouldOpen) return

        val data: Bundle? = intent.extras?.getBundle(EXTRA_CALLKIT_INCOMING_DATA)
        // Launch intent to MainActivity
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.cloneFilter()
            ?: return

        launch.action = CallkitConstants.ACTION_CALL_ACCEPT
        launch.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        )
        if (data != null) {
            launch.putExtra(EXTRA_CALLKIT_CALL_DATA, data)
        }

        try {
            context.startActivity(launch)
        } catch (_: Exception) {
        }
    }
}

