import 'dart:async';

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

/// Arguments: {'method': String, 'left': int (seconds the room stays on hold)}.
/// Pops with 'retry' when the user wants to pay again.
class PaymentFailedScreen extends StatefulWidget {
  const PaymentFailedScreen({super.key});
  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  String _method = 'Net banking';
  int _left = 600;
  bool _argsRead = false;
  Timer? _t;
  late final String _ref = 'TXN${DateTime.now().millisecondsSinceEpoch % 100000000}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final a = ModalRoute.of(context)?.settings.arguments;
    if (a is Map) {
      _method = (a['method'] as String?) ?? _method;
      _left = (a['left'] as int?) ?? _left;
    }
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _left > 0) setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String get _clock => '${(_left ~/ 60).toString().padLeft(2, '0')}:${(_left % 60).toString().padLeft(2, '0')}';

  static const _methods = [
    ['anyupi', Icons.phone_android_rounded, 'Any UPI app', 'GPay, PhonePe, Paytm & more'],
    ['card', Icons.credit_card_rounded, 'Credit / Debit card', 'Visa •••• 4417'],
    ['netbank', Icons.account_balance_rounded, 'Net banking', 'All major Indian banks'],
  ];

  Future<void> _retry() async {
    var sel = _method == 'Net banking' ? 'anyupi' : 'card';
    final go = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs)))),
            const SizedBox(height: Sp.lg),
            const Text('Choose how to pay', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.xs),
            Text('Last try with $_method didn\'t go through.', style: TextStyle(fontSize: Fs.base, color: C.muted)),
            const SizedBox(height: Sp.lg),
            for (final m in _methods)
              GestureDetector(
                onTap: () => setSheet(() => sel = m[0] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: Sp.sm),
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(
                    color: sel == m[0] ? C.limeSoft : C.card,
                    borderRadius: BorderRadius.circular(R.lg),
                    border: Border.all(color: sel == m[0] ? C.ink : C.border, width: 1.5),
                  ),
                  child: Row(children: [
                    IconTile(m[1] as IconData, bg: sel == m[0] ? C.limeBg : C.bg, size: 40),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(m[2] as String, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                          if (m[2] == _method) ...[
                            const SizedBox(width: Sp.sm),
                            Tag('Failed', bg: C.redSoft, fg: C.red),
                          ],
                        ]),
                        Text(m[3] as String, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                      ]),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel == m[0] ? C.inkBg : C.card,
                        border: Border.all(color: sel == m[0] ? C.ink : C.border, width: 2),
                      ),
                      child: sel == m[0]
                          ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle)))
                          : null,
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: Sp.sm),
            PillBtn('Pay ${inr(app.total)}',
                kind: BtnKind.dark, height: 56, expand: true, icon: Icons.lock_outline_rounded, trailingIcon: false, onTap: () => Navigator.pop(ctx, sel)),
          ]),
        ),
      ),
    );
    if (go == null || !mounted) return;
    _t?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: P.inkA60,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xxl, Sp.xl, Sp.xxl),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3.5, color: C.ink, backgroundColor: C.limeSoft)),
                SizedBox(height: Sp.lg),
                Text('Confirming payment…', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                SizedBox(height: Sp.xs),
                Text('Don\'t press back or close the app',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pop();
    app.set(() {
      app.bookingCancelled = false;
      app.checkedIn = false;
      app.bookingId = newBookingId(DateTime.now());
      app.stayStart = null;
      app.extraHours = 0;
      app.extraPaid = 0;
    });
    Navigator.pushNamedAndRemoveUntil(context, '/success', ModalRoute.withName('/home'));
  }

  static const _reasons = [
    'Payment keeps failing',
    'Found a better price elsewhere',
    'My plans changed',
    'Booked the wrong date or time',
    'Want a different hotel',
    'Other reason',
  ];

  Future<void> _cancel() async {
    String? picked;
    final other = TextEditingController();
    final yes = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final isOther = picked == 'Other reason';
          final ok = picked != null && (!isOther || other.text.trim().isNotEmpty);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs))),
                  ),
                  const SizedBox(height: Sp.lg),
                  const Text('Why are you cancelling?', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Sp.xs),
                  Text('Your room at ${app.hotel.name} will be released. No money has been charged.',
                      style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.45)),
                  const SizedBox(height: Sp.lg),
                  for (final r in _reasons)
                    GestureDetector(
                      onTap: () => setSheet(() => picked = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: Sp.sm),
                        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: 13),
                        decoration: BoxDecoration(
                          color: picked == r ? C.limeSoft : C.card,
                          borderRadius: BorderRadius.circular(R.lg),
                          border: Border.all(color: picked == r ? C.ink : C.border, width: 1.5),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(r, style: TextStyle(fontSize: Fs.md, fontWeight: picked == r ? FontWeight.w700 : FontWeight.w600)),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: picked == r ? C.inkBg : C.card,
                              border: Border.all(color: picked == r ? C.ink : C.border, width: 2),
                            ),
                            child: picked == r
                                ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle)))
                                : null,
                          ),
                        ]),
                      ),
                    ),
                  if (isOther)
                    Padding(
                      padding: const EdgeInsets.only(top: Sp.xxs),
                      child: TextField(
                        controller: other,
                        autofocus: true,
                        maxLength: 100,
                        maxLines: 2,
                        minLines: 2,
                        onChanged: (_) => setSheet(() {}),
                        style: const TextStyle(fontSize: Fs.md),
                        decoration: InputDecoration(
                          hintText: 'Tell us in a few words',
                          hintStyle: const TextStyle(color: P.hint),
                          filled: true,
                          fillColor: C.bg,
                          contentPadding: const EdgeInsets.all(Sp.lg),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  const SizedBox(height: Sp.md),
                  Row(children: [
                    Expanded(child: PillBtn('Keep booking', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pop(ctx, false))),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: ok ? () => Navigator.pop(ctx, true) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: ok ? C.red : C.tint(P.line), borderRadius: BorderRadius.circular(R.pill)),
                          child: Text('Cancel booking',
                              style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: ok ? C.white : C.muted2)),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          );
        },
      ),
    );
    // Wait for the sheet's close animation before freeing the text box.
  Future<void>.delayed(const Duration(milliseconds: 600), other.dispose);
    if (yes == true && mounted) {
      toast(context, 'Booking cancelled. No money was charged.');
      goHome(context);
    }
  }

  Widget _row(String k, String v, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Text(k, style: TextStyle(fontSize: Fs.base, color: C.muted)),
          const Spacer(),
          Text(v, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final expired = _left == 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, 'retry');
      },
      child: Scaffold(
        body: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 36, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: C.redSoft, shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: C.red, shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded, color: C.white, size: Ic.xl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.lg),
                const Text('Payment failed',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                const SizedBox(height: Sp.sm),
                Text('${inr(app.total)} was not charged. Your bank didn\'t confirm the payment in time.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.45)),
                const SizedBox(height: Sp.xxl),
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(
                    color: expired ? C.redSoft : C.limeSoft,
                    borderRadius: BorderRadius.circular(R.lg),
                  ),
                  child: Row(children: [
                    Icon(expired ? Icons.timer_off_rounded : Icons.timer_rounded, size: Ic.md, color: expired ? C.red : C.ink),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text(
                        expired ? 'Your room hold has ended. Retry to check if it\'s still free.' : 'We\'re holding your room for',
                        style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!expired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
                        decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.pill)),
                        child: Text(_clock, style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.lime)),
                      ),
                  ]),
                ),
                const SectionLabel('Attempt details'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
                  child: Column(children: [
                    _row('Hotel', app.hotel.name),
                    _row('Stay', '${app.whenShort} · ${app.stayLabel}'),
                    _row('Amount', inr(app.total)),
                    _row('Paid with', _method),
                    _row('Reference', _ref, last: true),
                  ]),
                ),
                const SizedBox(height: Sp.lg),
                WhiteCard(
                  radius: R.lg,
                  padding: const EdgeInsets.all(Sp.lg),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: Ic.md, color: C.muted),
                    SizedBox(width: Sp.md),
                    Expanded(
                      child: Text(
                        'If money left your account, it will be refunded automatically in 5–7 working days. You don\'t need to do anything.',
                        style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.45),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: Sp.lg),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/help'),
                    child: const Text('Money deducted? Get help',
                        style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
          BottomBar(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PillBtn('Retry payment',
                  kind: BtnKind.dark, height: 56, expand: true, icon: Icons.refresh_rounded, trailingIcon: false, onTap: _retry),
              const SizedBox(height: Sp.md),
              PillBtn('Cancel booking', kind: BtnKind.outline, height: 50, expand: true, onTap: _cancel),
            ]),
          ),
        ]),
      ),
    );
  }
}
