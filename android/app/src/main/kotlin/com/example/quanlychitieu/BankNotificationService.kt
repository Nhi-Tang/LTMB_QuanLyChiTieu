package com.example.quanlychitieu

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

class BankNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "MouseNoti"
        private const val PREFS_NAME = "mousey_notif_queue"
        private const val QUEUE_KEY = "pending_notifications"

        var eventSink: EventChannel.EventSink? = null
            set(value) {
                field = value
                if (value != null) {
                    instance?.flushPendingQueue()
                }
            }

        private var instance: BankNotificationService? = null

        private val ALLOWED_PACKAGES = setOf(
            "com.vcb", "com.vcb.vietcombank", "com.vcb.digibank",
            "com.mbmobile",
            // TODO: kiểm tra lại các package Techcombank bằng log thật
            "vn.com.techcombank.bb.app", "com.techcombank.mobile",
            "com.vnpay.bidv",
            "com.vietinbank.ipay",
            "com.tpb.mb.gprsandroid",
            "mobile.acb.com.vn",
            "com.vnpay.vpbankonline",
            "vn.com.msb.smartbooking",
            "com.mservice.momotransfer"   // MoMo (đã xác nhận bằng log)
        ).map { it.lowercase() }.toSet()

        fun isWhitelisted(packageName: String): Boolean =
            packageName.lowercase() in ALLOWED_PACKAGES

        fun sendEvent(data: Map<String, Any?>): Boolean {
            return try {
                if (eventSink != null) {
                    eventSink?.success(data)
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending event to Flutter: ${e.message}")
                false
            }
        }

        fun maskSensitiveNumbers(text: String): String {
            return text.replace(Regex("(?<!\\d)\\d{8,19}(?!\\d)"), "••••")
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        if (instance == this) instance = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        try {
            if (sbn == null) return

            val packageName = sbn.packageName ?: return

            // 1. Debug log package name
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "pkg=$packageName")
            }

            // 3. Bỏ qua thông báo của chính app và thông báo tóm tắt nhóm
            if (packageName == applicationContext.packageName) return

            val notification = sbn.notification ?: return
            val isGroupSummary = (notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0
            if (isGroupSummary) return

            // Lọc theo danh sách ngân hàng cho phép
            if (!isWhitelisted(packageName)) return

            // 2. Đọc extras an toàn
            val extras = notification.extras
            val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
            val postTime = sbn.postTime

            // 4. Debug log thông báo ngân hàng được phép (đã che số từ 8 chữ số trở lên)
            if (BuildConfig.DEBUG) {
                val safeTitle = maskSensitiveNumbers(title)
                val safeText = maskSensitiveNumbers(text)
                Log.d(TAG, "allowed pkg=$packageName title=$safeTitle text=$safeText")
            }

            val data = mapOf<String, Any?>(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "bigText" to bigText,
                "postTime" to postTime,
                "timestamp" to postTime
            )

            // 5. Gửi sang Flutter, nếu engine chưa sẵn sàng thì lưu tạm vào hàng đợi
            val sent = sendEvent(data)
            if (!sent) {
                enqueuePendingNotification(data)
            }
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) {
                Log.e(TAG, "Error in onNotificationPosted: ${e.message}", e)
            }
        }
    }

    @Synchronized
    private fun enqueuePendingNotification(data: Map<String, Any?>) {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queueJson = prefs.getString(QUEUE_KEY, "[]") ?: "[]"
            val array = JSONArray(queueJson)

            val now = System.currentTimeMillis()
            val cutoff = now - (24 * 60 * 60 * 1000L) // 24 giờ

            val newArray = JSONArray()

            // Xóa các mục quá 24 giờ và giữ lại các mục còn mới
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val time = obj.optLong("postTime", 0)
                if (time > cutoff) {
                    newArray.put(obj)
                }
            }

            // Giới hạn hàng đợi tối đa 50 mục
            if (newArray.length() >= 50) {
                newArray.remove(0)
            }

            val jsonObj = JSONObject()
            data.forEach { (k, v) ->
                if ((k == "title" || k == "text" || k == "bigText") && v is String) {
                    jsonObj.put(k, maskSensitiveNumbers(v))
                } else {
                    jsonObj.put(k, v)
                }
            }
            newArray.put(jsonObj)

            prefs.edit().putString(QUEUE_KEY, newArray.toString()).apply()
            Log.d(TAG, "Enqueued pending notification. Queue size: ${newArray.length()}")
        } catch (e: Exception) {
            Log.e(TAG, "Error enqueueing notification: ${e.message}")
        }
    }

    @Synchronized
    private fun flushPendingQueue() {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queueJson = prefs.getString(QUEUE_KEY, "[]") ?: "[]"
            val array = JSONArray(queueJson)

            if (array.length() == 0) return

            val now = System.currentTimeMillis()
            val cutoff = now - (24 * 60 * 60 * 1000L)

            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val time = obj.optLong("postTime", 0)
                if (time > cutoff) {
                    val map = mutableMapOf<String, Any?>()
                    val keys = obj.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        map[key] = obj.get(key)
                    }
                    sendEvent(map)
                }
            }

            prefs.edit().remove(QUEUE_KEY).apply()
            Log.d(TAG, "Flushed pending notification queue (${array.length()} items).")
        } catch (e: Exception) {
            Log.e(TAG, "Error flushing notification queue: ${e.message}")
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "BankNotificationService connected")
        flushPendingQueue()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "BankNotificationService disconnected, requesting rebind...")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                requestRebind(ComponentName(this, BankNotificationService::class.java))
            } catch (e: Exception) {
                Log.e(TAG, "Failed to requestRebind: ${e.message}")
            }
        }
    }
}
