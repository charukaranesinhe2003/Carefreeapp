package com.findhelp.nearby.find_help

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

data class AlarmItem(val id: Long, val title: String, val body: String, val at: Long)

object ReminderAlarms {
    private const val prefsName = "find_help_alarms"
    private const val prefsKey = "items"
    const val channelId = "find_help_reminders_sound"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val sound = alarmSound()
        val channel = NotificationChannel(channelId, "Reminders", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Pharmacy reminders with sound"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 200, 500)
            setSound(
                sound,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun sync(context: Context, items: List<AlarmItem>) {
        ensureChannel(context)
        cancelAll(context)
        val kept = JSONArray()
        val now = System.currentTimeMillis()
        for (item in items) {
            if (item.at <= now + 1000) {
                show(context, item)
            } else {
                schedule(context, item)
                kept.put(item.toJson())
            }
        }
        save(context, kept)
    }

    fun rescheduleSaved(context: Context) {
        ensureChannel(context)
        val now = System.currentTimeMillis()
        val kept = JSONArray()
        for (item in read(context)) {
            if (item.at <= now) {
                if (now - item.at < 15 * 60 * 1000) show(context, item)
            } else {
                schedule(context, item)
                kept.put(item.toJson())
            }
        }
        save(context, kept)
    }

    fun show(context: Context, item: AlarmItem) {
        ensureChannel(context)
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val content = PendingIntent.getActivity(
            context,
            item.requestCode,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notification = builder
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(item.title)
            .setContentText(item.body)
            .setContentIntent(content)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setWhen(item.at)
            .setShowWhen(true)
            .apply {
                if (Build.VERSION.SDK_INT < 26) {
                    @Suppress("DEPRECATION")
                    setSound(alarmSound())
                    @Suppress("DEPRECATION")
                    setDefaults(Notification.DEFAULT_VIBRATE or Notification.DEFAULT_LIGHTS)
                }
            }
            .build()
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.notify(item.requestCode, notification)
    }

    private fun schedule(context: Context, item: AlarmItem) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val pending = pending(context, item)
        val trigger = item.at
        try {
            if (Build.VERSION.SDK_INT >= 31 && !alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        }
    }

    private fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        for (item in read(context)) {
            alarmManager.cancel(pending(context, item))
        }
    }

    private fun pending(context: Context, item: AlarmItem): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra("id", item.id)
            putExtra("title", item.title)
            putExtra("body", item.body)
            putExtra("at", item.at)
        }
        return PendingIntent.getBroadcast(
            context,
            item.requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun read(context: Context): List<AlarmItem> {
        return try {
            val raw = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE).getString(prefsKey, "[]") ?: "[]"
            val array = JSONArray(raw)
            List(array.length()) { index -> alarmFromJson(array.getJSONObject(index)) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun save(context: Context, array: JSONArray) {
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(prefsKey, array.toString())
            .apply()
    }

    private fun alarmSound() = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
}

private val AlarmItem.requestCode: Int
    get() = (id and 0x7FFFFFFF).toInt()

private fun AlarmItem.toJson(): JSONObject {
    return JSONObject()
        .put("id", id)
        .put("title", title)
        .put("body", body)
        .put("at", at)
}

private fun alarmFromJson(json: JSONObject): AlarmItem {
    return AlarmItem(
        json.optLong("id"),
        json.optString("title", "Reminder"),
        json.optString("body", "Pharmacy reminder"),
        json.optLong("at"),
    )
}
