import 'package:flutter/services.dart';

/// Flutter-side wrapper around the Android Accessibility Service
/// that detects and blocks specified apps in real time.
class BlockerService {
  static const _channel = MethodChannel('com.example.grounded/blocker');

  /// Called whenever Android detects a blocked app in the foreground.
  static void Function(String appName)? onAppBlocked;

  /// Wire up the callback from Android → Flutter. Call once at startup.
  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAppBlocked') {
        onAppBlocked?.call(call.arguments as String);
      }
    });
  }

  /// Whether the Accessibility Service is enabled for Grounded.
  static Future<bool> hasAccessibilityPermission() async {
    try {
      return await _channel
              .invokeMethod<bool>('hasAccessibilityPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Settings → Accessibility so the user can enable Grounded.
  static Future<void> requestAccessibilityPermission() async {
    await _channel.invokeMethod('requestAccessibilityPermission');
  }

  /// Tell the Android service which apps to block and start monitoring.
  static Future<void> startBlocking(List<String> apps) async {
    await _channel.invokeMethod('startBlocking', {'apps': apps});
  }

  /// Pause blocking (used during breaks or when all tasks are done).
  static Future<void> stopBlocking() async {
    await _channel.invokeMethod('stopBlocking');
  }

  /// Update the blocked apps list while already running.
  static Future<void> updateBlockedApps(List<String> apps) async {
    await _channel.invokeMethod('updateBlockedApps', {'apps': apps});
  }
}
