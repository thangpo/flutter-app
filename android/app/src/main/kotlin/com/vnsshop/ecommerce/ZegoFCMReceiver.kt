package com.vnsshop.ecommerce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.io.BufferedWriter
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import im.zego.zpns_flutter.internal.utils.ZPNsFCMReceiver

/**
 * Catch FCM broadcast early (trước cả FirebaseMessagingService) để log và forward cho ZPNs.
 */
class ZegoFCMReceiver : BroadcastReceiver() {

    private val dateFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    private val prefsName = "FlutterSharedPreferences"
    private val accessTokenKey = "flutter.social_access_token"
    private val serverKey =
        "f6e69c898ddd643154c9bd4b152555842e26a868-d195c100005dddb9f1a30a67a5ae42d4-19845955"
    private val debugEndpoint = "https://social.vnshop247.com/api/zego_debug_log"

    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras
        val keys = extras?.keySet()?.joinToString(",") ?: ""

        sendRemoteLog(
            context,
            "native_broadcast_received",
            mapOf(
                "action" to (intent.action ?: ""),
                "keys" to keys,
                "has_extras" to (extras != null).toString(),
            ),
        )

        try {
            // Forward to ZPNs receiver (nếu Zego push dùng broadcast)
            ZPNsFCMReceiver().onReceive(context, intent)
            sendRemoteLog(context, "native_broadcast_forward_zpns", emptyMap())
        } catch (e: Exception) {
            sendRemoteLog(context, "native_broadcast_forward_failed", mapOf("error" to e.message))
        }
    }

    private fun sendRemoteLog(
        context: Context,
        event: String,
        payload: Map<String, String?>,
    ) {
        try {
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            val accessToken = prefs.getString(accessTokenKey, "") ?: ""

            val url = if (accessToken.isNotEmpty()) {
                URL("$debugEndpoint?access_token=${URLEncoder.encode(accessToken, "UTF-8")}")
            } else {
                URL(debugEndpoint)
            }
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 3000
                readTimeout = 3000
                doOutput = true
                setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
            }

            val body = StringBuilder().apply {
                append("event=").append(URLEncoder.encode(event, "UTF-8"))
                append("&ts=").append(URLEncoder.encode(dateFmt.format(Date()), "UTF-8"))
                append("&server_key=").append(URLEncoder.encode(serverKey, "UTF-8"))
                if (accessToken.isEmpty()) {
                    append("&missing_access_token=true")
                }
                payload.forEach { (k, v) ->
                    if (!k.isNullOrEmpty()) {
                        append("&").append(URLEncoder.encode(k, "UTF-8"))
                        append("=").append(URLEncoder.encode(v ?: "", "UTF-8"))
                    }
                }
            }.toString()

            BufferedWriter(OutputStreamWriter(conn.outputStream, "UTF-8")).use { writer ->
                writer.write(body)
            }
            conn.inputStream.bufferedReader().use { it.readText() }
            conn.disconnect()
        } catch (_: Exception) {
            // ignore logging failures
        }
    }
}
