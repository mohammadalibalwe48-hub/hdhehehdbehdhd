import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _showPassword = false;
  bool _loading = false;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.signIn(_usernameCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await AuthService.signUp(_usernameCtrl.text.trim(), _passwordCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح! 🎉')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String display = 'حدث خطأ، يرجى المحاولة مرة أخرى';
      if (msg.contains('Invalid login')) {
        display = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      } else if (msg.contains('already registered') ||
          msg.contains('User already')) {
        display = 'اسم المستخدم مستخدم مسبقاً';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(display)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.gradientHeroDark : AppColors.gradientHero,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _blob(180, AppColors.primary.withOpacity(isDark ? 0.18 : 0.22)),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _blob(260, AppColors.accent.withOpacity(isDark ? 0.16 : 0.20)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      _Logo(isDark: isDark),
                      const SizedBox(height: 24),
                      Text(
                        'جدول دروسي',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'نظم دروسك بسهولة وذكاء ✨',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForeground,
                            ),
                      ),
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildCard(context, isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      );

  Widget _buildCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _tabSwitcher(isDark),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _label('اسم المستخدم'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'أدخل اسم المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'الرجاء إدخال اسم المستخدم';
                    if (value.length < 3) return 'يجب أن يكون 3 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label('كلمة المرور'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    if ((v ?? '').length < 6) {
                      return 'يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _gradientButton(),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'ليس لديك حساب؟ ' : 'لديك حساب بالفعل؟ ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'أنشئ حساباً' : 'سجل الدخول',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.primaryGlow
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );

  Widget _tabSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mutedDark : AppColors.muted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tab(label: 'تسجيل الدخول', selected: _isLogin, onTap: () => setState(() => _isLogin = true)),
          _tab(label: 'حساب جديد', selected: !_isLogin, onTap: () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _tab({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _loading ? null : _submit,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
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
    );
  }
}

class _Logo extends StatelessWidget {
  final bool isDark;
  const _Logo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.45),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(Icons.auto_stories_outlined,
              color: Colors.white, size: 48),
        ),
        Positioned(
          top: -6,
          left: -6,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.gradientAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
