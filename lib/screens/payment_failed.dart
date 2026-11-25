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

  Future<void> _cancel() async {
    final yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        decoration: const BoxDecoration(color: C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cancel this booking?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('We\'ll release your room at ${app.hotel.name}. No money has been charged.',
              style: const TextStyle(fontSize: 14, color: C.muted, height: 1.45)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: PillBtn('Keep booking', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Yes, cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.white)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
    if (yes == true && mounted) {
      app.set(() => app.coupon = null);
      toast(context, 'Booking cancelled. No money was charged.');
      goHome(context);
    }
  }

  Widget _row(String k, String v, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Text(k, style: const TextStyle(fontSize: 13.5, color: C.muted)),
          const Spacer(),
          Text(v, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
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
                    decoration: const BoxDecoration(color: C.redSoft, shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: C.white, size: 32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Payment failed',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                const SizedBox(height: 8),
                Text('${inr(app.total)} was not charged. Your bank didn\'t confirm the payment in time.',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, color: C.muted, height: 1.45)),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: expired ? C.redSoft : C.limeSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(children: [
                    Icon(expired ? Icons.timer_off_outlined : Icons.timer_outlined, size: 22, color: expired ? C.red : C.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expired ? 'Your room hold has ended. Retry to check if it\'s still free.' : 'We\'re holding your room for',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!expired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(999)),
                        child: Text(_clock, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.lime)),
                      ),
                  ]),
                ),
                const SectionLabel('Attempt details'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(children: [
                    _row('Hotel', app.hotel.name),
                    _row('Stay', '${app.whenShort} · ${app.stayLabel}'),
                    _row('Amount', inr(app.total)),
                    _row('Paid with', _method),
                    _row('Reference', _ref, last: true),
                  ]),
                ),
                const SizedBox(height: 14),
                WhiteCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: C.muted),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If money left your account, it will be refunded automatically in 5–7 working days. You don\'t need to do anything.',
                        style: TextStyle(fontSize: 13, color: C.muted, height: 1.45),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/help'),
                    child: const Text('Money deducted? Get help',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
          BottomBar(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PillBtn('Retry payment',
                  kind: BtnKind.dark, height: 56, expand: true, icon: Icons.refresh_rounded, trailingIcon: false, onTap: () => Navigator.pop(context, 'retry')),
              const SizedBox(height: 10),
              PillBtn('Cancel booking', kind: BtnKind.outline, height: 50, expand: true, onTap: _cancel),
            ]),
          ),
        ]),
      ),
    );
  }
}
