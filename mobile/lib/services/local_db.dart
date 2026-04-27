import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson.dart';

/// Local SQLite cache of the user's lessons + lesson_exceptions, plus a
/// write-ahead queue of operations that still need to be pushed to Supabase.
///
/// This is the offline-first substrate:
///   * UI always reads from here (instant, offline)
///   * Writes go here first, then queue an entry in `pending_ops`
///   * `SyncService` flushes the queue and pulls fresh data from Supabase
///     whenever there is internet, and subscribes to Realtime for live updates
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const _dbName = 'lessons_local.db';
  static const _dbVersion = 1;
  static const _uuid = Uuid();

  Database? _db;
  final _lessonsCtrl = StreamController<List<Lesson>>.broadcast();
  final _exceptionsCtrl = StreamController<List<LessonException>>.broadcast();

  /// Currently-cached lessons and exceptions, kept in memory so every new
  /// subscriber gets the latest snapshot immediately on `listen`.
  List<Lesson> _lessons = const [];
  List<LessonException> _exceptions = const [];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lessons (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            teacher_name TEXT,
            weekdays TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            start_date TEXT NOT NULL,
            end_date TEXT,
            location_type TEXT NOT NULL,
            location_details TEXT,
            notes TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('CREATE INDEX lessons_user ON lessons(user_id)');

        await db.execute('''
          CREATE TABLE lesson_exceptions (
            id TEXT PRIMARY KEY,
            lesson_id TEXT NOT NULL,
            exception_date TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            title TEXT,
            teacher_name TEXT,
            start_time TEXT,
            end_time TEXT,
            location_type TEXT,
            location_details TEXT,
            notes TEXT,
            UNIQUE(lesson_id, exception_date)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_ops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op TEXT NOT NULL,            -- insert | update | delete | upsert
            table_name TEXT NOT NULL,    -- lessons | lesson_exceptions
            row_id TEXT NOT NULL,        -- pk of the row (id or composite)
            payload TEXT,                -- JSON body for insert/update/upsert
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    await _emit();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Database get _d {
    final db = _db;
    if (db == null) throw StateError('LocalDb not initialized');
    return db;
  }

  // ---------------------------------------------------------------------------
  // Reactive reads
  // ---------------------------------------------------------------------------

  Stream<List<Lesson>> watchLessons(String? userId) {
    final ctrl = StreamController<List<Lesson>>();
    void push(List<Lesson> ls) {
      if (ctrl.isClosed) return;
      if (userId == null) {
        ctrl.add(const []);
      } else {
        ctrl.add(ls.where((l) => l.userId == userId).toList());
      }
    }

    push(_lessons);
    final sub = _lessonsCtrl.stream.listen(push);
    ctrl.onCancel = sub.cancel;
    return ctrl.stream;
  }

  Stream<List<LessonException>> watchExceptions() async* {
    yield _exceptions;
    yield* _exceptionsCtrl.stream;
  }

  Future<void> _emit() async {
    _lessons = await _readLessons();
    _exceptions = await _readExceptions();
    if (!_lessonsCtrl.isClosed) _lessonsCtrl.add(_lessons);
    if (!_exceptionsCtrl.isClosed) _exceptionsCtrl.add(_exceptions);
  }

  Future<List<Lesson>> _readLessons() async {
    final rows = await _d.query('lessons', orderBy: 'created_at DESC');
    return rows.map(_rowToLesson).toList();
  }

  Future<List<LessonException>> _readExceptions() async {
    final rows = await _d.query('lesson_exceptions');
    return rows.map(_rowToException).toList();
  }

  // ---------------------------------------------------------------------------
  // Local-first writes — upsert into the cache AND queue a pending op so the
  // SyncService can replay them to Supabase the next time there's internet.
  // ---------------------------------------------------------------------------

  Future<String> createLessonLocal(LessonFormData f, String userId) async {
    final id = _uuid.v4();
    final row = _formToRow(id, f, userId);
    await _d.transaction((tx) async {
      await tx.insert('lessons', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _enqueue(tx, 'insert', 'lessons', id, _formToWireRow(id, f, userId));
    });
    await _emit();
    return id;
  }

  Future<void> updateLessonLocal(String id, LessonFormData f, String userId) async {
    final row = _formToRow(id, f, userId);
    // Preserve the existing created_at — only the server value matters for
    // ordering, and we don't want to overwrite it with `now` on every edit.
    row.remove('created_at');
    await _d.transaction((tx) async {
      await tx.update('lessons', row, where: 'id = ?', whereArgs: [id]);
      final wire = _formToWireRow(id, f, userId)..remove('user_id');
      await _enqueue(tx, 'update', 'lessons', id, wire);
    });
    await _emit();
  }

  Future<void> deleteLessonLocal(String id) async {
    await _d.transaction((tx) async {
      await tx.delete('lesson_exceptions',
          where: 'lesson_id = ?', whereArgs: [id]);
      await tx.delete('lessons', where: 'id = ?', whereArgs: [id]);
      await _enqueue(tx, 'delete', 'lessons', id, null);
    });
    await _emit();
  }

  Future<void> upsertExceptionLocal({
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
    final dateStr = _ymd(date);
    final rowId = '$lessonId|$dateStr';
    // Look up existing so we preserve previously-set fields (matches the
    // COALESCE semantics of the Supabase call this is shadowing).
    final existing = await _d.query('lesson_exceptions',
        where: 'lesson_id = ? AND exception_date = ?',
        whereArgs: [lessonId, dateStr],
        limit: 1);
    String id;
    Map<String, Object?> merged;
    if (existing.isNotEmpty) {
      final cur = existing.first;
      id = cur['id'] as String;
      merged = {
        'id': id,
        'lesson_id': lessonId,
        'exception_date': dateStr,
        'is_deleted': isDeleted ? 1 : 0,
        'title': title ?? cur['title'],
        'teacher_name': teacherName ?? cur['teacher_name'],
        'start_time': startTime ?? cur['start_time'],
        'end_time': endTime ?? cur['end_time'],
        'location_type': locationType == null
            ? cur['location_type']
            : locationTypeToString(locationType),
        'location_details': locationDetails ?? cur['location_details'],
        'notes': notes ?? cur['notes'],
      };
    } else {
      id = _uuid.v4();
      merged = {
        'id': id,
        'lesson_id': lessonId,
        'exception_date': dateStr,
        'is_deleted': isDeleted ? 1 : 0,
        'title': title,
        'teacher_name': teacherName,
        'start_time': startTime,
        'end_time': endTime,
        'location_type':
            locationType == null ? null : locationTypeToString(locationType),
        'location_details': locationDetails,
        'notes': notes,
      };
    }

    final wire = Map<String, dynamic>.of(merged)
      ..['is_deleted'] = isDeleted;

    await _d.transaction((tx) async {
      await tx.insert('lesson_exceptions', merged,
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _enqueue(tx, 'upsert', 'lesson_exceptions', rowId, wire);
    });
    await _emit();
  }

  // ---------------------------------------------------------------------------
  // Server-side reconciliation — called by SyncService after a fresh pull
  // or on every Realtime event. We overwrite the local copy with the server
  // row because the server is the single source of truth for synced state.
  // ---------------------------------------------------------------------------

  Future<void> replaceLessonsFromServer(List<Map<String, dynamic>> rows,
      {required String userId}) async {
    await _d.transaction((tx) async {
      await tx.delete('lessons', where: 'user_id = ?', whereArgs: [userId]);
      for (final r in rows) {
        await tx.insert('lessons', _serverToLessonRow(r),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    await _emit();
  }

  Future<void> replaceExceptionsFromServer(
      List<Map<String, dynamic>> rows) async {
    await _d.transaction((tx) async {
      await tx.delete('lesson_exceptions');
      for (final r in rows) {
        await tx.insert('lesson_exceptions', _serverToExceptionRow(r),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    await _emit();
  }

  /// Apply a single Realtime event without nuking the whole table.
  Future<void> applyRealtime({
    required String table,
    required String event, // INSERT | UPDATE | DELETE
    required Map<String, dynamic>? newRecord,
    required Map<String, dynamic>? oldRecord,
  }) async {
    switch (table) {
      case 'lessons':
        if (event == 'DELETE') {
          final id = (oldRecord?['id'] ?? newRecord?['id']) as String?;
          if (id != null) {
            await _d.delete('lessons', where: 'id = ?', whereArgs: [id]);
          }
        } else if (newRecord != null) {
          await _d.insert('lessons', _serverToLessonRow(newRecord),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        break;
      case 'lesson_exceptions':
        if (event == 'DELETE') {
          final id = (oldRecord?['id'] ?? newRecord?['id']) as String?;
          if (id != null) {
            await _d.delete('lesson_exceptions',
                where: 'id = ?', whereArgs: [id]);
          }
        } else if (newRecord != null) {
          await _d.insert('lesson_exceptions', _serverToExceptionRow(newRecord),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        break;
    }
    await _emit();
  }

  /// Wipe everything — used on sign-out so a different user's lessons don't
  /// leak through on the same device.
  Future<void> clear() async {
    await _d.transaction((tx) async {
      await tx.delete('lessons');
      await tx.delete('lesson_exceptions');
      await tx.delete('pending_ops');
    });
    await _emit();
  }

  // ---------------------------------------------------------------------------
  // Pending ops — the write-ahead queue the SyncService drains.
  // ---------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> listPendingOps() {
    return _d.query('pending_ops', orderBy: 'id ASC');
  }

  Future<void> deletePendingOp(int id) async {
    await _d.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _enqueue(DatabaseExecutor tx, String op, String table,
      String rowId, Map<String, dynamic>? payload) async {
    await tx.insert('pending_ops', {
      'op': op,
      'table_name': table,
      'row_id': rowId,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // Row ↔ model mapping
  // ---------------------------------------------------------------------------

  Map<String, Object?> _formToRow(String id, LessonFormData f, String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': f.title,
      'teacher_name': _nullable(f.teacherName),
      'weekdays': jsonEncode(f.weekdays),
      'start_time': f.startTime,
      'end_time': f.hasEndTime && f.endTime.isNotEmpty ? f.endTime : null,
      'start_date': _ymd(f.startDate),
      'end_date':
          f.hasEndDate && f.endDate != null ? _ymd(f.endDate!) : null,
      'location_type': locationTypeToString(f.locationType),
      'location_details': _nullable(f.locationDetails),
      'notes': _nullable(f.notes),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Same as `_formToRow` but `weekdays` stays as `List<int>` (for Supabase
  /// REST, which expects the Postgres `INTEGER[]`, not a JSON string).
  Map<String, dynamic> _formToWireRow(
      String id, LessonFormData f, String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': f.title,
      'teacher_name': _nullable(f.teacherName),
      'weekdays': List<int>.of(f.weekdays),
      'start_time': f.startTime,
      'end_time': f.hasEndTime && f.endTime.isNotEmpty ? f.endTime : null,
      'start_date': _ymd(f.startDate),
      'end_date':
          f.hasEndDate && f.endDate != null ? _ymd(f.endDate!) : null,
      'location_type': locationTypeToString(f.locationType),
      'location_details': _nullable(f.locationDetails),
      'notes': _nullable(f.notes),
    };
  }

  Map<String, Object?> _serverToLessonRow(Map<String, dynamic> r) {
    final weekdays = r['weekdays'];
    String weekdaysJson;
    if (weekdays is List) {
      weekdaysJson = jsonEncode(weekdays);
    } else if (weekdays is String) {
      weekdaysJson = weekdays;
    } else {
      weekdaysJson = '[]';
    }
    return {
      'id': r['id'],
      'user_id': r['user_id'],
      'title': r['title'],
      'teacher_name': r['teacher_name'],
      'weekdays': weekdaysJson,
      'start_time': r['start_time'],
      'end_time': r['end_time'],
      'start_date': r['start_date'],
      'end_date': r['end_date'],
      'location_type': r['location_type'],
      'location_details': r['location_details'],
      'notes': r['notes'],
      'created_at': r['created_at'],
    };
  }

  Map<String, Object?> _serverToExceptionRow(Map<String, dynamic> r) {
    return {
      'id': r['id'],
      'lesson_id': r['lesson_id'],
      'exception_date': r['exception_date'],
      'is_deleted': (r['is_deleted'] == true || r['is_deleted'] == 1) ? 1 : 0,
      'title': r['title'],
      'teacher_name': r['teacher_name'],
      'start_time': r['start_time'],
      'end_time': r['end_time'],
      'location_type': r['location_type'],
      'location_details': r['location_details'],
      'notes': r['notes'],
    };
  }

  Lesson _rowToLesson(Map<String, Object?> row) {
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

  LessonException _rowToException(Map<String, Object?> row) {
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

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();

  @visibleForTesting
  static String makeYmd(DateTime d) => _ymd(d);
}
