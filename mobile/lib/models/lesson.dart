import 'package:flutter/foundation.dart';

enum LocationType { online, inPerson }

String locationTypeToString(LocationType t) =>
    t == LocationType.online ? 'online' : 'in_person';

LocationType locationTypeFromString(String? s) =>
    s == 'in_person' ? LocationType.inPerson : LocationType.online;

@immutable
class Lesson {
  final String id;
  final String userId;
  final String title;
  final String? teacherName;
  final List<int> weekdays;
  final String startTime; // HH:MM
  final String? endTime;
  final DateTime startDate;
  final DateTime? endDate;
  final LocationType locationType;
  final String? locationDetails;
  final String? notes;

  const Lesson({
    required this.id,
    required this.userId,
    required this.title,
    this.teacherName,
    required this.weekdays,
    required this.startTime,
    this.endTime,
    required this.startDate,
    this.endDate,
    required this.locationType,
    this.locationDetails,
    this.notes,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      teacherName: json['teacher_name'] as String?,
      weekdays: (json['weekdays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      startTime: _normalizeTime(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : _normalizeTime(json['end_time'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      locationType: locationTypeFromString(json['location_type'] as String?),
      locationDetails: json['location_details'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

@immutable
class LessonException {
  final String id;
  final String lessonId;
  final DateTime exceptionDate;
  final bool isDeleted;
  final String? title;
  final String? teacherName;
  final String? startTime;
  final String? endTime;
  final LocationType? locationType;
  final String? locationDetails;
  final String? notes;

  const LessonException({
    required this.id,
    required this.lessonId,
    required this.exceptionDate,
    required this.isDeleted,
    this.title,
    this.teacherName,
    this.startTime,
    this.endTime,
    this.locationType,
    this.locationDetails,
    this.notes,
  });

  factory LessonException.fromJson(Map<String, dynamic> json) {
    return LessonException(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      exceptionDate: DateTime.parse(json['exception_date'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
      title: json['title'] as String?,
      teacherName: json['teacher_name'] as String?,
      startTime: json['start_time'] == null
          ? null
          : _normalizeTime(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : _normalizeTime(json['end_time'] as String),
      locationType: json['location_type'] == null
          ? null
          : locationTypeFromString(json['location_type'] as String?),
      locationDetails: json['location_details'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

@immutable
class LessonOccurrence {
  final String lessonId;
  final DateTime date;
  final String title;
  final String? teacherName;
  final String startTime;
  final String? endTime;
  final LocationType locationType;
  final String? locationDetails;
  final String? notes;
  final bool isException;
  final String? exceptionId;

  const LessonOccurrence({
    required this.lessonId,
    required this.date,
    required this.title,
    this.teacherName,
    required this.startTime,
    this.endTime,
    required this.locationType,
    this.locationDetails,
    this.notes,
    this.isException = false,
    this.exceptionId,
  });
}

class LessonFormData {
  String title;
  String teacherName;
  List<int> weekdays;
  String startTime;
  String endTime;
  bool hasEndTime;
  DateTime startDate;
  DateTime? endDate;
  bool hasEndDate;
  LocationType locationType;
  String locationDetails;
  String notes;

  LessonFormData({
    this.title = '',
    this.teacherName = '',
    List<int>? weekdays,
    this.startTime = '',
    this.endTime = '',
    this.hasEndTime = true,
    DateTime? startDate,
    this.endDate,
    this.hasEndDate = false,
    this.locationType = LocationType.online,
    this.locationDetails = '',
    this.notes = '',
  })  : weekdays = weekdays ?? <int>[],
        startDate = startDate ?? DateTime.now();

  factory LessonFormData.fromLesson(Lesson l) => LessonFormData(
        title: l.title,
        teacherName: l.teacherName ?? '',
        weekdays: List.of(l.weekdays),
        startTime: l.startTime,
        endTime: l.endTime ?? '',
        hasEndTime: l.endTime != null,
        startDate: l.startDate,
        endDate: l.endDate,
        hasEndDate: l.endDate != null,
        locationType: l.locationType,
        locationDetails: l.locationDetails ?? '',
        notes: l.notes ?? '',
      );

  factory LessonFormData.fromOccurrence(LessonOccurrence o) => LessonFormData(
        title: o.title,
        teacherName: o.teacherName ?? '',
        weekdays: [o.date.weekday == 7 ? 0 : o.date.weekday % 7],
        startTime: o.startTime,
        endTime: o.endTime ?? '',
        hasEndTime: o.endTime != null,
        startDate: o.date,
        endDate: o.date,
        hasEndDate: true,
        locationType: o.locationType,
        locationDetails: o.locationDetails ?? '',
        notes: o.notes ?? '',
      );
}

const List<Map<String, dynamic>> weekdaysAr = [
  {'value': 0, 'label': 'الأحد', 'short': 'أحد'},
  {'value': 1, 'label': 'الاثنين', 'short': 'إثنين'},
  {'value': 2, 'label': 'الثلاثاء', 'short': 'ثلاثاء'},
  {'value': 3, 'label': 'الأربعاء', 'short': 'أربعاء'},
  {'value': 4, 'label': 'الخميس', 'short': 'خميس'},
  {'value': 5, 'label': 'الجمعة', 'short': 'جمعة'},
  {'value': 6, 'label': 'السبت', 'short': 'سبت'},
];

String _normalizeTime(String raw) {
  // Supabase returns "HH:MM:SS" for TIME. We store as HH:MM.
  final parts = raw.split(':');
  if (parts.length >= 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
  return raw;
}
