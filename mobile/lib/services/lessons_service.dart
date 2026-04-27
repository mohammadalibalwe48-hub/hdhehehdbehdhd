import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';

class LessonsService {
  LessonsService._();
  static final SupabaseClient _client = Supabase.instance.client;
  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');

  static Future<List<Lesson>> listLessons() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from('lessons')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<LessonException>> listExceptions() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client.from('lesson_exceptions').select();
    return (res as List)
        .map((e) => LessonException.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _formToRow(LessonFormData f, String uid) => {
        'user_id': uid,
        'title': f.title,
        'teacher_name':
            f.teacherName.trim().isEmpty ? null : f.teacherName.trim(),
        'weekdays': f.weekdays,
        'start_time': f.startTime,
        'end_time': f.hasEndTime && f.endTime.isNotEmpty ? f.endTime : null,
        'start_date': _ymd.format(f.startDate),
        'end_date': f.hasEndDate && f.endDate != null
            ? _ymd.format(f.endDate!)
            : null,
        'location_type': locationTypeToString(f.locationType),
        'location_details': f.locationDetails.trim().isEmpty
            ? null
            : f.locationDetails.trim(),
        'notes': f.notes.trim().isEmpty ? null : f.notes.trim(),
      };

  static Future<void> createLesson(LessonFormData f) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('lessons').insert(_formToRow(f, uid));
  }

  static Future<void> updateLesson(String id, LessonFormData f) async {
    final uid = _client.auth.currentUser!.id;
    final row = _formToRow(f, uid)..remove('user_id');
    await _client.from('lessons').update(row).eq('id', id);
  }

  static Future<void> deleteLesson(String id) async {
    await _client.from('lessons').delete().eq('id', id);
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
    await _client.from('lesson_exceptions').upsert(
      {
        'lesson_id': lessonId,
        'exception_date': _ymd.format(date),
        'is_deleted': isDeleted,
        if (title != null) 'title': title,
        if (teacherName != null) 'teacher_name': teacherName,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (locationType != null)
          'location_type': locationTypeToString(locationType),
        if (locationDetails != null) 'location_details': locationDetails,
        if (notes != null) 'notes': notes,
      },
      onConflict: 'lesson_id,exception_date',
    );
  }
}
