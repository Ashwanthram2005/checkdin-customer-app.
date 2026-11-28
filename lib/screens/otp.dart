import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
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
        padding: const EdgeInsets.only(top: Sp.lg),
        decoration: BoxDecoration(
          color: C.inkBg,
          borderRadius: BorderRadius.circular(R.xl),
          boxShadow: const [BoxShadow(color: P.inkA28, blurRadius: 50, offset: Offset(0, 24))],
        ),
        child: Column(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: C.bg, shape: BoxShape.circle)),
          Container(width: 10, height: 16, color: C.bg),
          const SizedBox(height: Sp.lg),
          Text('Shh…', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: -1)),
          const SizedBox(height: Sp.sm),
          Text('Resting till\n5:00 PM',
              textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, color: C.muted2, height: 1.4)),
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
  final _shake = GlobalKey<ShakeState>();
  String? _err;
  bool _bad = false;
  int _tries = 3;

  bool _verifying = false;

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _ctrls.map((c) => c.text).join();
    if (_tries == 0) {
      setState(() => _err = 'Too many wrong tries. Tap Resend to get a new OTP.');
      _shake.currentState?.shake();
      return;
    }
    if (code.length < 4) {
      setState(() {
        _err = 'Enter all 4 digits';
        _bad = true;
      });
      _shake.currentState?.shake();
      return;
    }
    setState(() => _verifying = true);
    ApiError? fail;
    var isNew = true;
    try {
      // Demo: the fake backend accepts 1234 until a real WhatsApp/SMS service is connected.
      isNew = await api.verifyOtp(app.phone, code);
    } on ApiError catch (e) {
      fail = e;
    }
    if (!mounted) return;
    setState(() => _verifying = false);
    if (fail != null && fail.code != 'wrong_otp') {
      setState(() => _err = fail!.message);
      _shake.currentState?.shake();
      return;
    }
    if (fail != null) {
      _tries--;
      setState(() {
        _bad = true;
        _err = _tries == 0 ? 'Wrong OTP. Tap Resend to get a new one.' : 'That OTP is wrong. $_tries ${_tries == 1 ? 'try' : 'tries'} left.';
      });
      _shake.currentState?.shake();
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      for (final c in _ctrls) {
        c.clear();
      }
      setState(() => _bad = false);
      if (_tries > 0) _nodes[0].requestFocus();
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, isNew ? '/profile-setup' : '/home', (_) => false);
  }

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
          const Text('Verify your number', style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w700)),
          const SizedBox(height: Sp.sm),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
            Text.rich(TextSpan(style: TextStyle(fontSize: Fs.md, color: C.muted), children: [
              const TextSpan(text: "We've sent an OTP on WhatsApp to "),
              TextSpan(text: '+91 $phone', style: TextStyle(color: C.ink, fontWeight: FontWeight.w700)),
            ])),
            TapLink('Edit number',
                onTap: () => Navigator.pop(context),
                style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ]),
          const SizedBox(height: Sp.lg),
          Shake(
            key: _shake,
            child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < Sp.xs ? Sp.lg : 0),
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      autofocus: i == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      // Keyboard OTP suggestions and paste put the whole code in one box; it's spread out below.
                      autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: Sp.lg),
                        filled: _bad,
                        fillColor: C.redSoft,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide(color: _bad ? C.red : P.border, width: 1.5)),
                        focusedBorder:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide(color: _bad ? C.red : C.ink, width: 1.5)),
                      ),
                      onChanged: (v) {
                        if (v.length > 1) {
                          // Pasted or autofilled: spread the digits from this box onwards.
                          final digits = v.split('');
                          var last = i;
                          for (var k = 0; k < digits.length && i + k < 4; k++) {
                            _ctrls[i + k].text = digits[k];
                            last = i + k;
                          }
                          _nodes[last].requestFocus();
                          _ctrls[last].selection = TextSelection.collapsed(offset: _ctrls[last].text.length);
                          setState(() {
                            if (_tries > 0) _err = null;
                          });
                          if (_ok) _verify();
                          return;
                        }
                        if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
                        if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                        setState(() {
                          if (_tries > 0) _err = null;
                        });
                        if (v.isNotEmpty && i == 3 && _ok) _verify();
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
          ),
          FieldError(_err),
          const SizedBox(height: Sp.lg),
          PillBtn('Verify & continue',
              kind: BtnKind.dark,
              height: 56,
              expand: true,
              loading: _verifying,
              onTap: _verify),
          const SizedBox(height: Sp.sm),
          Text('Demo OTP: 1234', style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
          const SizedBox(height: Sp.md),
          Row(children: [
            Expanded(child: Text("Didn't get the code?", style: TextStyle(fontSize: Fs.md, color: C.muted))),
            if (_secs > 0)
              Text('Resend in 0:${_secs.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600, color: P.hint))
            else
              TextButton.icon(
                onPressed: () {
                  _start();
                  setState(() {
                    _tries = 3;
                    _err = null;
                  });
                  toast(context, 'New OTP sent on WhatsApp');
                },
                icon: Icon(Icons.refresh_rounded, size: Ic.md, color: C.ink),
                label: Text('Resend OTP',
                    style: TextStyle(color: C.ink, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
              ),
          ]),
        ]),
      ]),
    );
  }
}
