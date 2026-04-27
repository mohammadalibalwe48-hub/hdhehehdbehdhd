import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../theme.dart';

class LessonCard extends StatelessWidget {
  final LessonOccurrence occurrence;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.occurrence,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeRange = occurrence.endTime != null
        ? '${occurrence.startTime} - ${occurrence.endTime}'
        : occurrence.startTime;
    final isOnline = occurrence.locationType == LocationType.online;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? AppColors.gradientPrimary
                      : AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline
                              ? AppColors.primary
                              : AppColors.accent)
                          .withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            occurrence.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (occurrence.isException)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'معدل',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentDeep,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_outlined,
                            size: 14,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          timeRange,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForeground,
                          ),
                        ),
                        if (occurrence.teacherName != null &&
                            occurrence.teacherName!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              occurrence.teacherName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
