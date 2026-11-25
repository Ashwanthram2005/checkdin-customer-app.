import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';

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
        padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
        child: Column(crossAxisAlignment: align, children: [
          Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Image.asset('assets/logo.png', height: 36),
            const Spacer(),
            if (trailing != null) trailing!,
          ]),
          SizedBox(height: compact ? 10 : 22),
          if (!compact) ...[
            Text(sub, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.muted)),
            const SizedBox(height: 8),
            Text(line1, style: style),
            Text(line2, style: style),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(14)),
            child: Text(compact ? '$line1 $line2 $marked' : marked, style: compact ? style.copyWith(fontSize: 30, letterSpacing: -1) : style),
          ),
          if (!compact) Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(20), child: art)))),
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
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: on ? C.lime : const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(999)),
          child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? C.ink : C.white)),
        );
    return Transform.rotate(
      angle: -9 * math.pi / 180,
      child: Container(
        width: 266,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: C.ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x47111111), blurRadius: 50, offset: Offset(0, 24))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ROOM KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: C.faint)),
                Text('Room 204', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.white)),
              ]),
            ),
            Container(width: 40, height: 30, decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(6))),
          ]),
          const SizedBox(height: 14),
          Row(children: [chip('3h', true), chip('6h', false), chip('9h', false), chip('12h', false)]),
          const SizedBox(height: 14),
          const Row(children: [
            Icon(Icons.schedule_rounded, size: 14, color: C.faint),
            SizedBox(width: 6),
            Text('Check-in 2:00 PM · Check-out 5:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.faint)),
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _ctrl.text.length == 10;
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
            trailing: TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Skip', style: TextStyle(color: C.ink, fontWeight: FontWeight.w700, fontSize: 15)),
                Icon(Icons.chevron_right_rounded, color: C.ink),
              ]),
            ),
          ),
        ),
        _Sheet(children: [
          const Text('Book your stay now', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text("We'll send your OTP on WhatsApp", style: TextStyle(fontSize: 15, color: C.muted)),
          const SizedBox(height: 20),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDADAD2), width: 1.5), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('+91', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              Container(width: 1.5, height: 20, color: C.ink, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter mobile number',
                    hintStyle: TextStyle(color: Color(0xFF7C7C74), fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          PillBtn('Get OTP on WhatsApp',
              kind: BtnKind.dark,
              height: 56,
              expand: true,
              onTap: ok
                  ? () {
                      app.set(() => app.phone = _ctrl.text);
                      Navigator.pushNamed(context, '/otp');
                    }
                  : null),
          const SizedBox(height: 14),
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
      decoration: const BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
