import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// Redesigned auth screen: floating Studies banner, frosted card, animated
/// entrance. Same username/password logic as before, just a fresher look.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _showPassword = false;
  bool _loading = false;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _entry.dispose();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(display)));
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
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0E1B1F), Color(0xFF0B1518)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEDF2FF), Color(0xFFF9FBFF), Color(0xFFFFFFFF)],
                ),
        ),
        child: Stack(
          children: [
            // Soft colored blobs in the background.
            Positioned(
              top: -140,
              right: -80,
              child: _blob(260, const Color(0xFF2F6FE5)
                  .withOpacity(isDark ? 0.22 : 0.18)),
            ),
            Positioned(
              top: 180,
              left: -120,
              child: _blob(220, const Color(0xFF34C759)
                  .withOpacity(isDark ? 0.16 : 0.14)),
            ),
            Positioned(
              bottom: -160,
              right: -100,
              child: _blob(320, const Color(0xFF1EA594)
                  .withOpacity(isDark ? 0.16 : 0.10)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: AnimatedBuilder(
                    animation: _entry,
                    builder: (context, _) {
                      final t = Curves.easeOutCubic.transform(_entry.value);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _brandHeader(context, isDark),
                                const SizedBox(height: 22),
                                _card(context, isDark),
                                const SizedBox(height: 16),
                                _footerNote(context, isDark),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0)],
            ),
          ),
        ),
      );

  Widget _brandHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F6FE5).withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE6EEFB),
            ),
          ),
          child: Image.asset(
            'assets/icon_square.png',
            width: 96,
            height: 96,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Studies',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1F4AA3),
                letterSpacing: -0.5,
                fontSize: 40,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin
              ? 'مرحباً بعودتك، سجل دخولك لمتابعة دروسك'
              : 'أنشئ حساباً جديداً وابدأ تنظيم دروسك',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForeground,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withOpacity(0.92) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE6EEFB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _tabSwitcher(isDark),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  controller: _usernameCtrl,
                  label: 'اسم المستخدم',
                  hint: 'أدخل اسم المستخدم',
                  icon: Icons.person_outline,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'الرجاء إدخال اسم المستخدم';
                    if (value.length < 3) return 'يجب أن يكون 3 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _passwordCtrl,
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: !_showPassword,
                  suffix: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForeground,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (v) {
                    if ((v ?? '').length < 6) {
                      return 'يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                _primaryButton(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerNote(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'ليس لديك حساب؟ ' : 'لديك حساب بالفعل؟ ',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForeground,
              ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isLogin = !_isLogin),
          child: Text(
            _isLogin ? 'أنشئ حساباً' : 'سجل الدخول',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isDark ? const Color(0xFF6AA3FF) : const Color(0xFF2F6FE5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : const Color(0xFF2F6FE5)),
            suffixIcon: suffix,
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF3F6FC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE6EEFB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE6EEFB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF2F6FE5),
                width: 1.8,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _tabSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tab(
              label: 'تسجيل الدخول',
              selected: _isLogin,
              onTap: () => setState(() => _isLogin = true)),
          _tab(
              label: 'حساب جديد',
              selected: !_isLogin,
              onTap: () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A7BF0), Color(0xFF2F6FE5)],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2F6FE5).withOpacity(0.28),
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
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A7BF0), Color(0xFF2F6FE5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F6FE5).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.6,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
