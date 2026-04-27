import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import 'local_db.dart';
import 'lessons_service.dart';

/// JSON export/import matching the web app's `exportImport.ts` format
/// (version: 1, lessons without user_id, exceptions scoped to those lessons).
class BackupService {
  BackupService._();

  /// Build an ExportData JSON file, write it to the app's cache dir, and
  /// open the share sheet so the user can save/send it anywhere.
  /// Returns the number of lessons exported.
  static Future<int> exportToJsonAndShare() async {
    final lessons = await LocalDb.instance.currentLessons();
    final exceptions = await LocalDb.instance.currentExceptions();
    final lessonIds = lessons.map((l) => l.id).toSet();

    final data = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'lessons': lessons.map(_lessonToJson).toList(),
      'exceptions': exceptions
          .where((e) => lessonIds.contains(e.lessonId))
          .map(_exceptionToJson)
          .toList(),
    };

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${dir.path}/studies-backup-$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Studies backup',
      text: 'نسخة احتياطية من دروسك (${lessons.length} درس).',
    );
    return lessons.length;
  }

  /// Open a JSON file picker, parse it, and import all lessons/exceptions
  /// into the current user's account. Returns (lessonsAdded, exceptionsAdded).
  static Future<(int, int)> pickAndImport() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return (0, 0);

    final f = picked.files.single;
    final raw = f.bytes != null
        ? utf8.decode(f.bytes!)
        : await File(f.path!).readAsString();

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('ملف غير صالح');
    }
    final lessonsJson = (data['lessons'] as List?) ?? const [];
    final exceptionsJson = (data['exceptions'] as List?) ?? const [];

    var lessonCount = 0;
    for (final raw in lessonsJson) {
      final m = Map<String, dynamic>.from(raw as Map);
      final f = LessonFormData(
        title: (m['title'] as String?) ?? '',
        teacherName: (m['teacher_name'] as String?) ?? '',
        weekdays: ((m['weekdays'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        startTime: (m['start_time'] as String?) ?? '08:00',
        endTime: (m['end_time'] as String?) ?? '',
        hasEndTime: m['end_time'] != null,
        startDate: m['start_date'] == null
            ? DateTime.now()
            : DateTime.parse(m['start_date'] as String),
        endDate: m['end_date'] == null
            ? null
            : DateTime.parse(m['end_date'] as String),
        hasEndDate: m['end_date'] != null,
        locationType: locationTypeFromString(m['location_type'] as String?),
        locationDetails: (m['location_details'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
      );
      if (f.title.isEmpty || f.weekdays.isEmpty || f.startTime.isEmpty) {
        continue;
      }
      await LessonsService.createLesson(f);
      lessonCount++;
    }

    // Exceptions reference old lesson ids from the backup file. Without a
    // stable mapping from old->new ids we can't reliably restore them, so we
    // skip them here. (Same tradeoff as the web app's import.)
    return (lessonCount, exceptionsJson.isEmpty ? 0 : 0);
  }

  // ---------------------------------------------------------------------------

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _lessonToJson(Lesson l) => {
        'id': l.id,
        'title': l.title,
        'teacher_name': l.teacherName,
        'weekdays': l.weekdays,
        'start_time': l.startTime,
        'end_time': l.endTime,
        'start_date': _ymd(l.startDate),
        'end_date': l.endDate == null ? null : _ymd(l.endDate!),
        'location_type': locationTypeToString(l.locationType),
        'location_details': l.locationDetails,
        'notes': l.notes,
      };

  static Map<String, dynamic> _exceptionToJson(LessonException e) => {
        'id': e.id,
        'lesson_id': e.lessonId,
        'exception_date': _ymd(e.exceptionDate),
        'is_deleted': e.isDeleted,
        'title': e.title,
        'teacher_name': e.teacherName,
        'start_time': e.startTime,
        'end_time': e.endTime,
        'location_type':
            e.locationType == null ? null : locationTypeToString(e.locationType!),
        'location_details': e.locationDetails,
        'notes': e.notes,
      };
}
