import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_gate.dart';

/// Menampilkan splash screen beranimasi sambil memuat sesi pengguna,
/// lalu berpindah ke [AuthGate].
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const Duration _minimumDuration = Duration(milliseconds: 2200);
  static const Duration _maximumWait = Duration(seconds: 8);

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    auth.startRecoveryListener();

    final minimumDelay = Future<void>.delayed(_minimumDuration);
    final sessionLoad = auth.hasLoaded
        ? Future<void>.value()
        : auth.loadUser().timeout(_maximumWait, onTimeout: () {});

    await Future.wait<void>([minimumDelay, sessionLoad]);

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _ready
          ? const AuthGate(key: ValueKey('auth-gate'))
          : const SplashScreen(key: ValueKey('splash-screen')),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9F1), AppColors.shopBackground, Color(0xFFFFE9D6)],
          ),
        ),
        child: Stack(
          children: [
            const _SoftBubble(
              alignment: Alignment(-1.25, -1.05),
              size: 260,
              color: Color(0x1AFF914D),
            ),
            const _SoftBubble(
              alignment: Alignment(1.3, 0.95),
              size: 300,
              color: Color(0x14D63F32),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    _AnimatedEntry(
                      visible: _visible,
                      offset: const Offset(0, 18),
                      child: const _LogoCard(),
                    ),
                    const SizedBox(height: 26),
                    _AnimatedEntry(
                      visible: _visible,
                      offset: const Offset(0, 14),
                      delay: const Duration(milliseconds: 110),
                      child: const _Wordmark(),
                    ),
                    const SizedBox(height: 10),
                    _AnimatedEntry(
                      visible: _visible,
                      offset: const Offset(0, 10),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Selamatin makanannya!!! Kenyangin perutmu, amanin dompetmu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _AnimatedEntry(
                      visible: _visible,
                      offset: Offset.zero,
                      delay: const Duration(milliseconds: 320),
                      child: const _LoadingLine(),
                    ),
                    const SizedBox(height: 22),
                    _AnimatedEntry(
                      visible: _visible,
                      offset: Offset.zero,
                      delay: const Duration(milliseconds: 380),
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1,
        ),
        children: [
          const TextSpan(
            text: 'Kenyang',
            style: TextStyle(color: AppColors.primary),
          ),
          TextSpan(
            text: 'in',
            style: TextStyle(color: AppColors.orange.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.orangeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/kenyangin_logo.jpg',
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: AppColors.orangeSoft,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({
    required this.visible,
    required this.child,
    this.offset = const Offset(0, 12),
    this.delay = Duration.zero,
  });

  final bool visible;
  final Widget child;
  final Offset offset;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = delay + const Duration(milliseconds: 650);
    final start = delay.inMilliseconds / total.inMilliseconds;

    return AnimatedSlide(
      offset: visible ? Offset.zero : offset,
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: total,
        curve: Interval(start, 1, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

class _SoftBubble extends StatelessWidget {
  const _SoftBubble({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
