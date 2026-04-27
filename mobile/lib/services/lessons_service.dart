import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import 'local_db.dart';
import 'sync_service.dart';

/// Thin facade over [LocalDb] + [SyncService] so the rest of the app doesn't
/// need to know how the offline layer works.
///
/// Reads come from the local SQLite cache (instant, offline-safe) and writes
/// go to the cache first — [SyncService] drains them to Supabase in the
/// background whenever there is internet.
class LessonsService {
  LessonsService._();

  static final SupabaseClient _authClient = Supabase.instance.client;
  static String? get _uid => _authClient.auth.currentUser?.id;

  // Reactive reads — the UI subscribes to these streams and automatically
  // re-renders on any local write, Realtime push, or post-offline sync pull.
  static Stream<List<Lesson>> watchLessons() =>
      LocalDb.instance.watchLessons(_uid);

  static Stream<List<LessonException>> watchExceptions() =>
      LocalDb.instance.watchExceptions();

  static Future<void> createLesson(LessonFormData f) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    await LocalDb.instance.createLessonLocal(f, uid);
    // Fire-and-forget attempt at an immediate push so the user doesn't have
    // to wait for a connectivity tick if they already have internet.
    unawaited(SyncService.instance.flushNow());
  }

  static Future<void> updateLesson(String id, LessonFormData f) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    await LocalDb.instance.updateLessonLocal(id, f, uid);
    unawaited(SyncService.instance.flushNow());
  }

  static Future<void> deleteLesson(String id) async {
    await LocalDb.instance.deleteLessonLocal(id);
    unawaited(SyncService.instance.flushNow());
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
    await LocalDb.instance.upsertExceptionLocal(
      lessonId: lessonId,
      date: date,
      isDeleted: isDeleted,
      title: title,
      teacherName: teacherName,
      startTime: startTime,
      endTime: endTime,
      locationType: locationType,
      locationDetails: locationDetails,
      notes: notes,
    );
    unawaited(SyncService.instance.flushNow());
  }
}
