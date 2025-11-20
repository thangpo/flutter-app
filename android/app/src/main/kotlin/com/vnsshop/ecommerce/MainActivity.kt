package com.vnsshop.ecommerce

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Bật edge-to-edge đúng cách cho Flutter
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
