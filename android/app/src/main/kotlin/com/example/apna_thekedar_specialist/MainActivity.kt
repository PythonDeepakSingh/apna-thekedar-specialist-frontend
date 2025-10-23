package com.example.apna_thekedar_specialist // Aapka package name yahan check kar lein

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine // Naya import
import io.flutter.plugins.GeneratedPluginRegistrant // Naya import

// Naye imports channel banane ke liye
import android.os.Build
import android.app.NotificationManager
import android.app.NotificationChannel
import android.content.Context
import android.media.AudioAttributes // Sound ke liye
import android.net.Uri // Sound ke liye

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        // Yahan se channel banane ka code shuru hota hai
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Channel 1: Default (Chat etc. ke liye)
            val defaultChannelId = "default_channel"
            val defaultChannelName = "General Notifications"
            val defaultChannelDescription = "Default channel for app notifications"
            val defaultImportance = NotificationManager.IMPORTANCE_DEFAULT
            val defaultChannel = NotificationChannel(defaultChannelId, defaultChannelName, defaultImportance).apply {
                description = defaultChannelDescription
            }

            // Channel 2: Requirement (Lambi ringtone ke saath)
            val requirementChannelId = "requirement_channel"
            val requirementChannelName = "New Requirements"
            val requirementChannelDescription = "Channel for new job requirement alerts"
            val requirementImportance = NotificationManager.IMPORTANCE_HIGH // High importance taaki pop-up ho

            // Sound file ka path banayein
            val soundUri = Uri.parse("android.resource://$packageName/raw/notification_sound")
            // Sound ke attributes set karein
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE) // Ringtone ki tarah behave karega
                .build()

            val requirementChannel = NotificationChannel(requirementChannelId, requirementChannelName, requirementImportance).apply {
                description = requirementChannelDescription
                enableLights(true)
                enableVibration(true)
                setSound(soundUri, audioAttributes) // Custom sound yahan set karein
            }

            // System ko dono channels ke baare mein batayein
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(requirementChannel)
        }
    }
}