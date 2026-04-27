import 'package:intl/intl.dart';
import '../models/lesson.dart';

final _ymd = DateFormat('yyyy-MM-dd');

/// Convert a DateTime.weekday (1=Mon..7=Sun) to the app's 0=Sun..6=Sat.
int weekdayForApp(DateTime d) => d.weekday == 7 ? 0 : d.weekday % 7;

DateTime startOfWeekSunday(DateTime d) {
  final sinceSunday = weekdayForApp(d);
  final base = DateTime(d.year, d.month, d.day);
  return base.subtract(Duration(days: sinceSunday));
}

List<LessonOccurrence> occurrencesBetween({
  required List<Lesson> lessons,
  required List<LessonException> exceptions,
  required DateTime from,
  required DateTime to,
}) {
  final occurrences = <LessonOccurrence>[];
  final exMap = <String, LessonException>{
    for (final e in exceptions) '${e.lessonId}|${_ymd.format(e.exceptionDate)}': e,
  };

  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);

  for (var cursor = start;
      !cursor.isAfter(end);
      cursor = cursor.add(const Duration(days: 1))) {
    final dow = weekdayForApp(cursor);
    for (final lesson in lessons) {
      if (!lesson.weekdays.contains(dow)) continue;
      if (cursor.isBefore(lesson.startDate)) continue;
      if (lesson.endDate != null && cursor.isAfter(lesson.endDate!)) continue;

      final key = '${lesson.id}|${_ymd.format(cursor)}';
      final ex = exMap[key];
      if (ex != null && ex.isDeleted) continue;

      occurrences.add(LessonOccurrence(
        lessonId: lesson.id,
        date: cursor,
        title: ex?.title ?? lesson.title,
        teacherName: ex?.teacherName ?? lesson.teacherName,
        startTime: ex?.startTime ?? lesson.startTime,
        endTime: ex?.endTime ?? lesson.endTime,
        locationType: ex?.locationType ?? lesson.locationType,
        locationDetails: ex?.locationDetails ?? lesson.locationDetails,
        notes: ex?.notes ?? lesson.notes,
        isException: ex != null,
        exceptionId: ex?.id,
      ));
    }
  }

  occurrences.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.startTime.compareTo(b.startTime);
  });
  return occurrences;
}
