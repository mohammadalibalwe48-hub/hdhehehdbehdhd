import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/lesson.dart';
import '../utils/occurrences.dart';
import 'local_db.dart';
import 'settings_service.dart';

/// Schedules on-device notifications `minutesBefore` each lesson occurrence.
///
/// No push service is involved — everything runs through the Android
/// AlarmManager via flutter_local_notifications, so scheduled reminders
/// survive app kills and device reboots (we registered the boot receiver).
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  static const _channelId = 'studies_lesson_reminders';
  static const _channelName = 'تذكير الدروس';
  static const _channelDescription =
      'تنبيهات قبل بداية كل درس بالوقت الذي تحدده.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Timer? _debounce;
  StreamSubscription<List<Lesson>>? _lessonsSub;
  StreamSubscription<List<LessonException>>? _exceptionsSub;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      // Fall back to UTC if the platform can't tell us the tz name — we'll
      // still fire, just possibly off by the DST offset.
      debugPrint('NotificationsService: tz lookup failed: $e');
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    // Listen to settings changes so we can re-sync notifications when the
    // toggle or "minutes before" value changes.
    SettingsService.instance.addListener(_onSettingsChanged);
    _initialized = true;
  }

  /// Subscribe to lesson / exception changes from LocalDb and recompute the
  /// notification schedule. Call once after SyncService has done its first
  /// pull (so the initial schedule reflects real data).
  void bindToLocalDb(String? userId) {
    _lessonsSub?.cancel();
    _exceptionsSub?.cancel();
    _lessonsSub = LocalDb.instance
        .watchLessons(userId)
        .listen((_) => _debouncedResync());
    _exceptionsSub =
        LocalDb.instance.watchExceptions().listen((_) => _debouncedResync());
  }

  Future<void> unbind() async {
    await _lessonsSub?.cancel();
    await _exceptionsSub?.cancel();
    _lessonsSub = null;
    _exceptionsSub = null;
    await cancelAll();
  }

  void _debouncedResync() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => resyncSchedule());
  }

  void _onSettingsChanged() => _debouncedResync();

  /// Ask the OS for POST_NOTIFICATIONS (Android 13+) and ignore-battery-
  /// optimization prompts. Returns true if we can schedule notifications.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) return false;
    // Android 12+ also needs permission to schedule exact alarms. On some
    // OEMs this is auto-granted; on others the user is bounced to settings.
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {/* older Android — no-op */}
    return true;
  }

  Future<bool> hasPermission() async {
    return (await Permission.notification.status).isGranted;
  }

  /// Recompute the full notification schedule based on the current
  /// lessons / exceptions in LocalDb and the current settings.
  ///
  /// Strategy: cancel everything we've scheduled, then schedule notifications
  /// for every occurrence in the next [windowDays] days. Flutter-local-
  /// notifications handles the AlarmManager side, so this is cheap even at
  /// ~200+ pending entries.
  Future<void> resyncSchedule({int windowDays = 30}) async {
    if (!_initialized) return;
    final settings = SettingsService.instance;

    // Always start from a clean slate so disabled/edited lessons don't linger.
    await cancelAll();

    if (!settings.notifyEnabled) return;
    if (!(await hasPermission())) return;

    final lessons = await LocalDb.instance.currentLessons();
    final exceptions = await LocalDb.instance.currentExceptions();
    if (lessons.isEmpty) return;

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(Duration(days: windowDays));
    final occurrences = occurrencesBetween(
      lessons: lessons,
      exceptions: exceptions,
      from: from,
      to: to,
    );

    final minutesBefore = settings.notifyMinutesBefore;
    final leadTime = Duration(minutes: minutesBefore);

    var id = 1;
    for (final occ in occurrences) {
      final startDt = _combineDateAndTime(occ.date, occ.startTime);
      if (startDt == null) continue;
      final fireAt = startDt.subtract(leadTime);
      if (!fireAt.isAfter(now)) continue;
      await _schedule(
        id: id++,
        occurrence: occ,
        fireAt: fireAt,
        minutesBefore: minutesBefore,
      );
      if (id > 400) break; // hard cap: plenty for a month of lessons
    }
  }

  Future<void> _schedule({
    required int id,
    required LessonOccurrence occurrence,
    required DateTime fireAt,
    required int minutesBefore,
  }) async {
    final tzTime = tz.TZDateTime.from(fireAt, tz.local);
    final title = 'درسك قريب: ${occurrence.title}';
    final body = _buildBody(occurrence, minutesBefore);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Exact-alarm permission might be denied; fall back to inexact.
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('NotificationsService.schedule failed: $e2');
      }
    }
  }

  String _buildBody(LessonOccurrence occ, int minutesBefore) {
    final time = occ.startTime;
    final teacher = (occ.teacherName ?? '').trim();
    final suffix = teacher.isNotEmpty ? ' مع $teacher' : '';
    return 'يبدأ الساعة $time$suffix — باقي $minutesBefore دقيقة.';
  }

  DateTime? _combineDateAndTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {/* noop */}
  }

  /// Fire an immediate test notification so the user can confirm they'll
  /// receive reminders on this device.
  Future<void> showTestNotification() async {
    if (!_initialized) return;
    await _plugin.show(
      999999,
      'تنبيه تجريبي ✅',
      'إشعارات Studies تعمل على هذا الجهاز.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
