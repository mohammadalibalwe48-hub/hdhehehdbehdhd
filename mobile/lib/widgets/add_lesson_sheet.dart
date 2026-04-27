import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import '../models/lesson.dart';
import '../theme.dart';

class AddLessonSheet extends StatefulWidget {
  final LessonFormData? initial;
  final bool isEditing;
  final Future<void> Function(LessonFormData) onSubmit;

  const AddLessonSheet({
    super.key,
    this.initial,
    this.isEditing = false,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    LessonFormData? initial,
    bool isEditing = false,
    required Future<void> Function(LessonFormData) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddLessonSheet(
        initial: initial,
        isEditing: isEditing,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<AddLessonSheet> {
  late LessonFormData _data;
  String? _titleError;
  String? _weekdaysError;
  String? _startTimeError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _data = widget.initial ?? LessonFormData();
  }

  bool _validate() {
    setState(() {
      _titleError = _data.title.trim().isEmpty ? 'أدخل عنوان الدرس' : null;
      _weekdaysError =
          _data.weekdays.isEmpty ? 'اختر يوماً واحداً على الأقل' : null;
      _startTimeError =
          _data.startTime.isEmpty ? 'اختر وقت البدء' : null;
    });
    return _titleError == null &&
        _weekdaysError == null &&
        _startTimeError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final now = TimeOfDay.now();
    final initial = TimeOfDay(hour: now.hour, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _data.startTime = text;
        _startTimeError = null;
      } else {
        _data.endTime = text;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _data.startDate : (_data.endDate ?? DateTime.now()),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _data.startDate = picked;
      } else {
        _data.endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'تعديل الدرس' : 'إضافة درس جديد',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _sectionLabel('عنوان الدرس'),
                  TextFormField(
                    initialValue: _data.title,
                    onChanged: (v) => setState(() {
                      _data.title = v;
                      _titleError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'مثال: الرياضيات',
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      errorText: _titleError,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('اسم المعلم (اختياري)'),
                  TextFormField(
                    initialValue: _data.teacherName,
                    onChanged: (v) => setState(() => _data.teacherName = v),
                    decoration: const InputDecoration(
                      hintText: 'مثال: أستاذ أحمد',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('أيام التكرار'),
                  _buildWeekdayChips(isDark),
                  if (_weekdaysError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 4),
                      child: Text(
                        _weekdaysError!,
                        style: const TextStyle(
                            color: AppColors.destructive, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                          child: _timeField(
                              label: 'وقت البدء',
                              value: _data.startTime,
                              onTap: () => _pickTime(isStart: true),
                              error: _startTimeError)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _timeField(
                        label: 'وقت الانتهاء',
                        value: _data.hasEndTime ? _data.endTime : '',
                        onTap: _data.hasEndTime
                            ? () => _pickTime(isStart: false)
                            : null,
                        trailing: Switch(
                          value: _data.hasEndTime,
                          onChanged: (v) => setState(() => _data.hasEndTime = v),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          label: 'تاريخ البدء',
                          value: intl.DateFormat('d MMM y', 'ar')
                              .format(_data.startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dateField(
                          label: 'تاريخ الانتهاء',
                          value: _data.hasEndDate && _data.endDate != null
                              ? intl.DateFormat('d MMM y', 'ar')
                                  .format(_data.endDate!)
                              : 'مستمر',
                          onTap: _data.hasEndDate
                              ? () => _pickDate(isStart: false)
                              : null,
                          trailing: Switch(
                            value: _data.hasEndDate,
                            onChanged: (v) =>
                                setState(() => _data.hasEndDate = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('المكان'),
                  _buildLocationSwitcher(isDark),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: _data.locationDetails,
                    onChanged: (v) =>
                        setState(() => _data.locationDetails = v),
                    decoration: InputDecoration(
                      hintText: _data.locationType == LocationType.online
                          ? 'رابط الفصل الافتراضي'
                          : 'تفاصيل المكان',
                      prefixIcon: Icon(
                          _data.locationType == LocationType.online
                              ? Icons.link
                              : Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('ملاحظات (اختياري)'),
                  TextFormField(
                    initialValue: _data.notes,
                    onChanged: (v) => setState(() => _data.notes = v),
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'أي ملاحظات إضافية...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submitting ? null : _submit,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.4),
                                  )
                                : Text(
                                    widget.isEditing ? 'حفظ التعديلات' : 'إضافة الدرس',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      );

  Widget _buildWeekdayChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final day in weekdaysAr)
          GestureDetector(
            onTap: () {
              final v = day['value'] as int;
              setState(() {
                if (_data.weekdays.contains(v)) {
                  _data.weekdays.remove(v);
                } else {
                  _data.weekdays = [..._data.weekdays, v]..sort();
                }
                _weekdaysError = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: _data.weekdays.contains(day['value'])
                    ? AppColors.gradientPrimary
                    : null,
                color: _data.weekdays.contains(day['value'])
                    ? null
                    : (isDark ? AppColors.mutedDark : AppColors.muted),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _data.weekdays.contains(day['value'])
                      ? Colors.transparent
                      : (isDark ? AppColors.borderDark : AppColors.border),
                ),
              ),
              child: Text(
                day['short'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _data.weekdays.contains(day['value'])
                      ? Colors.white
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mutedDark : AppColors.muted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _locationOption(LocationType.online, 'أونلاين', Icons.videocam_outlined),
          _locationOption(LocationType.inPerson, 'حضوري', Icons.place_outlined),
        ],
      ),
    );
  }

  Widget _locationOption(LocationType type, String label, IconData icon) {
    final selected = _data.locationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _data.locationType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : null),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    VoidCallback? onTap,
    String? error,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionLabel(label)),
            if (trailing != null) trailing,
          ],
        ),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              key: ValueKey('$label-$value'),
              initialValue: value,
              readOnly: true,
              decoration: InputDecoration(
                hintText: '--:--',
                prefixIcon: const Icon(Icons.access_time_outlined),
                errorText: error,
                suffixIcon: onTap == null
                    ? null
                    : const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionLabel(label)),
            if (trailing != null) trailing,
          ],
        ),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              key: ValueKey('$label-$value'),
              initialValue: value,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: onTap == null
                    ? null
                    : const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
