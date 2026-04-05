package com.example.grounded

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class GroundedAccessibilityService : AccessibilityService() {

    companion object {
        var blockedApps: List<String> = emptyList()
        var isBlocking: Boolean = false

        val appPackages: Map<String, List<String>> = mapOf(
            "Instagram" to listOf("com.instagram.android"),
            "TikTok"    to listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill"),
            "YouTube"   to listOf("com.google.android.youtube"),
            "WhatsApp"  to listOf("com.whatsapp", "com.whatsapp.w4b"),
            "Reddit"    to listOf("com.reddit.frontpage"),
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        if (!isBlocking) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName) return

        for (appName in blockedApps) {
            val packages = appPackages[appName] ?: continue
            if (pkg in packages) {
                val intent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("blocked_app", appName)
                }
                startActivity(intent)
                return
            }
        }
    }

    override fun onInterrupt() {}
}
