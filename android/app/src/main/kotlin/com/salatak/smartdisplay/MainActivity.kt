package com.salatak.smartdisplay

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.salatak.smartdisplay/screen_control"
    private val launchRequestCode = 4101
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent?.getBooleanExtra("salatak_wake_for_prayer", false) == true) {
            wakeScreen()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("salatak_wake_for_prayer", false)) {
            wakeScreen()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "wakeScreen" -> {
                    wakeScreen()
                    result.success(null)
                }
                "sleepScreen" -> {
                    val percent = call.argument<Int>("brightnessPercent") ?: 5
                    sleepScreen(percent)
                    result.success(null)
                }
                "scheduleLaunchAt" -> {
                    val epochMillis = call.argument<Number>("epochMillis")?.toLong()
                    if (epochMillis == null) {
                        result.error("bad_args", "epochMillis is required", null)
                    } else {
                        scheduleLaunchAt(epochMillis)
                        result.success(null)
                    }
                }
                "cancelScheduledLaunch" -> {
                    cancelScheduledLaunch()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun wakeScreen() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
                )
            }

            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            val attrs = window.attributes
            attrs.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
            window.attributes = attrs
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        val lock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "SalatakSmartDisplay:PrayerWake",
        )
        wakeLock?.releaseIfHeld()
        wakeLock = lock
        @Suppress("WakelockTimeout")
        lock.acquire(10_000L)
    }

    private fun sleepScreen(brightnessPercent: Int) {
        runOnUiThread {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            val attrs = window.attributes
            attrs.screenBrightness = (brightnessPercent.coerceIn(1, 100) / 100f)
                .coerceAtLeast(0.01f)
            window.attributes = attrs
        }
        wakeLock?.releaseIfHeld()
        wakeLock = null
    }

    private fun scheduleLaunchAt(epochMillis: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = launchPendingIntent()
        val triggerAt = epochMillis.coerceAtLeast(System.currentTimeMillis() + 1_000L)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !alarmManager.canScheduleExactAlarms()
        ) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                pendingIntent,
            )
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                pendingIntent,
            )
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    private fun cancelScheduledLaunch() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(launchPendingIntent())
    }

    private fun launchPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.salatak.smartdisplay.PRAYER_WAKE"
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            putExtra("salatak_wake_for_prayer", true)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        return PendingIntent.getActivity(this, launchRequestCode, intent, flags)
    }

    private fun PowerManager.WakeLock.releaseIfHeld() {
        if (isHeld) {
            release()
        }
    }
}
