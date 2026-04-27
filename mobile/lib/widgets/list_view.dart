import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/lesson.dart';
import '../theme.dart';
import 'empty_state.dart';
import 'lesson_card.dart';

class LessonsListView extends StatelessWidget {
  final List<LessonOccurrence> occurrences;
  final void Function(LessonOccurrence) onLessonTap;

  const LessonsListView({
    super.key,
    required this.occurrences,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'لا توجد دروس قادمة',
        subtitle: 'أضف دروسك لتظهر هنا مرتبة حسب التاريخ.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final upcoming = occurrences
        .where((o) =>
            !o.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList();
    final grouped = groupBy(upcoming, (o) => _dateKey(o.date));
    final keys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final key = keys[i];
        final items = grouped[key]!;
        final date = items.first.date;
        final isToday = _isSameDay(date, now);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8, right: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isToday
                          ? (isDark
                                  ? AppColors.primaryGlow
                                  : AppColors.primary)
                              .withOpacity(0.14)
                          : (isDark
                                  ? AppColors.mutedDark
                                  : AppColors.muted)
                              .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      intl.DateFormat('EEEE، d MMMM', 'ar').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? (isDark
                                ? AppColors.primaryGlow
                                : AppColors.primary)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LessonCard(
                    occurrence: o,
                    onTap: () => onLessonTap(o),
                  ),
                )),
          ],
        );
      },
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
