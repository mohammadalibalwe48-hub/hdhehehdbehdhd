import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import '../app.dart';
import '../models/lesson.dart';
import '../services/auth_service.dart';
import '../services/lessons_service.dart';
import '../theme.dart';
import 'settings_page.dart';
import '../utils/occurrences.dart';
import '../widgets/add_lesson_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_details_sheet.dart';
import '../widgets/list_view.dart';
import '../widgets/week_view.dart';

enum HomeTab { week, list }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _tab = HomeTab.week;
  DateTime _weekStart = startOfWeekSunday(DateTime.now());
  bool _loading = true;
  List<Lesson> _lessons = [];
  List<LessonException> _exceptions = [];
  StreamSubscription<List<Lesson>>? _lessonsSub;
  StreamSubscription<List<LessonException>>? _exceptionsSub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _lessonsSub?.cancel();
    _exceptionsSub?.cancel();
    super.dispose();
  }

  /// Subscribe to the local PowerSync-managed SQLite DB. These streams emit
  /// on every change — local write, pull from Supabase, post-offline sync —
  /// so the UI stays live without any manual refresh.
  void _subscribe() {
    _lessonsSub = LessonsService.watchLessons().listen((lessons) {
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحميل الدروس: $e')),
      );
    });
    _exceptionsSub = LessonsService.watchExceptions().listen((ex) {
      if (!mounted) return;
      setState(() => _exceptions = ex);
    });
  }

  List<LessonOccurrence> get _weekOccurrences => occurrencesBetween(
        lessons: _lessons,
        exceptions: _exceptions,
        from: _weekStart,
        to: _weekStart.add(const Duration(days: 6)),
      );

  List<LessonOccurrence> get _upcomingOccurrences {
    final now = DateTime.now();
    return occurrencesBetween(
      lessons: _lessons,
      exceptions: _exceptions,
      from: DateTime(now.year, now.month, now.day),
      to: now.add(const Duration(days: 60)),
    );
  }

  void _changeWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
    });
  }

  Future<void> _openAddSheet({LessonFormData? initial, bool isEditing = false, Future<void> Function(LessonFormData)? customSubmit}) async {
    await AddLessonSheet.show(
      context,
      initial: initial,
      isEditing: isEditing,
      onSubmit: customSubmit ?? (data) async {
        await LessonsService.createLesson(data);
      },
    );
  }

  Future<void> _openDetails(LessonOccurrence occ) async {
    await LessonDetailsSheet.show(
      context,
      occurrence: occ,
      onAction: (action) async {
        switch (action) {
          case LessonAction.editSingle:
            await _openAddSheet(
              initial: LessonFormData.fromOccurrence(occ),
              isEditing: true,
              customSubmit: (data) async {
                await LessonsService.upsertException(
                  lessonId: occ.lessonId,
                  date: occ.date,
                  title: data.title,
                  teacherName: data.teacherName.isEmpty
                      ? null
                      : data.teacherName,
                  startTime: data.startTime,
                  endTime: data.hasEndTime && data.endTime.isNotEmpty
                      ? data.endTime
                      : null,
                  locationType: data.locationType,
                  locationDetails: data.locationDetails.isEmpty
                      ? null
                      : data.locationDetails,
                  notes: data.notes.isEmpty ? null : data.notes,
                );
              },
            );
            break;
          case LessonAction.editAll:
            final lesson = _lessons.firstWhere((l) => l.id == occ.lessonId);
            await _openAddSheet(
              initial: LessonFormData.fromLesson(lesson),
              isEditing: true,
              customSubmit: (data) async {
                await LessonsService.updateLesson(occ.lessonId, data);
              },
            );
            break;
          case LessonAction.deleteSingle:
            final ok = await _confirm(
                'حذف هذه المرة فقط',
                'سيتم إخفاء هذا الموعد فقط. باقي المواعيد تبقى كما هي.');
            if (ok) {
              await LessonsService.upsertException(
                lessonId: occ.lessonId,
                date: occ.date,
                isDeleted: true,
              );
            }
            break;
          case LessonAction.deleteAll:
            final ok = await _confirm(
                'حذف كل المواعيد',
                'هل أنت متأكد أنك تريد حذف هذا الدرس وجميع مواعيده؟');
            if (ok) {
              await LessonsService.deleteLesson(occ.lessonId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الدرس')),
                );
              }
            }
            break;
        }
      },
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.currentUser;
    final username =
        (user?.userMetadata?['username'] as String?) ?? user?.email ?? '';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.gradientHeroDark : AppColors.gradientHero,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, username),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_lessons.isEmpty
                        ? const EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'ابدأ بإضافة درسك الأول',
                            subtitle:
                                'اضغط على زر + لإضافة درس جديد، وسيظهر تلقائياً في كل يوم من أيامه.',
                          )
                        : (_tab == HomeTab.week
                            ? WeekView(
                                weekStart: _weekStart,
                                occurrences: _weekOccurrences,
                                onWeekChange: _changeWeek,
                                onLessonTap: _openDetails,
                              )
                            : LessonsListView(
                                occurrences: _upcomingOccurrences,
                                onLessonTap: _openDetails,
                              ))),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: 62,
          height: 62,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openAddSheet();
                },
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String username) {
    final todayLabel = intl.DateFormat('EEEE، d MMMM y', 'ar').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isNotEmpty ? 'مرحباً، $username' : 'مرحباً بك',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  todayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'المظهر',
            onPressed: () => LessonsApp.of(context).toggleTheme(),
            icon: Icon(isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              label: 'الأسبوع',
              selected: _tab == HomeTab.week,
              onTap: () => setState(() => _tab = HomeTab.week),
            ),
            _navItem(
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt,
              label: 'القائمة',
              selected: _tab == HomeTab.list,
              onTap: () => setState(() => _tab = HomeTab.list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppColors.primaryGlow : AppColors.primary)
        : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.primaryGlow : AppColors.primary)
                    .withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
