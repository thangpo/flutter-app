package com.vnsshop.ecommerce

import android.content.Intent
import java.io.BufferedWriter
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import im.zego.zpns_flutter.internal.utils.ZPNsFCMReceiver

/**
 * Forward FCM to ZPNs/Zego for offline call invitations (app bị kill).
 * Dùng FirebaseMessagingService gốc để tránh phụ thuộc lớp plugin không có sẵn trên Android build.
 */
class ZegoMessagingService : FirebaseMessagingService() {

    private val dateFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    private val prefsName = "FlutterSharedPreferences"
    private val accessTokenKey = "flutter.social_access_token"
    private val serverKey = "f6e69c898ddd643154c9bd4b152555842e26a868-d195c100005dddb9f1a30a67a5ae42d4-19845955"
    private val debugEndpoint = "https://social.vnshop247.com/api/zego_debug_log"

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // ZPNs (zego_zpns) sẽ tự xử lý registration từ phía Flutter.
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        sendRemoteLog(
            "native_fcm_received",
            mapOf(
                "from" to (message.from ?: ""),
                "data_keys" to message.data.keys.joinToString(","),
                "has_notification" to (message.notification != null).toString(),
            ),
        )

        // Gửi lại data FCM sang ZPNs receiver để CallKit/offline hoạt động.
        try {
            // Chỉ forward phần data (bỏ notification) để ZPNs không bỏ qua.
            val intent = Intent("com.google.android.c2dm.intent.RECEIVE").apply {
                setPackage(applicationContext.packageName)
                for ((k, v) in message.data) {
                    putExtra(k, v)
                }
            }
            ZPNsFCMReceiver().onReceive(applicationContext, intent)
            sendRemoteLog("native_forward_to_zpns_success", mapOf("has_data" to message.data.isNotEmpty().toString()))
        } catch (e: Exception) {
            sendRemoteLog("native_forward_to_zpns_failed", mapOf("error" to e.message))
        }
    }

    private fun sendRemoteLog(event: String, payload: Map<String, String?>) {
        try {
            val prefs = getSharedPreferences(prefsName, MODE_PRIVATE)
            val accessToken = prefs.getString(accessTokenKey, "") ?: ""

            // Gửi ngay cả khi thiếu access_token để biết service đã chạy (server có thể reject nhưng vẫn log HTTP hit)
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
