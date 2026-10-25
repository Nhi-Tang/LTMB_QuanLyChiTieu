package com.example.quanlychitieu

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_CONTROL = "com.mousey.app/notifications_control"
    private val CHANNEL_NOTIFICATIONS = "com.mousey.app/notifications"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CONTROL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationPermissionGranted" -> {
                        result.success(isNotificationServiceEnabled())
                    }
                    "requestNotificationPermission" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                intent.data = Uri.parse("package:$packageName")
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                    }
                    "openBatteryOptimizationSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                            } catch (e2: Exception) {
                                result.error("ERROR", e2.message, null)
                            }
                        }
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NOTIFICATIONS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BankNotificationService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    BankNotificationService.eventSink = null
                }
            })
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (flat != null && flat.isNotEmpty()) {
            val names = flat.split(":")
            for (name in names) {
                if (name.contains(pkgName)) {
                    return true
                }
            }
        }
        return false
    }
}
