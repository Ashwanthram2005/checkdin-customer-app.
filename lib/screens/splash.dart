import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api.dart';
import '../loading.dart';
import '../theme.dart';
import 'login.dart';

/// Animated logo intro.
/// Lockup geometry lives in a 653 x 200 unit box measured from the real logo:
/// disc r=100 at (100,100), wordmark from x=216 to x=653.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const double _total = 3.6; // seconds
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  bool _left = false;
  // Login check runs while the logo animates. If it isn't done when the logo
  // finishes, the animation holds and a spinner appears (next screen unknown).
  bool _ready = false, _loggedIn = false, _waiting = false, _showSpin = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final t = _c.value * _total;
      if (!_ready && !_waiting && t >= 2.95) {
        _waiting = true;
        _c.stop();
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_ready) setState(() => _showSpin = true);
        });
      }
      if (!_left && t >= 3.5) _leave();
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
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/'),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ));
  }

  /// Progress 0..1 of a segment [start, start+dur] in seconds.
  static double seg(double t, double start, double dur, [Curve curve = Curves.linear]) {
    final p = ((t - start) / dur).clamp(0.0, 1.0);
    return curve.transform(p);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final lockW = math.min(size.width * 0.78, 320.0);
    final u = lockW / 653;
    final lockH = 200 * u;
    final top = size.height * 0.42 - lockH / 2;

    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * _total;
            // icon slide/scale to final spot
            final slide = seg(t, 1.75, 0.55, Curves.easeOutCubic);
            final iconDx = (226.5 * (1 - slide)) * u;
            final iconScale = 1.45 - 0.45 * slide;
            // wordmark wipe + rise
            final wipe = seg(t, 1.85, 0.55, Curves.easeOutCubic);
            final rise = seg(t, 1.85, 0.5, Curves.easeOutBack);
            // tagline
            final tag = seg(t, 2.3, 0.4, Curves.easeOut);
            // exit
            final fade = 1 - seg(t, 3.25, 0.2);
            final flood = seg(t, 3.05, 0.55, Curves.easeInOutCubic);
            final diag = math.sqrt(size.width * size.width + size.height * size.height);

            return Stack(children: [
              if (_showSpin)
                Positioned(left: 0, right: 0, top: top + lockH + 56, child: const Center(child: Spinner(size: 26))),
              Positioned(
                left: (size.width - lockW) / 2,
                top: top,
                width: lockW,
                height: lockH,
                child: Opacity(
                  opacity: fade,
                  child: Stack(clipBehavior: Clip.none, children: [
                    // icon
                    Positioned(
                      left: iconDx,
                      top: 0,
                      width: 200 * u,
                      height: 200 * u,
                      child: Transform.scale(
                        scale: iconScale,
                        child: CustomPaint(painter: _IconPainter(t)),
                      ),
                    ),
                    // wordmark
                    Positioned(
                      left: 216 * u,
                      top: 0,
                      width: 437 * u,
                      height: 200 * u,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: wipe,
                          child: Opacity(
                            opacity: rise.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 40 * u * (1 - rise)),
                              child: SizedBox(
                                width: 437 * u,
                                height: 200 * u,
                                child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text('Checkdin',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 100, fontWeight: FontWeight.w800, color: C.ink, letterSpacing: -2, height: 1.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: top + lockH + 26,
                child: Opacity(
                  opacity: tag * fade,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - tag)),
                    child: Text('Hotel rooms by the hour',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w500, color: C.muted)),
                  ),
                ),
              ),
              if (flood > 0)
                Positioned(
                  left: size.width / 2 - diag * flood / 2,
                  top: top + lockH / 2 - diag * flood / 2,
                  width: diag * flood,
                  height: diag * flood,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: C.limeBg,
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final double t;
  _IconPainter(this.t);

  static double seg(double t, double s, double d, [Curve c = Curves.linear]) => _SplashScreenState.seg(t, s, d, c);
  static const _ink = Color(0xFF111111);
  static const _lime = Color(0xFFD1F148);
  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 200;
    canvas.save();
    canvas.scale(u);
    const c = Offset(100, 100);

    // ripple
    final rp = seg(t, 1.42, 0.7, Curves.easeOut);
    if (rp > 0 && rp < 1) {
      canvas.drawCircle(
          c,
          100 * (1 + 0.55 * rp),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = _lime.withAlpha((180 * (1 - rp)).round()));
    }

    // disc pop + beat
    var ds = seg(t, 0, 0.5, Curves.easeOutBack);
    final beat = seg(t, 1.42, 0.4);
    if (beat > 0 && beat < 1) ds *= 1 + 0.07 * math.sin(beat * math.pi);
    if (ds > 0) canvas.drawCircle(c, 100 * ds, Paint()..color = _lime);

    // ring draw synced with the hand
    final sweep = seg(t, 0.42, 0.62, Curves.easeInOutCubic);
    if (sweep > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: 63),
          _rad(-28),
          _rad(331 * sweep),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 15
            ..strokeCap = StrokeCap.round
            ..color = _ink);
    }

    // ticks pop as the hand passes
    final tickPaint = Paint()
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    const ticks = [
      [0.5, 146.0, 100.0, 155.0, 100.0],
      [0.66, 100.0, 146.0, 100.0, 155.0],
      [0.83, 54.0, 100.0, 45.0, 100.0],
      [0.98, 100.0, 54.0, 100.0, 45.0],
    ];
    for (final k in ticks) {
      final p = seg(t, k[0], 0.22, Curves.easeOutBack);
      if (p <= 0) continue;
      final a = Offset(k[1], k[2]), b = Offset(k[3], k[4]);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      canvas.drawLine(mid + (a - mid) * p, mid + (b - mid) * p, tickPaint);
    }

    // hand + pivot (fade out before the check)
    final handFade = 1 - seg(t, 1.02, 0.12);
    if (handFade > 0) {
      final ang = _rad(-28 + 331 * sweep);
      final hp = Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = _ink.withAlpha((255 * handFade).round());
      if (t >= 0.42) canvas.drawLine(c, c + Offset(math.cos(ang), math.sin(ang)) * 58, hp);
      final pv = seg(t, 0.32, 0.25, Curves.easeOutBack);
      if (pv > 0) canvas.drawCircle(c, 8 * pv, Paint()..color = _ink.withAlpha((255 * handFade).round()));
    }

    // check mark
    final ck = seg(t, 1.08, 0.34, Curves.easeOutCubic);
    if (ck > 0) {
      final path = Path()
        ..moveTo(74, 89)
        ..lineTo(96, 118)
        ..lineTo(140, 67);
      final m = path.computeMetrics().first;
      canvas.drawPath(
          m.extractPath(0, m.length * ck),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 15
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.t != t;
}
