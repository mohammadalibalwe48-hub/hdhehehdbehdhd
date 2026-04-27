import 'package:flutter/material.dart';

/// In-app animated splash shown right after the OS-level native splash finishes.
///
/// The native splash (white background + logo) stays on screen until Flutter
/// renders its first frame. This widget picks up from there and plays a
/// scale + fade-in + subtle float animation on the banner, then transitions
/// into whatever [child] is (the root gate / auth page / home page).
class AnimatedSplash extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSplash({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final AnimationController _outro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _outro.forward();
      if (!mounted) return;
      setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    _outro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Actual app — mounted from the start so nav/state is ready.
        Positioned.fill(child: widget.child),
        if (!_gone)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _float, _outro]),
              builder: (context, _) {
                final intro = Curves.easeOutCubic.transform(_intro.value);
                final outro = _outro.value;
                final floatY =
                    (Curves.easeInOut.transform(_float.value) - 0.5) * 10;
                return Opacity(
                  opacity: (1 - outro).clamp(0.0, 1.0),
                  child: Container(
                    color: isDark ? const Color(0xFF0B1518) : Colors.white,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, floatY + (1 - intro) * 40),
                        child: Transform.scale(
                          scale: 0.85 + 0.15 * intro,
                          child: Opacity(
                            opacity: intro,
                            child: const _SplashBanner(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SplashBanner extends StatelessWidget {
  const _SplashBanner();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Image.asset(
          'assets/banner.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
