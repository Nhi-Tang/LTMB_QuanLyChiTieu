package com.mousey.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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

        // Thông báo dự phòng khi Flutter chưa chạy (app đã bị đóng)
        private const val FALLBACK_CHANNEL_ID = "mousey_bank_pending"
        private const val FALLBACK_NOTIFICATION_ID = 73001

        // Cài đặt bật/tắt đọc thông báo ngân hàng do Flutter (shared_preferences) lưu
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val FLUTTER_BANK_ENABLED_KEY = "flutter.bank_notifications_enabled"

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
            "com.mservice.momotransfer",   // MoMo
            "vn.com.vng.zalopay"           // ZaloPay
        ).map { it.lowercase() }.toSet()

        fun isWhitelisted(packageName: String): Boolean =
            packageName.lowercase() in ALLOWED_PACKAGES

        fun sendEvent(data: Map<String, Any?>): Boolean {
            val sink = eventSink ?: return false
            return try {
                sink.success(data)
                true
            } catch (e: Exception) {
                Log.e(TAG, "Error sending event to Flutter: ${e.message}")
                false
            }
        }

        fun maskSensitiveNumbers(text: String): String {
            // Che các chuỗi số điện thoại / tài khoản từ 8 chữ số trở lên
            var masked = text.replace(Regex("(?<!\\d)\\d{8,19}(?!\\d)"), "••••")
            // Che luôn họ tên người trong giao dịch nếu in hoa 2 từ trở lên
            masked = masked.replace(Regex("\\b[A-Z][A-Z\\s]{2,}[A-Z]\\b"), "***")
            return masked
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

    private fun isBankReadingEnabled(): Boolean {
        return try {
            getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(FLUTTER_BANK_ENABLED_KEY, true)
        } catch (e: Exception) {
            true
        }
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

            if (!isBankReadingEnabled()) return

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
                "timestamp" to postTime,
                // Khóa thông báo hệ thống: phân biệt 2 giao dịch cùng số tiền
                "notifKey" to (sbn.key ?: "")
            )

            // 5. Gửi sang Flutter, nếu engine chưa sẵn sàng thì lưu tạm vào hàng đợi
            //    và hiện thông báo dự phòng để người dùng biết có giao dịch mới
            val sent = sendEvent(data)
            if (!sent) {
                val queueSize = enqueuePendingNotification(data)
                showFallbackNotification(queueSize)
            }
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) {
                Log.e(TAG, "Error in onNotificationPosted: ${e.message}", e)
            }
        }
    }

    /** Thêm vào hàng đợi, trả về số mục đang chờ */
    @Synchronized
    private fun enqueuePendingNotification(data: Map<String, Any?>): Int {
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

            // Lưu nguyên văn (bộ nhớ riêng của app, xóa ngay khi Flutter nhận):
            // nếu che số/tên ở đây thì parser phía Flutter không đọc được số tài khoản,
            // nội dung chuyển khoản và có thể tính sai số tiền
            val jsonObj = JSONObject()
            data.forEach { (k, v) -> jsonObj.put(k, v) }
            newArray.put(jsonObj)

            prefs.edit().putString(QUEUE_KEY, newArray.toString()).apply()
            Log.d(TAG, "Enqueued pending notification. Queue size: ${newArray.length()}")
            return newArray.length()
        } catch (e: Exception) {
            Log.e(TAG, "Error enqueueing notification: ${e.message}")
            return 1
        }
    }

    @Synchronized
    private fun flushPendingQueue() {
        // Chưa có Flutter lắng nghe thì giữ nguyên hàng đợi, không được xóa
        if (eventSink == null) return
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queueJson = prefs.getString(QUEUE_KEY, "[]") ?: "[]"
            val array = JSONArray(queueJson)

            if (array.length() == 0) return

            val now = System.currentTimeMillis()
            val cutoff = now - (24 * 60 * 60 * 1000L)
            val remaining = JSONArray()

            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val time = obj.optLong("postTime", 0)
                if (time <= cutoff) continue

                val map = mutableMapOf<String, Any?>()
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    map[key] = obj.get(key)
                }
                if (!sendEvent(map)) {
                    remaining.put(obj)
                }
            }

            if (remaining.length() == 0) {
                prefs.edit().remove(QUEUE_KEY).apply()
                cancelFallbackNotification()
            } else {
                prefs.edit().putString(QUEUE_KEY, remaining.toString()).apply()
            }
            Log.d(TAG, "Flushed pending queue: ${array.length() - remaining.length()} sent, ${remaining.length()} kept.")
        } catch (e: Exception) {
            Log.e(TAG, "Error flushing notification queue: ${e.message}")
        }
    }

    private fun showFallbackNotification(count: Int) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    FALLBACK_CHANNEL_ID,
                    "Giao dịch ngân hàng",
                    NotificationManager.IMPORTANCE_HIGH
                )
                manager.createNotificationChannel(channel)
            }

            val launchIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            val contentIntent = PendingIntent.getActivity(this, 0, launchIntent, piFlags)

            val title = if (count <= 1) "Có giao dịch ngân hàng mới" else "Có $count giao dịch ngân hàng mới"
            val body = "Mở Mousey để xem và phân loại giao dịch"

            @Suppress("DEPRECATION")
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, FALLBACK_CHANNEL_ID)
            } else {
                Notification.Builder(this).setPriority(Notification.PRIORITY_HIGH)
            }
            val notification = builder
                .setSmallIcon(applicationInfo.icon)
                .setContentTitle(title)
                .setContentText(body)
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .build()

            manager.notify(FALLBACK_NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing fallback notification: ${e.message}")
        }
    }

    private fun cancelFallbackNotification() {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(FALLBACK_NOTIFICATION_ID)
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling fallback notification: ${e.message}")
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
