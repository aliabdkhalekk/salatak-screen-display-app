package com.salatak.smartdisplay

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.salatak.smartdisplay/screen_control"
    private val launchRequestCode = 4101
    private var wakeLock: PowerManager.WakeLock? = null
    private var remoteUnlockCaptureEnabled = false
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyKeepScreenOn(true)
        if (intent?.getBooleanExtra("salatak_wake_for_prayer", false) == true) {
            wakeScreen()
        }
    }

    override fun onResume() {
        super.onResume()
        applyKeepScreenOn(true)
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
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        methodChannel?.setMethodCallHandler { call, result ->
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
                "setKeepScreenOn" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    applyKeepScreenOn(enabled)
                    result.success(null)
                }
                "enterRealStandby" -> {
                    result.success(tryEnterRealStandby())
                }
                "getRealScreenOffSupportStatus" -> {
                    result.success(realScreenOffSupportStatus())
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
                "setRemoteUnlockCapture" -> {
                    remoteUnlockCaptureEnabled =
                        call.argument<Boolean>("enabled") ?: false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (remoteUnlockCaptureEnabled && isUnlockKey(keyCode)) {
            event.startTracking()
            if (event.repeatCount == 0) {
                sendRemoteKeyEvent(keyCode, "down")
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        if (remoteUnlockCaptureEnabled && isUnlockKey(keyCode)) {
            sendRemoteKeyEvent(keyCode, "up")
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    private fun isUnlockKey(keyCode: Int): Boolean {
        return keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
            keyCode == KeyEvent.KEYCODE_ENTER ||
            keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER ||
            keyCode == KeyEvent.KEYCODE_BACK
    }

    private fun sendRemoteKeyEvent(keyCode: Int, action: String) {
        val label = when (keyCode) {
            KeyEvent.KEYCODE_BACK -> "BACK"
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER -> "OK"
            else -> "UNKNOWN"
        }
        Log.d("SalatakRemote", "Remote key detected: $label")
        methodChannel?.invokeMethod(
            "remoteKey",
            mapOf(
                "key" to label,
                "action" to action,
            ),
        )
    }

    private fun wakeScreen() {
        runOnUiThread {
            applyKeepScreenOn(true)
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

    private fun applyKeepScreenOn(enabled: Boolean) {
        runOnUiThread {
            if (enabled) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            window.decorView.keepScreenOn = enabled
        }
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

    private fun realScreenOffSupportStatus(): String {
        val devicePolicyManager =
            getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP &&
            devicePolicyManager.isDeviceOwnerApp(packageName)
        ) {
            "yes"
        } else {
            "unknown"
        }
    }

    private fun tryEnterRealStandby(): Boolean {
        applyKeepScreenOn(false)
        wakeLock?.releaseIfHeld()
        wakeLock = null

        if (tryDeviceOwnerLockNow()) {
            return true
        }
        if (tryPowerManagerGoToSleep()) {
            return true
        }
        if (trySleepKeyEvent()) {
            return true
        }

        // Android TV exposes HDMI-CEC standby only to system/privileged apps on
        // most devices. Normal launcher APKs cannot reliably send CEC standby.
        Log.w(
            "SalatakPower",
            "Real display standby unavailable; falling back to black screen",
        )
        applyKeepScreenOn(true)
        return false
    }

    private fun tryDeviceOwnerLockNow(): Boolean {
        return try {
            val devicePolicyManager =
                getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP &&
                devicePolicyManager.isDeviceOwnerApp(packageName)
            ) {
                devicePolicyManager.lockNow()
                Log.i("SalatakPower", "Real standby requested with DevicePolicyManager")
                true
            } else {
                false
            }
        } catch (error: Throwable) {
            Log.w("SalatakPower", "DevicePolicyManager standby failed", error)
            false
        }
    }

    private fun tryPowerManagerGoToSleep(): Boolean {
        return try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val method = PowerManager::class.java.getMethod(
                "goToSleep",
                Long::class.javaPrimitiveType,
            )
            method.invoke(powerManager, SystemClock.uptimeMillis())
            Log.i("SalatakPower", "Real standby requested with PowerManager.goToSleep")
            true
        } catch (error: Throwable) {
            Log.w("SalatakPower", "PowerManager.goToSleep standby failed", error)
            false
        }
    }

    private fun trySleepKeyEvent(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("input", "keyevent", "223"))
            val exitCode = process.waitFor()
            if (exitCode == 0) {
                Log.i("SalatakPower", "Real standby requested with KEYCODE_SLEEP")
                true
            } else {
                false
            }
        } catch (error: Throwable) {
            Log.w("SalatakPower", "KEYCODE_SLEEP standby failed", error)
            false
        }
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
