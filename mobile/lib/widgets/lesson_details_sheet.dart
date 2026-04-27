import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/lesson.dart';
import '../theme.dart';

enum LessonAction { editSingle, editAll, deleteSingle, deleteAll }

class LessonDetailsSheet extends StatelessWidget {
  final LessonOccurrence occurrence;
  final void Function(LessonAction) onAction;

  const LessonDetailsSheet({
    super.key,
    required this.occurrence,
    required this.onAction,
  });

  static Future<void> show(BuildContext context,
      {required LessonOccurrence occurrence,
      required void Function(LessonAction) onAction}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LessonDetailsSheet(
        occurrence: occurrence,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeRange = occurrence.endTime != null
        ? '${occurrence.startTime} - ${occurrence.endTime}'
        : occurrence.startTime;

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient:
                        occurrence.locationType == LocationType.online
                            ? AppColors.gradientPrimary
                            : AppColors.gradientAccent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    occurrence.locationType == LocationType.online
                        ? Icons.videocam_outlined
                        : Icons.place_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        intl.DateFormat('EEEE، d MMMM y', 'ar')
                            .format(occurrence.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _row(context, Icons.access_time_outlined, 'الوقت', timeRange),
                if (occurrence.teacherName != null &&
                    occurrence.teacherName!.isNotEmpty)
                  _row(context, Icons.person_outline, 'المعلم',
                      occurrence.teacherName!),
                if (occurrence.locationDetails != null &&
                    occurrence.locationDetails!.isNotEmpty)
                  _row(
                      context,
                      occurrence.locationType == LocationType.online
                          ? Icons.link
                          : Icons.place_outlined,
                      occurrence.locationType == LocationType.online
                          ? 'رابط الفصل'
                          : 'المكان',
                      occurrence.locationDetails!),
                if (occurrence.notes != null &&
                    occurrence.notes!.isNotEmpty)
                  _row(context, Icons.notes_outlined, 'ملاحظات',
                      occurrence.notes!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _actionButton(
                  context,
                  label: 'تعديل هذه المرة فقط',
                  icon: Icons.edit_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    onAction(LessonAction.editSingle);
                  },
                ),
                const SizedBox(height: 8),
                _actionButton(
                  context,
                  label: 'تعديل كل المواعيد',
                  icon: Icons.edit_note_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    onAction(LessonAction.editAll);
                  },
                ),
                const SizedBox(height: 8),
                _actionButton(
                  context,
                  label: 'حذف هذه المرة فقط',
                  icon: Icons.remove_circle_outline,
                  destructive: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    onAction(LessonAction.deleteSingle);
                  },
                ),
                const SizedBox(height: 8),
                _actionButton(
                  context,
                  label: 'حذف كل المواعيد',
                  icon: Icons.delete_outline,
                  destructive: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    onAction(LessonAction.deleteAll);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.mutedDark : AppColors.muted),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18,
                color: isDark
                    ? AppColors.primaryGlow
                    : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForeground,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool destructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = destructive
        ? AppColors.destructive
        : (isDark ? AppColors.primaryGlow : AppColors.primary);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
