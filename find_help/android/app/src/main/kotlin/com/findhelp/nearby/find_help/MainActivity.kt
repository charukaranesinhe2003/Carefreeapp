package com.findhelp.nearby.find_help

import android.Manifest
import android.app.AlarmManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReminderAlarms.ensureChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "find_help/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> prepare(result)
                    "sync" -> {
                        val raw = (call.arguments as? Map<*, *>)?.get("reminders") as? List<*>
                        val items = raw.orEmpty().mapNotNull { entry ->
                            val item = entry as? Map<*, *> ?: return@mapNotNull null
                            val id = (item["id"] as? Number)?.toLong() ?: return@mapNotNull null
                            val at = (item["at"] as? Number)?.toLong() ?: return@mapNotNull null
                            AlarmItem(
                                id,
                                item["title"] as? String ?: "Reminder",
                                item["body"] as? String ?: "Pharmacy reminder",
                                at,
                            )
                        }
                        ReminderAlarms.sync(this, items)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun prepare(result: MethodChannel.Result) {
        ReminderAlarms.ensureChannel(this)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            pending = result
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4101)
            return
        }
        result.success(exactAlarmsAllowed())
    }

    private fun exactAlarmsAllowed(): Boolean {
        if (Build.VERSION.SDK_INT < 31) return true
        val manager = getSystemService(AlarmManager::class.java)
        if (manager.canScheduleExactAlarms()) return true
        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
        return false
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 4101 || permissions.isEmpty()) return
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pending?.success(granted && exactAlarmsAllowed())
        pending = null
    }
}
