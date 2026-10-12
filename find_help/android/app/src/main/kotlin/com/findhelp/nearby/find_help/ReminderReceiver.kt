package com.findhelp.nearby.find_help

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val item = AlarmItem(
            intent.getLongExtra("id", 0L),
            intent.getStringExtra("title") ?: "Reminder",
            intent.getStringExtra("body") ?: "Pharmacy reminder",
            intent.getLongExtra("at", System.currentTimeMillis()),
        )
        ReminderAlarms.show(context, item)
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            ReminderAlarms.rescheduleSaved(context)
        }
    }
}
