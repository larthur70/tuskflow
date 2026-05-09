package com.tuskflow.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.content.Context

fun createNotificationChannel(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

        val channel = NotificationChannel(
            "high_importance_channel",
            "Study Notifications",
            NotificationManager.IMPORTANCE_HIGH
        )

        channel.description = "High priority study notifications"
        channel.enableVibration(true)
        channel.vibrationPattern = longArrayOf(0, 400, 200, 400)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }
}