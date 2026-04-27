import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'settings_service.dart';

/// Thin wrapper over the `studies.secure_window` MethodChannel implemented in
/// the Android host. Flips FLAG_SECURE on the Activity window — when on, the
/// OS blocks screenshots, screen recordings, and hides the app's preview in
/// the recent-apps switcher.
class SecureWindow {
  SecureWindow._();
  static const _channel = MethodChannel('studies.secure_window');

  /// Applies the current `screenshotBlockEnabled` setting to the host window.
  static Future<void> applyFromSettings() async {
    if (!defaultTargetPlatform.toString().contains('android')) return;
    try {
      await _channel.invokeMethod<void>('setSecure',
          {'enabled': SettingsService.instance.screenshotBlockEnabled});
    } catch (e) {
      debugPrint('SecureWindow.apply failed: $e');
    }
  }
}
