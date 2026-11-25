import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import 'login.dart';

class DoorHanger extends StatelessWidget {
  const DoorHanger({super.key});
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 10 * math.pi / 180,
      child: Container(
        width: 150,
        height: 210,
        padding: const EdgeInsets.only(top: 18),
        decoration: BoxDecoration(
          color: C.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x47111111), blurRadius: 50, offset: Offset(0, 24))],
        ),
        child: Column(children: [
          Container(width: 52, height: 52, decoration: const BoxDecoration(color: C.bg, shape: BoxShape.circle)),
          Container(width: 10, height: 16, color: C.bg),
          const SizedBox(height: 14),
          const Text('Shh…', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: -1)),
          const SizedBox(height: 6),
          const Text('Resting till\n5:00 PM',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.faint, height: 1.4)),
        ]),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _secs = 30;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _secs = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secs = math.max(0, _secs - 1));
      if (_secs == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool get _ok => _ctrls.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final phone = app.phone.isEmpty ? '98765 43210' : '${app.phone.substring(0, 5)} ${app.phone.substring(5)}';
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: HeroTop(
            center: false,
            sub: 'One last step.',
            line1: 'Almost',
            line2: 'checked',
            marked: 'in.',
            art: const DoorHanger(),
            trailing: const BackBtn(),
          ),
        ),
        AuthSheet(children: [
          const Text('Verify your number', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
            Text.rich(TextSpan(style: const TextStyle(fontSize: 15, color: C.muted), children: [
              const TextSpan(text: "We've sent an OTP on WhatsApp to "),
              TextSpan(text: '+91 $phone', style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700)),
            ])),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Edit number',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 14 : 0),
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      autofocus: i == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDADAD2), width: 1.5)),
                        focusedBorder:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.ink, width: 1.5)),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
                        if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          PillBtn('Verify & continue',
              kind: BtnKind.dark,
              height: 56,
              expand: true,
              onTap: _ok ? () => Navigator.pushNamedAndRemoveUntil(context, '/profile-setup', (_) => false) : null),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(child: Text("Didn't get the code?", style: TextStyle(fontSize: 15, color: C.muted))),
            if (_secs > 0)
              Text('Resend in 0:${_secs.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF7C7C74)))
            else
              TextButton.icon(
                onPressed: () {
                  _start();
                  toast(context, 'New OTP sent on WhatsApp');
                },
                icon: const Icon(Icons.refresh_rounded, size: 18, color: C.ink),
                label: const Text('Resend OTP',
                    style: TextStyle(color: C.ink, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
              ),
          ]),
        ]),
      ]),
    );
  }
}
