import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson.dart';
import 'powersync_service.dart';

/// All reads and writes go through the local PowerSync-managed SQLite DB.
/// Writes are instant (no network), PowerSync replays them to Supabase in the
/// background, and incoming changes from Supabase (web app, other devices)
/// land in the same tables — so UI `watch()` streams update automatically.
class LessonsService {
  LessonsService._();

  static final SupabaseClient _authClient = Supabase.instance.client;
  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');
  static const _uuid = Uuid();

  static String? get _uid => _authClient.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Reactive streams — home_page subscribes to these so the UI re-renders as
  // soon as data changes, whether the change came from the user's own write,
  // from the website via PowerSync pull, or from a sync after being offline.
  // ---------------------------------------------------------------------------

  static Stream<List<Lesson>> watchLessons() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return PowerSyncService.db.watch(
      'SELECT * FROM lessons WHERE user_id = ? ORDER BY created_at DESC NULLS LAST, id DESC',
      parameters: [uid],
    ).map((rs) => rs.map(_rowToLesson).toList());
  }

  static Stream<List<LessonException>> watchExceptions() {
    if (_uid == null) return Stream.value(const []);
    return PowerSyncService.db
        .watch('SELECT * FROM lesson_exceptions')
        .map((rs) => rs.map(_rowToException).toList());
  }

  // ---------------------------------------------------------------------------
  // Writes — local-first. PowerSync queues them and replays to Supabase.
  // ---------------------------------------------------------------------------

  static Future<void> createLesson(LessonFormData f) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final id = _uuid.v4();
    await PowerSyncService.db.execute(
      '''INSERT INTO lessons
         (id, user_id, title, teacher_name, weekdays, start_time, end_time,
          start_date, end_date, location_type, location_details, notes, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        uid,
        f.title,
        _nullable(f.teacherName),
        jsonEncode(f.weekdays),
        f.startTime,
        f.hasEndTime && f.endTime.isNotEmpty ? f.endTime : null,
        _ymd.format(f.startDate),
        f.hasEndDate && f.endDate != null ? _ymd.format(f.endDate!) : null,
        locationTypeToString(f.locationType),
        _nullable(f.locationDetails),
        _nullable(f.notes),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  static Future<void> updateLesson(String id, LessonFormData f) async {
    await PowerSyncService.db.execute(
      '''UPDATE lessons SET
           title = ?,
           teacher_name = ?,
           weekdays = ?,
           start_time = ?,
           end_time = ?,
           start_date = ?,
           end_date = ?,
           location_type = ?,
           location_details = ?,
           notes = ?
         WHERE id = ?''',
      [
        f.title,
        _nullable(f.teacherName),
        jsonEncode(f.weekdays),
        f.startTime,
        f.hasEndTime && f.endTime.isNotEmpty ? f.endTime : null,
        _ymd.format(f.startDate),
        f.hasEndDate && f.endDate != null ? _ymd.format(f.endDate!) : null,
        locationTypeToString(f.locationType),
        _nullable(f.locationDetails),
        _nullable(f.notes),
        id,
      ],
    );
  }

  static Future<void> deleteLesson(String id) async {
    await PowerSyncService.db.writeTransaction((tx) async {
      await tx.execute(
          'DELETE FROM lesson_exceptions WHERE lesson_id = ?', [id]);
      await tx.execute('DELETE FROM lessons WHERE id = ?', [id]);
    });
  }

  static Future<void> upsertException({
    required String lessonId,
    required DateTime date,
    bool isDeleted = false,
    String? title,
    String? teacherName,
    String? startTime,
    String? endTime,
    LocationType? locationType,
    String? locationDetails,
    String? notes,
  }) async {
    final dateStr = _ymd.format(date);
    final existing = await PowerSyncService.db.getOptional(
      'SELECT id FROM lesson_exceptions WHERE lesson_id = ? AND exception_date = ?',
      [lessonId, dateStr],
    );
    if (existing != null) {
      await PowerSyncService.db.execute(
        '''UPDATE lesson_exceptions SET
             is_deleted = ?,
             title = COALESCE(?, title),
             teacher_name = COALESCE(?, teacher_name),
             start_time = COALESCE(?, start_time),
             end_time = COALESCE(?, end_time),
             location_type = COALESCE(?, location_type),
             location_details = COALESCE(?, location_details),
             notes = COALESCE(?, notes)
           WHERE id = ?''',
        [
          isDeleted ? 1 : 0,
          title,
          teacherName,
          startTime,
          endTime,
          locationType == null ? null : locationTypeToString(locationType),
          locationDetails,
          notes,
          existing['id'],
        ],
      );
    } else {
      await PowerSyncService.db.execute(
        '''INSERT INTO lesson_exceptions
             (id, lesson_id, exception_date, is_deleted, title, teacher_name,
              start_time, end_time, location_type, location_details, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          _uuid.v4(),
          lessonId,
          dateStr,
          isDeleted ? 1 : 0,
          title,
          teacherName,
          startTime,
          endTime,
          locationType == null ? null : locationTypeToString(locationType),
          locationDetails,
          notes,
        ],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Row → model mapping. SQLite stores everything as text/integer, so we
  // rebuild the Supabase-shaped map and hand it to the existing `fromJson`
  // factories to keep parsing logic in one place.
  // ---------------------------------------------------------------------------

  static Lesson _rowToLesson(Map<String, dynamic> row) {
    final weekdaysRaw = row['weekdays'];
    final weekdays = weekdaysRaw is String && weekdaysRaw.isNotEmpty
        ? (jsonDecode(weekdaysRaw) as List<dynamic>)
        : const <dynamic>[];
    return Lesson.fromJson({
      'id': row['id'],
      'user_id': row['user_id'],
      'title': row['title'],
      'teacher_name': row['teacher_name'],
      'weekdays': weekdays,
      'start_time': row['start_time'],
      'end_time': row['end_time'],
      'start_date': row['start_date'],
      'end_date': row['end_date'],
      'location_type': row['location_type'],
      'location_details': row['location_details'],
      'notes': row['notes'],
    });
  }

  static LessonException _rowToException(Map<String, dynamic> row) {
    return LessonException.fromJson({
      'id': row['id'],
      'lesson_id': row['lesson_id'],
      'exception_date': row['exception_date'],
      'is_deleted': (row['is_deleted'] as int? ?? 0) == 1,
      'title': row['title'],
      'teacher_name': row['teacher_name'],
      'start_time': row['start_time'],
      'end_time': row['end_time'],
      'location_type': row['location_type'],
      'location_details': row['location_details'],
      'notes': row['notes'],
    });
  }

  static String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();
}
