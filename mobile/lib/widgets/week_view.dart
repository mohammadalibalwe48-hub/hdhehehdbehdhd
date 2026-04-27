import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/lesson.dart';
import '../theme.dart';
import '../utils/occurrences.dart';
import 'empty_state.dart';
import 'lesson_card.dart';

class WeekView extends StatefulWidget {
  final DateTime weekStart;
  final List<LessonOccurrence> occurrences;
  final void Function(int direction) onWeekChange; // -1 prev, +1 next
  final void Function(LessonOccurrence) onLessonTap;

  const WeekView({
    super.key,
    required this.weekStart,
    required this.occurrences,
    required this.onWeekChange,
    required this.onLessonTap,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String _formatRange() {
    final end = widget.weekStart.add(const Duration(days: 6));
    final startMonth = intl.DateFormat.MMMM('ar').format(widget.weekStart);
    final endMonth = intl.DateFormat.MMMM('ar').format(end);
    final year = intl.DateFormat('y', 'ar').format(widget.weekStart);
    if (startMonth == endMonth) {
      return '${widget.weekStart.day} - ${end.day} $startMonth $year';
    }
    return '${widget.weekStart.day} $startMonth - ${end.day} $endMonth $year';
  }

  List<LessonOccurrence> _dayOccurrences(DateTime d) {
    return widget.occurrences
        .where((o) =>
            o.date.year == d.year &&
            o.date.month == d.month &&
            o.date.day == d.day)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));
    final dayOccurrences = _dayOccurrences(_selectedDate);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => widget.onWeekChange(-1),
                tooltip: 'الأسبوع السابق',
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.primaryGlow
                            : AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _formatRange(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => widget.onWeekChange(1),
                tooltip: 'الأسبوع التالي',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.mutedDark.withOpacity(0.7)
                  : AppColors.muted.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                for (final d in days)
                  Expanded(child: _dayChip(d, isDark)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                intl.DateFormat('EEEE، d MMMM', 'ar').format(_selectedDate),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                '${dayOccurrences.length} درس',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayOccurrences.isEmpty
              ? const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'لا توجد دروس في هذا اليوم',
                  subtitle: 'اضغط على زر الإضافة لإنشاء درس جديد.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  itemBuilder: (_, i) => LessonCard(
                    occurrence: dayOccurrences[i],
                    onTap: () => widget.onLessonTap(dayOccurrences[i]),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: dayOccurrences.length,
                ),
        ),
      ],
    );
  }

  Widget _dayChip(DateTime d, bool isDark) {
    final isSelected = _isSameDay(d, _selectedDate);
    final isToday = _isSameDay(d, DateTime.now());
    final hasLessons = _dayOccurrences(d).isNotEmpty;
    final dow = weekdayForApp(d);
    final label = weekdaysAr[dow]['short'] as String;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.gradientPrimary : null,
          color: !isSelected && isToday
              ? (isDark ? AppColors.primaryGlow : AppColors.primary)
                  .withOpacity(0.14)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: !isSelected && isToday
              ? Border.all(
                  color: (isDark ? AppColors.primaryGlow : AppColors.primary)
                      .withOpacity(0.4))
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : (isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForeground)
                        .withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? Colors.white
                    : (isToday
                        ? (isDark ? AppColors.primaryGlow : AppColors.primary)
                        : null),
              ),
            ),
            const SizedBox(height: 4),
            if (hasLessons)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : AppColors.accent,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
