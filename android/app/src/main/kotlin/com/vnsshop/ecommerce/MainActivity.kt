package com.vnsshop.ecommerce

import android.content.Intent
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CALLKIT_INTENT_CHANNEL = "com.vnsshop.ecommerce/callkit_intent"
        private const val EXTRA_CALLKIT_CALL_DATA = "EXTRA_CALLKIT_CALL_DATA"
    }

    private var initialCallkitIntent: Map<String, Any?>? = null
    private var callkitChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Bật edge-to-edge đúng cách cho Flutter
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Lưu intent CallKit (cold start) để Flutter đọc sau khi engine sẵn sàng.
        initialCallkitIntent = extractCallkitIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        callkitChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALLKIT_INTENT_CHANNEL)
        callkitChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntent" -> {
                    val payload = initialCallkitIntent
                    initialCallkitIntent = null
                    result.success(payload)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val payload = extractCallkitIntent(intent) ?: return
        // Cập nhật state phòng khi Flutter chưa nhận kịp (có thể gọi getInitialIntent sau đó)
        initialCallkitIntent = payload
        // Push realtime sang Flutter nếu app đã chạy
        try {
            callkitChannel?.invokeMethod("onCallkitIntent", payload)
        } catch (_: Exception) {
        }
    }

    private fun extractCallkitIntent(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val action = intent.action ?: ""
        val hasCallkitAction = action.contains("flutter_callkit_incoming", ignoreCase = true) ||
            action.contains("ACTION_CALL_", ignoreCase = true)
        val dataBundle = intent.getBundleExtra(EXTRA_CALLKIT_CALL_DATA)
        if (!hasCallkitAction && dataBundle == null) return null

        return mapOf(
            "action" to action,
            "data" to (dataBundle?.let { bundleToMap(it) } ?: emptyMap<String, Any?>())
        )
    }

    private fun bundleToMap(bundle: Bundle): Map<String, Any?> {
        val map = LinkedHashMap<String, Any?>()
        for (key in bundle.keySet()) {
            val value = bundle.get(key)
            map[key] = when (value) {
                is Bundle -> bundleToMap(value)
                is Map<*, *> -> value.entries.associate { (k, v) -> k.toString() to v }
                is Array<*> -> value.toList()
                else -> value
            }
        }
        return map
    }
}
