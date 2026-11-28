import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

/// Shared top half used by login / OTP: logo + headline + illustration.
class HeroTop extends StatelessWidget {
  final String sub;
  final String line1, line2, marked;
  final Widget art;
  final bool center;
  final Widget? leading;
  final Widget? trailing;
  const HeroTop({
    super.key,
    required this.sub,
    required this.line1,
    required this.line2,
    required this.marked,
    required this.art,
    this.center = true,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight - top;
      final compact = h < 380;
      final fs = (h * 0.13).clamp(34.0, 64.0).toDouble();
      final style = TextStyle(fontSize: fs, fontWeight: FontWeight.w800, letterSpacing: -fs * 0.04, height: 1.0);
      final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
      return Padding(
        padding: EdgeInsets.fromLTRB(Sp.xl, top + Sp.md, Sp.xl, 0),
        child: Column(crossAxisAlignment: align, children: [
          Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: Sp.md)],
            Image.asset('assets/logo.png', height: 36),
            const Spacer(),
            if (trailing != null) trailing!,
          ]),
          SizedBox(height: compact ? 10 : 22),
          if (!compact) ...[
            Text(sub, style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w600, color: C.muted)),
            const SizedBox(height: Sp.sm),
            Text(line1, style: style),
            Text(line2, style: style),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Sp.md),
            decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.lg)),
            child: Text(compact ? '$line1 $line2 $marked' : marked, style: compact ? style.copyWith(fontSize: Fs.h1, letterSpacing: -1) : style),
          ),
          if (!compact) Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(Sp.xl), child: art)))),
        ]),
      );
    });
  }
}

/// Black room key card.
class KeyCard extends StatelessWidget {
  const KeyCard({super.key});
  @override
  Widget build(BuildContext context) {
    Widget chip(String t, bool on) => Container(
          margin: const EdgeInsets.only(right: Sp.sm),
          padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
          decoration: BoxDecoration(color: on ? C.limeBg : P.grey16, borderRadius: BorderRadius.circular(R.pill)),
          child: Text(t, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: on ? C.ink : C.white)),
        );
    return Transform.rotate(
      angle: -9 * math.pi / 180,
      child: Container(
        width: 266,
        padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.lg),
        decoration: BoxDecoration(
          color: C.inkBg,
          borderRadius: BorderRadius.circular(R.xl),
          boxShadow: const [BoxShadow(color: P.inkA28, blurRadius: 50, offset: Offset(0, 24))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ROOM KEY', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: C.faint)),
                Text('Room 204', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w700, color: C.white)),
              ]),
            ),
            Container(width: 40, height: 30, decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.sm))),
          ]),
          const SizedBox(height: Sp.lg),
          Row(children: [chip('3h', true), chip('6h', false), chip('9h', false), chip('12h', false)]),
          const SizedBox(height: Sp.lg),
          Row(children: [
            Icon(Icons.schedule_rounded, size: Ic.sm, color: C.faint),
            SizedBox(width: Sp.sm),
            Flexible(
              child: Text('Check-in 2:00 PM · Check-out 5:00 PM',
                  maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, color: C.faint)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrl = TextEditingController();

  final _shake = GlobalKey<ShakeState>();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _sending = false;

  Future<void> _getOtp() async {
    if (_sending) return;
    final n = _ctrl.text;
    final err = n.isEmpty
        ? 'Enter your mobile number'
        : n.length != 10
            ? 'Mobile numbers have 10 digits'
            : !RegExp(r'^[6-9]').hasMatch(n)
                ? 'Indian mobile numbers start with 6, 7, 8 or 9'
                : null;
    if (err != null) {
      setState(() => _err = err);
      _shake.currentState?.shake();
      return;
    }
    setState(() => _sending = true);
    try {
      await api.sendOtp(n);
      if (!mounted) return;
      app.set(() => app.phone = n);
      Navigator.pushNamed(context, '/otp');
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _err = e.message);
      _shake.currentState?.shake();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        Expanded(
          child: HeroTop(
            sub: 'Pay only for the hours you stay.',
            line1: 'Stay',
            line2: 'by the',
            marked: 'hour.',
            art: const KeyCard(),
          ),
        ),
        _Sheet(children: [
          const Text('Book your stay now', style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w700)),
          const SizedBox(height: Sp.xs),
          Text("We'll send your OTP on WhatsApp", style: TextStyle(fontSize: Fs.md, color: C.muted)),
          const SizedBox(height: Sp.xl),
          Shake(
            key: _shake,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
            decoration: BoxDecoration(border: Border.all(color: _err != null ? C.red : P.border, width: 1.5), borderRadius: BorderRadius.circular(R.lg)),
            child: Row(children: [
              const Text('+91', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w600)),
              Container(width: 1.5, height: 20, color: C.inkBg, margin: const EdgeInsets.symmetric(horizontal: Sp.md)),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  onChanged: (_) => setState(() => _err = null),
                  onSubmitted: (_) => _getOtp(),
                  style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter mobile number',
                    hintStyle: TextStyle(color: P.hint, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ]),
          ),
          ),
          FieldError(_err),
          const SizedBox(height: Sp.lg),
          PillBtn('Get OTP on WhatsApp',
              kind: BtnKind.dark,
              height: 56,
              expand: true,
              loading: _sending,
              onTap: _getOtp),
          const SizedBox(height: Sp.lg),
          Row(children: [
            Expanded(child: Divider(color: C.border)),
            Padding(padding: EdgeInsets.symmetric(horizontal: Sp.md), child: Text('or', style: TextStyle(fontSize: Fs.base, color: C.muted))),
            Expanded(child: Divider(color: C.border)),
          ]),
          const SizedBox(height: Sp.lg),
          Material(
            color: C.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill), side: BorderSide(color: C.border, width: 1.5)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => _google(context),
              child: SizedBox(
                height: 54,
                child: ValueListenableBuilder<bool>(
                  valueListenable: googleBusy,
                  builder: (_, busy, __) => busy
                      ? const Center(child: Spinner())
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _GoogleMark(),
                          SizedBox(width: Sp.md),
                          Text('Continue with Google', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: Sp.lg),
          const LegalLine(),
        ]),
      ]),
    );
  }
}

class _Sheet extends StatelessWidget {
  final List<Widget> children;
  const _Sheet({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 26, 24, 18 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
        boxShadow: kSheetShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Exposed so OTP and profile screens use the same sheet.
class AuthSheet extends StatelessWidget {
  final List<Widget> children;
  const AuthSheet({super.key, required this.children});
  @override
  Widget build(BuildContext context) => _Sheet(children: children);
}


/// Four-colour ring mark for the Google button.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(3, 3, s.width - 6, s.height - 6);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const cols = [P.googleBlue, P.googleGreen, P.googleYellow, P.googleRed];
    const starts = [-0.25, 0.55, 1.05, 1.55];
    const sweeps = [0.8, 0.5, 0.5, 0.45];
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(r, starts[i] * 3.14159, sweeps[i] * 3.14159, false, p..color = cols[i]);
    }
    canvas.drawLine(Offset(s.width / 2, s.height / 2), Offset(s.width - 3, s.height / 2), p..color = cols[0]);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Google account picker. Real sign-in needs a Google Cloud OAuth client (see README).
final googleBusy = ValueNotifier<bool>(false);

Future<void> _google(BuildContext context) async {
  if (googleBusy.value) return;
  final emailCtrl = TextEditingController();
  final picked = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final other = emailCtrl.text.trim();
      final validOther = RegExp(r'^[\w.+-]+@gmail\.com$').hasMatch(other) || RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(other);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs)))),
            const SizedBox(height: Sp.lg),
            const Row(children: [_GoogleMark(), SizedBox(width: Sp.md), Text('Sign in with Google', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))]),
            const SizedBox(height: Sp.lg),
            const Text('Choose an account', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
            Text('to continue to Checkdin', style: TextStyle(fontSize: Fs.base, color: C.muted)),
            const SizedBox(height: Sp.lg),
            InkWell(
              borderRadius: BorderRadius.circular(R.lg),
              onTap: () => Navigator.pop(ctx, ['Ashwanth', 'ashwanth@gmail.com']),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.md),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle),
                    child: Text('A', style: TextStyle(color: C.lime, fontWeight: FontWeight.w800, fontSize: Fs.lg)),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ashwanth', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      Text('ashwanth@gmail.com', style: TextStyle(fontSize: Fs.base, color: C.muted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ),
            Divider(color: C.line),
            const SizedBox(height: Sp.sm),
            Text('Use another account', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.muted)),
            const SizedBox(height: Sp.sm),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => set(() {}),
                  decoration: InputDecoration(
                    hintText: 'you@gmail.com',
                    isDense: true,
                    filled: true,
                    fillColor: C.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: Sp.sm),
              PillBtn('Next', kind: BtnKind.dark, height: 48, fontSize: Fs.md,
                  onTap: validOther ? () => Navigator.pop(ctx, [other.split('@').first, other]) : null),
            ]),
            const SizedBox(height: Sp.lg),
            Text('Google will share your name and email address with Checkdin. Checkdin never sees your Google password.',
                style: TextStyle(fontSize: Fs.sm, color: C.muted2, height: 1.45)),
          ]),
        ),
      );
    }),
  );
  // Wait for the sheet's close animation before freeing the text box.
  Future<void>.delayed(const Duration(milliseconds: 600), emailCtrl.dispose);
  if (picked == null || !context.mounted) return;
  googleBusy.value = true;
  try {
    await api.googleSignIn(picked[1]);
  } on ApiError catch (e) {
    googleBusy.value = false;
    if (context.mounted) toast(context, e.message);
    return;
  }
  googleBusy.value = false;
  if (!context.mounted) return;
  app.set(() {
    app.name = picked[0].isEmpty ? '' : picked[0][0].toUpperCase() + picked[0].substring(1);
    app.email = picked[1];
    app.googleAccount = true;
  });
  toast(context, 'Signed in as ${picked[1]}');
  Navigator.pushNamed(context, '/profile-setup');
}
