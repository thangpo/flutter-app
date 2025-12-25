package com.vnsshop.ecommerce

import android.content.Intent
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Bật edge-to-edge đúng cách cho Flutter
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // để FlutterActivity/plugin đọc intent mới
    }

}
