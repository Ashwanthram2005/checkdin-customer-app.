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
              decoration: const BoxDecoration(color: C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Why are you cancelling?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Your room at ${app.hotel.name} will be released. No money has been charged.',
                      style: const TextStyle(fontSize: 13.5, color: C.muted, height: 1.45)),
                  const SizedBox(height: 14),
                  for (final r in _reasons)
                    GestureDetector(
                      onTap: () => setSheet(() => picked = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: picked == r ? C.limeSoft : C.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: picked == r ? C.ink : C.border, width: 1.5),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(r, style: TextStyle(fontSize: 14.5, fontWeight: picked == r ? FontWeight.w800 : FontWeight.w600)),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: picked == r ? C.ink : C.white,
                              border: Border.all(color: picked == r ? C.ink : C.border, width: 2),
                            ),
                            child: picked == r
                                ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle)))
                                : null,
                          ),
                        ]),
                      ),
                    ),
                  if (isOther)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: TextField(
                        controller: other,
                        autofocus: true,
                        maxLength: 100,
                        maxLines: 2,
                        minLines: 2,
                        onChanged: (_) => setSheet(() {}),
                        style: const TextStyle(fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: 'Tell us in a few words',
                          hintStyle: const TextStyle(color: Color(0xFF8A8A82)),
                          filled: true,
                          fillColor: C.bg,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: PillBtn('Keep booking', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pop(ctx, false))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: ok ? () => Navigator.pop(ctx, true) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: ok ? C.red : const Color(0xFFEFEFEA), borderRadius: BorderRadius.circular(999)),
                          child: Text('Cancel booking',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ok ? C.white : C.muted2)),
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
    other.dispose();
    if (yes == true && mounted) {
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
