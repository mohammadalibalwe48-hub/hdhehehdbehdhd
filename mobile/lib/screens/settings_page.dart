import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/notifications_service.dart';
import '../services/secure_window.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';

const _kWebAppUrl = 'https://hdhehehdbehdhd.vercel.app';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsService.instance;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onChanged);
    _loadVersion();
  }

  @override
  void dispose() {
    _settings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => mounted ? setState(() {}) : null;

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {/* noop */}
  }

  // ---------------------------------------------------------------------------
  // Action handlers
  // ---------------------------------------------------------------------------

  Future<void> _onNotifyToggle(bool v) async {
    if (v) {
      final granted = await NotificationsService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        _snack('لتفعيل الإشعارات اسمح بها من إعدادات الجهاز.');
        return;
      }
    }
    await _settings.setNotifyEnabled(v);
  }

  Future<void> _pickMinutes() async {
    final current = _settings.notifyMinutesBefore;
    final options = const [5, 10, 15, 30, 60, 120];
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('اختر وقت التذكير',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
            for (final m in options)
              RadioListTile<int>(
                value: m,
                groupValue: current,
                onChanged: (v) => Navigator.of(ctx).pop(v),
                title: Text(_minutesLabel(m)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) await _settings.setNotifyMinutesBefore(result);
  }

  Future<void> _onTestNotification() async {
    final ok = await NotificationsService.instance.hasPermission()
        ? true
        : await NotificationsService.instance.requestPermission();
    if (!ok) {
      _snack('الإشعارات غير مسموح بها. فعّلها من الإعدادات.');
      return;
    }
    await NotificationsService.instance.showTestNotification();
    _snack('تم إرسال تنبيه تجريبي.');
  }

  Future<void> _pickTheme() async {
    final current = _settings.themeMode;
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('المظهر',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: current,
              title: const Text('حسب النظام'),
              secondary: const Icon(Icons.brightness_auto_outlined),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: current,
              title: const Text('فاتح'),
              secondary: const Icon(Icons.light_mode_outlined),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: current,
              title: const Text('داكن'),
              secondary: const Icon(Icons.dark_mode_outlined),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) await _settings.setThemeMode(result);
  }

  Future<void> _onSyncNow() async {
    HapticFeedback.selectionClick();
    _snack('جاري المزامنة…');
    try {
      await SyncService.instance.syncNow();
      _snack('تمت المزامنة.');
    } catch (e) {
      _snack('تعذّرت المزامنة: $e');
    }
  }

  Future<void> _onExport() async {
    try {
      final n = await BackupService.exportToJsonAndShare();
      _snack('تم تصدير $n درس.');
    } catch (e) {
      _snack('تعذّر التصدير: $e');
    }
  }

  Future<void> _onImport() async {
    final confirmed = await _confirm(
      'استيراد نسخة احتياطية',
      'ستتم إضافة الدروس من الملف إلى حسابك. هل تريد المتابعة؟',
    );
    if (!confirmed) return;
    try {
      final (added, _) = await BackupService.pickAndImport();
      if (added == 0) {
        _snack('لم يتم استيراد أي درس.');
      } else {
        _snack('تمت إضافة $added درس من الملف.');
      }
    } catch (e) {
      _snack('تعذّر الاستيراد: $e');
    }
  }

  Future<void> _onScreenshotToggle(bool v) async {
    await _settings.setScreenshotBlockEnabled(v);
    await SecureWindow.applyFromSettings();
    _snack(v
        ? 'لقطات الشاشة محظورة داخل التطبيق.'
        : 'تم السماح بلقطات الشاشة.');
  }

  Future<void> _openWebApp() async {
    final uri = Uri.parse(_kWebAppUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack('تعذّر فتح الرابط.');
    }
  }

  Future<void> _onSignOut() async {
    final ok =
        await _confirm('تسجيل الخروج', 'هل تريد الخروج من حساب Studies؟');
    if (!ok) return;
    await NotificationsService.instance.cancelAll();
    await AuthService.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 2)),
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
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  String _minutesLabel(int m) {
    if (m >= 60) {
      final h = m ~/ 60;
      return h == 1 ? 'قبل ساعة' : 'قبل $h ساعات';
    }
    return 'قبل $m دقيقة';
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.currentUser;
    final username =
        (user?.userMetadata?['username'] as String?) ?? user?.email ?? '—';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              pinned: false,
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.background,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: true,
              title: const Text('الإعدادات',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              centerTitle: false,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsetsDirectional.only(start: 56, bottom: 14),
                title: const Text('الإعدادات',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900)),
                background: _HeroBackground(isDark: isDark),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList.list(children: [
                _sectionHeader('الإشعارات', Icons.notifications_active_outlined),
                _SettingsCard(children: [
                  _SwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'التذكير قبل كل درس',
                    subtitle:
                        'سيصلك إشعار على الجهاز قبل بداية كل درس. يعمل دون إنترنت.',
                    value: _settings.notifyEnabled,
                    onChanged: _onNotifyToggle,
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.timer_outlined,
                    title: 'وقت التذكير',
                    trailingText: _minutesLabel(_settings.notifyMinutesBefore),
                    enabled: _settings.notifyEnabled,
                    onTap: _pickMinutes,
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.campaign_outlined,
                    title: 'إرسال تنبيه تجريبي',
                    subtitle: 'للتأكد أن الإشعارات تعمل على جهازك.',
                    onTap: _onTestNotification,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionHeader('المظهر', Icons.palette_outlined),
                _SettingsCard(children: [
                  _ActionTile(
                    icon: _themeIcon(_settings.themeMode),
                    title: 'المظهر',
                    trailingText: _themeLabel(_settings.themeMode),
                    onTap: _pickTheme,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionHeader('البيانات', Icons.folder_open_outlined),
                _SettingsCard(children: [
                  _ActionTile(
                    icon: Icons.sync_outlined,
                    title: 'مزامنة الآن',
                    subtitle:
                        'إرسال التغييرات غير المتزامنة وجلب أي جديد من الموقع.',
                    onTap: _onSyncNow,
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.ios_share_outlined,
                    title: 'تصدير نسخة احتياطية',
                    subtitle: 'حفظ كل الدروس كملف JSON.',
                    onTap: _onExport,
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.file_upload_outlined,
                    title: 'استيراد من ملف JSON',
                    subtitle: 'إضافة الدروس من نسخة احتياطية سابقة.',
                    onTap: _onImport,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionHeader('الخصوصية', Icons.shield_outlined),
                _SettingsCard(children: [
                  _SwitchTile(
                    icon: Icons.no_photography_outlined,
                    title: 'منع لقطات الشاشة',
                    subtitle:
                        'يظهر محتوى التطبيق أسود عند التقاط صورة أو تسجيل الشاشة.',
                    value: _settings.screenshotBlockEnabled,
                    onChanged: _onScreenshotToggle,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionHeader('الحساب', Icons.person_outline),
                _SettingsCard(children: [
                  _ActionTile(
                    icon: Icons.person_outline,
                    title: 'المستخدم',
                    trailingText: username,
                    onTap: null,
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.logout_outlined,
                    title: 'تسجيل الخروج',
                    destructive: true,
                    onTap: _onSignOut,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionHeader('حول', Icons.info_outline),
                _SettingsCard(children: [
                  _ActionTile(
                    icon: Icons.language_outlined,
                    title: 'فتح نسخة الويب',
                    subtitle: _kWebAppUrl,
                    onTap: _openWebApp,
                  ),
                  _Divider(),
                  _ActionTile(
                    icon: Icons.new_releases_outlined,
                    title: 'إصدار التطبيق',
                    trailingText: _version.isEmpty ? '…' : _version,
                    onTap: null,
                  ),
                ]),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'Studies — صُنع بحب ❤️',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color:
                  isDark ? AppColors.primaryGlow : AppColors.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: isDark ? AppColors.primaryGlow : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.system:
        return 'حسب النظام';
    }
  }
}

// =============================================================================
// Reusable pieces
// =============================================================================

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.gradientHeroDark : AppColors.gradientHero,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 56),
      child: Container(
        height: 1,
        color: (isDark ? AppColors.borderDark : AppColors.border)
            .withOpacity(0.6),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = destructive
        ? AppColors.destructive
        : (isDark ? Colors.white : const Color(0xFF0B1518));
    final muted =
        isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground;
    final opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (destructive
                          ? AppColors.destructive
                          : (isDark
                              ? AppColors.primaryGlow
                              : AppColors.primary))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: destructive
                        ? AppColors.destructive
                        : (isDark
                            ? AppColors.primaryGlow
                            : AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
                ),
              ],
              if (onTap != null && enabled) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_left, color: muted, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryGlow : AppColors.primary)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 20,
                color: isDark ? AppColors.primaryGlow : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                        fontSize: 12, color: muted, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
