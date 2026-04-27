import 'package:powersync/powersync.dart';

/// Client-side schema for the local SQLite mirror that PowerSync keeps in sync
/// with the Supabase `lessons` and `lesson_exceptions` tables.
///
/// Notes:
/// - PowerSync auto-creates a text `id` column for every table; we don't declare it.
/// - All non-text columns from Postgres are represented as text/integer here —
///   dates/times as ISO strings, `weekdays` as a JSON-encoded text array,
///   `is_deleted` as an integer 0/1. The app-layer code handles the
///   conversion both on read (Lesson.fromJson / LessonException.fromJson) and
///   on write (LessonsService).
const lessonsSchema = Schema([
  Table('lessons', [
    Column.text('user_id'),
    Column.text('title'),
    Column.text('teacher_name'),
    Column.text('weekdays'),
    Column.text('start_time'),
    Column.text('end_time'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.text('location_type'),
    Column.text('location_details'),
    Column.text('notes'),
    Column.text('created_at'),
  ], indexes: [
    Index('lessons_by_user', [IndexedColumn('user_id')]),
  ]),
  Table('lesson_exceptions', [
    Column.text('lesson_id'),
    Column.text('exception_date'),
    Column.integer('is_deleted'),
    Column.text('title'),
    Column.text('teacher_name'),
    Column.text('start_time'),
    Column.text('end_time'),
    Column.text('location_type'),
    Column.text('location_details'),
    Column.text('notes'),
  ], indexes: [
    Index('exceptions_by_lesson',
        [IndexedColumn('lesson_id'), IndexedColumn('exception_date')]),
  ]),
]);
