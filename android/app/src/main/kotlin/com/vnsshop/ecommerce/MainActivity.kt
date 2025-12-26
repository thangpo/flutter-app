package com.vnsshop.ecommerce

import android.content.Intent
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val callkitChannelName = "com.vnsshop/callkit"
    private var callkitChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Bật edge-to-edge đúng cách cho Flutter
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Nếu app được mở từ action accept của callkit, báo về Dart sớm.
        intent?.let { handleCallkitAction(it) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callkitChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callkitChannelName)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // để FlutterActivity/plugin đọc intent mới
        handleCallkitAction(intent)
    }

    private fun handleCallkitAction(intent: Intent) {
        val action = intent.action ?: return
        if (action.contains("com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT")) {
            callkitChannel?.invokeMethod(
                "callkit_action",
                mapOf("action" to "accept", "source" to "android_intent")
            )
        }
    }

}
