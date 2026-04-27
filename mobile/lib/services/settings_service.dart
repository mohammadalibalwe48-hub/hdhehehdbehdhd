import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds all user-configurable settings and persists them to SharedPreferences.
///
/// Any widget can subscribe via `context.watch<SettingsService>()` (or by
/// listening to this as a [ChangeNotifier]) and will rebuild on change.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kThemeMode = 'setting_theme_mode';
  // Legacy key from earlier versions of the app (before the settings page).
  // Read it once on migration so existing users don't lose their theme pick.
  static const _kThemeModeLegacy = 'theme_mode';
  static const _kNotifyEnabled = 'setting_notify_enabled';
  static const _kNotifyMinutesBefore = 'setting_notify_minutes_before';
  static const _kScreenshotBlockEnabled = 'setting_screenshot_block_enabled';

  late SharedPreferences _prefs;
  bool _ready = false;

  ThemeMode _themeMode = ThemeMode.system;
  bool _notifyEnabled = false;
  int _notifyMinutesBefore = 15;
  bool _screenshotBlockEnabled = false;

  ThemeMode get themeMode => _themeMode;
  bool get notifyEnabled => _notifyEnabled;
  int get notifyMinutesBefore => _notifyMinutesBefore;
  bool get screenshotBlockEnabled => _screenshotBlockEnabled;
  bool get ready => _ready;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final tmStr = _prefs.getString(_kThemeMode) ??
        _prefs.getString(_kThemeModeLegacy);
    if (tmStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == tmStr,
        orElse: () => ThemeMode.system,
      );
    }
    _notifyEnabled = _prefs.getBool(_kNotifyEnabled) ?? false;
    _notifyMinutesBefore = _prefs.getInt(_kNotifyMinutesBefore) ?? 15;
    _screenshotBlockEnabled =
        _prefs.getBool(_kScreenshotBlockEnabled) ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setNotifyEnabled(bool v) async {
    if (_notifyEnabled == v) return;
    _notifyEnabled = v;
    await _prefs.setBool(_kNotifyEnabled, v);
    notifyListeners();
  }

  Future<void> setNotifyMinutesBefore(int minutes) async {
    if (_notifyMinutesBefore == minutes) return;
    _notifyMinutesBefore = minutes;
    await _prefs.setInt(_kNotifyMinutesBefore, minutes);
    notifyListeners();
  }

  Future<void> setScreenshotBlockEnabled(bool v) async {
    if (_screenshotBlockEnabled == v) return;
    _screenshotBlockEnabled = v;
    await _prefs.setBool(_kScreenshotBlockEnabled, v);
    notifyListeners();
  }
}
