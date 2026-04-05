package com.example.grounded

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.example.grounded/blocker"
        var methodChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        )
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startBlocking" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    GroundedAccessibilityService.blockedApps = apps
                    GroundedAccessibilityService.isBlocking = true
                    result.success(null)
                }
                "stopBlocking" -> {
                    GroundedAccessibilityService.isBlocking = false
                    result.success(null)
                }
                "updateBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    GroundedAccessibilityService.blockedApps = apps
                    result.success(null)
                }
                "hasAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "requestAccessibilityPermission" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleBlockedAppIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleBlockedAppIntent(intent)
    }

    private fun handleBlockedAppIntent(intent: Intent?) {
        val blockedApp = intent?.getStringExtra("blocked_app") ?: return
        intent.removeExtra("blocked_app")
        methodChannel?.invokeMethod("onAppBlocked", blockedApp)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        return am.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        ).any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
            it.resolveInfo.serviceInfo.name == GroundedAccessibilityService::class.java.name
        }
    }
}
