import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../photos.dart';
import '../state.dart';
import '../theme.dart';
import 'login.dart';

Future<void> loadOnboarded() async {
  try {
    final p = await SharedPreferences.getInstance();
    app.onboarded = p.getBool('onboarded') ?? false;
  } catch (_) {}
}

Future<void> _markOnboarded() async {
  app.onboarded = true;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarded', true);
  } catch (_) {}
}

/// Three slides that explain Checkdin. First launch only.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  double _page = 0;

  static const _slides = [
    ('Book by the ', 'hour', ['Choose 3, 6, 9 or 12 hours.', 'Pay only for the time you stay.']),
    ('Stays you can ', 'trust', ['Verified hotels, couple friendly,', 'local ID accepted. Rules shown upfront.']),
    ('Check in with an ', 'OTP', ['Show your 4-digit code at the desk.', 'Extend anytime, cancel easily.']),
  ];

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await _markOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/'),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final idx = _page.round().clamp(0, 2);
    final last = idx == 2;
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        // soft lime glow behind the pictures
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.33 - 300,
          height: 600,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [Color(0x59D1F148), Color(0x24D1F148), Color(0x00D1F148)], stops: [0, 0.45, 1]),
            ),
          ),
        ),
        PageView.builder(
          controller: _pc,
          itemCount: 3,
          itemBuilder: (_, i) {
            final s = _slides[i];
            final d = (_page - i); // -1..1 while swiping
            return Padding(
              padding: EdgeInsets.fromLTRB(Sp.xl, pad.top + 72, Sp.xl, 0),
              child: Column(children: [
                Expanded(
                  flex: 11,
                  child: Transform.translate(
                    offset: Offset(-60 * d, 0),
                    child: Opacity(opacity: (1 - d.abs()).clamp(0.0, 1.0), child: Center(child: [const _SlotsArt(), const _TrustArt(), const _OtpArt()][i])),
                  ),
                ),
                const SizedBox(height: Sp.xxl),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: s.$1),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                        decoration: BoxDecoration(color: P.lime, borderRadius: BorderRadius.circular(R.md)),
                        child: Text(s.$2, style: GoogleFonts.plusJakartaSans(fontSize: Fs.h1, fontWeight: FontWeight.w800, color: P.ink, letterSpacing: -0.6)),
                      ),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: Fs.h1, fontWeight: FontWeight.w800, color: C.ink, letterSpacing: -0.6),
                ),
                const SizedBox(height: Sp.md),
                for (final l in s.$3)
                  Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
                const Spacer(flex: 7),
              ]),
            );
          },
        ),
        // top bar
        Positioned(
          left: Sp.xl,
          right: Sp.sm,
          top: pad.top + Sp.md,
          child: Row(children: [
            Image.asset('assets/logo_icon.png', width: 28, height: 28),
            const SizedBox(width: Sp.sm),
            Text('Checkdin', style: GoogleFonts.plusJakartaSans(fontSize: Fs.lg, fontWeight: FontWeight.w800, color: C.ink)),
            const Spacer(),
            TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: C.ink),
              child: const Text('Skip', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        // dots + button
        Positioned(
          left: Sp.xl,
          right: Sp.xl,
          bottom: pad.bottom + Sp.xl,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: Sp.xs),
                  width: i == idx ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == idx ? C.ink : P.grey87, borderRadius: BorderRadius.circular(R.pill)),
                ),
            ]),
            const SizedBox(height: Sp.xl),
            PillBtn(
              last ? 'Get started' : 'Next',
              kind: last ? BtnKind.lime : BtnKind.dark,
              icon: Icons.arrow_forward_rounded,
              trailingIcon: true,
              onTap: () => last ? _finish() : _pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- art

BoxDecoration _cardDeco(Color c, double r) => BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(r),
      boxShadow: const [BoxShadow(color: Color(0x26111111), blurRadius: 30, offset: Offset(0, 14))],
    );

Widget _chip(String t, {required Color bg, required Color fg}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs + 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.pill)),
      child: Text(t, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: fg)),
    );

class _SlotsArt extends StatelessWidget {
  const _SlotsArt();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 250,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 10,
          top: 20,
          child: Transform.rotate(
            angle: -0.1,
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(Sp.lg + 2),
              decoration: _cardDeco(P.ink, R.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('ROOM KEY', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: Color(0xFFA0A398), letterSpacing: 1)),
                  const Spacer(),
                  Container(width: 34, height: 24, decoration: BoxDecoration(color: P.lime, borderRadius: BorderRadius.circular(R.sm))),
                ]),
                const Text('Room 204', style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: Sp.md),
                Row(children: [
                  _chip('3h', bg: P.lime, fg: P.ink),
                  for (final h in ['6h', '9h', '12h']) ...[const SizedBox(width: Sp.xs + 2), _chip(h, bg: const Color(0xFF2C2E28), fg: Colors.white)],
                ]),
                const SizedBox(height: Sp.md),
                const Text('Check-in 2:00 PM · Check-out 5:00 PM', style: TextStyle(fontSize: Fs.xs, color: Color(0xFFA0A398))),
              ]),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 6,
          child: Transform.rotate(
            angle: 0.07,
            child: Container(
              padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.sm),
              decoration: _cardDeco(Colors.white, R.lg),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('3 hours', style: TextStyle(fontSize: Fs.xs, color: P.muted, fontWeight: FontWeight.w600)),
                Text('₹849', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, color: P.ink)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TrustArt extends StatelessWidget {
  const _TrustArt();
  @override
  Widget build(BuildContext context) {
    final h = hotels.first;
    return SizedBox(
      width: 300,
      height: 260,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 14,
          top: 30,
          child: Transform.rotate(
            angle: -0.05,
            child: Container(
              width: 264,
              padding: const EdgeInsets.all(Sp.md),
              decoration: _cardDeco(Colors.white, R.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  NetPhoto(coverOf(h), height: 110, radius: R.lg, w: 600),
                  Positioned(
                    left: Sp.sm,
                    top: Sp.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.sm + 2, vertical: Sp.xs),
                      decoration: BoxDecoration(color: P.lime, borderRadius: BorderRadius.circular(R.pill)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_rounded, size: Ic.sm, color: P.ink),
                        SizedBox(width: Sp.xs),
                        Text('Verified', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: P.ink)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: Sp.md),
                Text(h.name, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800, color: P.ink)),
                Text('${h.area} · ${h.distanceKm} km away', style: const TextStyle(fontSize: Fs.xs, color: P.muted)),
                const SizedBox(height: Sp.sm),
                Row(children: [
                  _chip('Couple friendly', bg: P.grey94, fg: P.ink),
                  const SizedBox(width: Sp.xs + 2),
                  _chip('Local ID OK', bg: P.grey94, fg: P.ink),
                ]),
              ]),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 64,
            height: 64,
            decoration: _cardDeco(P.ink, R.pill),
            child: const Icon(Icons.verified_user_rounded, color: P.lime, size: Ic.xl),
          ),
        ),
      ]),
    );
  }
}

class _OtpArt extends StatelessWidget {
  const _OtpArt();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 240,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 12,
          top: 20,
          child: Transform.rotate(
            angle: -0.07,
            child: Container(
              width: 264,
              padding: const EdgeInsets.all(Sp.lg + 2),
              decoration: _cardDeco(P.ink, R.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CHECK-IN OTP', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: Color(0xFFA0A398), letterSpacing: 1)),
                const SizedBox(height: Sp.md),
                Row(children: [
                  for (final d in '4827'.split(''))
                    Container(
                      width: 50,
                      height: 60,
                      margin: const EdgeInsets.only(right: Sp.sm),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFF2C2E28), borderRadius: BorderRadius.circular(R.md)),
                      child: Text(d, style: const TextStyle(fontSize: Fs.h2 + 2, fontWeight: FontWeight.w800, color: P.lime)),
                    ),
                ]),
                const SizedBox(height: Sp.md),
                const Text('Show this at the front desk', style: TextStyle(fontSize: Fs.xs, color: Color(0xFFA0A398))),
              ]),
            ),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Transform.rotate(
            angle: 0.08,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.md),
              decoration: _cardDeco(P.lime, R.pill),
              child: const Text('+1 hr  Extend', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w800, color: P.ink)),
            ),
          ),
        ),
      ]),
    );
  }
}
