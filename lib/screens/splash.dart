import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api.dart';
import '../loading.dart';
import '../state.dart';
import '../theme.dart';
import 'login.dart';
import 'onboarding.dart';

/// Intro: soft lime glow, full-colour logo, "Hotel rooms [by the hour]".
/// About 2 s, then a seamless fade into Onboarding (first launch), Login or Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const double _total = 1.85; // seconds
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1850));
  bool _left = false, _ready = false, _loggedIn = false, _waiting = false, _showSpin = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final t = _c.value * _total;
      // Hold the finished logo until the login check is done.
      if (!_ready && !_waiting && t >= 1.45) {
        _waiting = true;
        _c.stop();
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_ready) setState(() => _showSpin = true);
        });
      }
    });
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _leave();
    });
    _c.forward();
    api.restoreSession().then((v) => _loggedIn = v, onError: (_) => _loggedIn = false).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _showSpin = false;
      });
      if (_waiting) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left || !mounted || !_ready) return;
    _left = true;
    if (_loggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }
    final next = app.onboarded ? const LoginScreen() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      settings: RouteSettings(name: app.onboarded ? '/' : '/onboarding'),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => next,
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.016), end: Offset.zero).animate(c), child: child),
        );
      },
    ));
  }

  static double seg(double t, double start, double dur) => ((t - start) / dur).clamp(0.0, 1.0);
  static double quint(double p) => 1 - math.pow(1 - p, 5).toDouble();
  static double cubic(double p) => 1 - math.pow(1 - p, 3).toDouble();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cy = size.height * 0.42;
    const iw = 112.0;
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_ready) {
            _c.stop();
            _leave();
          }
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * _total;
            final out = cubic(seg(t, 1.5, 0.35));
            final glow = cubic(seg(t, 0, 0.8)) * (1 - out);
            final disc = quint(seg(t, 0, 0.5));
            final mark = quint(seg(t, 0.18, 0.5));
            final word = quint(seg(t, 0.42, 0.5));
            final tag1 = quint(seg(t, 0.62, 0.4));
            final pill = quint(seg(t, 0.78, 0.45));
            final pillText = quint(seg(t, 0.98, 0.3));
            return Stack(children: [
              // soft lime glow
              Positioned(
                left: size.width / 2 - 320,
                top: cy - 320,
                width: 640,
                height: 640,
                child: Opacity(
                  opacity: glow,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [Color(0x73D1F148), Color(0x33D1F148), Color(0x00D1F148)], stops: [0, 0.45, 1]),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 1 - out,
                  child: Transform.scale(
                    scale: 1 - 0.03 * out,
                    child: Stack(children: [
                      // logo: lime disc + clock mark
                      Positioned(
                        left: size.width / 2 - iw / 2,
                        top: cy - iw / 2,
                        width: iw,
                        height: iw,
                        child: Stack(fit: StackFit.expand, children: [
                          Opacity(
                            opacity: disc,
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * disc,
                              child: const DecoratedBox(decoration: BoxDecoration(color: P.lime, shape: BoxShape.circle)),
                            ),
                          ),
                          Opacity(
                            opacity: mark,
                            child: Transform.rotate(
                              angle: -24 * math.pi / 180 * (1 - mark),
                              child: Transform.scale(scale: 0.92 + 0.08 * mark, child: Image.asset('assets/logo_mark_ink.png', fit: BoxFit.contain)),
                            ),
                          ),
                        ]),
                      ),
                      // wordmark rises out of a mask
                      Positioned(
                        left: 0,
                        right: 0,
                        top: cy + iw / 2 + 28,
                        child: Center(
                          child: SizedBox(
                            width: 176,
                            height: 33,
                            child: ClipRect(
                              child: Transform.translate(
                                offset: Offset(0, 22 * (1 - word)),
                                child: Opacity(opacity: (word * 1.4).clamp(0.0, 1.0), child: Image.asset('assets/logo_word_ink.png', fit: BoxFit.contain)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // tagline: Hotel rooms [by the hour]
                      Positioned(
                        left: 0,
                        right: 0,
                        top: cy + iw / 2 + 78,
                        child: Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Opacity(
                              opacity: tag1,
                              child: Transform.translate(
                                offset: Offset(0, 6 * (1 - tag1)),
                                child: Text('Hotel rooms ',
                                    style: GoogleFonts.plusJakartaSans(fontSize: Fs.lg, fontWeight: FontWeight.w600, color: P.ink2)),
                              ),
                            ),
                            ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: pill,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xxs),
                                  decoration: BoxDecoration(color: P.ink, borderRadius: BorderRadius.circular(R.sm)),
                                  child: Opacity(
                                    opacity: pillText,
                                    child: Text('by the hour',
                                        style: GoogleFonts.plusJakartaSans(fontSize: Fs.lg, fontWeight: FontWeight.w800, color: P.lime)),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              if (_showSpin) Positioned(left: 0, right: 0, top: cy + iw / 2 + 130, child: const Center(child: Spinner(size: 26))),
            ]);
          },
        ),
      ),
    );
  }
}
