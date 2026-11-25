import 'dart:async';

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import 'hotel_detail.dart' show billRow, totalBox;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _sel = 'anyupi';
  int _left = 600;
  Timer? _t;
  final _vpa = TextEditingController();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _left > 0) setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _vpa.dispose();
    super.dispose();
  }

  Widget _row(String id, IconData icon, String title, String sub, {String? badge, bool last = false}) {
    final on = _sel == id;
    return Material(
      color: on ? C.bg : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _sel = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            IconTile(icon, bg: on ? C.lime : C.bg, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(6)),
                      child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.lime, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 12.5, color: C.muted)),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: C.white,
                shape: BoxShape.circle,
                border: Border.all(color: on ? C.ink : const Color(0xFF9A9A92), width: on ? 7 : 2),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 20), children: [
            Row(children: [
              const BackBtn(),
              const SizedBox(width: 12),
              const Expanded(child: Text('Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text('Room held · $mm:$ss', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(22)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('YOU PAY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: C.faint)),
                        const SizedBox(height: 6),
                        Text(inr(app.total), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: -1.5, height: 1)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.stayLabel}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.white)),
                      const SizedBox(height: 3),
                      Text(app.whenShort,
                          style: const TextStyle(fontSize: 13, color: C.faint)),
                    ]),
                  ]),
                ),
                Row(children: [
                  Container(width: 10, height: 20, decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.horizontal(right: Radius.circular(10)))),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate((c.maxWidth / 10).floor(), (_) => Container(width: 5, height: 2, color: const Color(0xFF3A3A3A))),
                      ),
                    ),
                  ),
                  Container(width: 10, height: 20, decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.horizontal(left: Radius.circular(10)))),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(children: [
                    const Expanded(child: Text('Inclusive of all taxes', style: TextStyle(fontSize: 13, color: C.faint))),
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: C.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Align(alignment: Alignment.centerLeft, child: Text('Price details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            const SizedBox(height: 16),
                            billRow('Room price', inr(app.gross - app.fees)),
                            const SizedBox(height: 12),
                            billRow('Taxes & fees', inr(app.fees)),
                            if (app.coupon) ...[const SizedBox(height: 12), billRow('Coupon FIRST40', '−₹40', vColor: C.green)],
                            const SizedBox(height: 14),
                            totalBox(inr(app.total)),
                          ]),
                        ),
                      ),
                      child: const Row(children: [
                        Text('Price details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.white)),
                        Icon(Icons.chevron_right_rounded, size: 16, color: C.white),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SectionLabel('Pay with UPI'),
            WhiteCard(
              radius: 20,
              padding: const EdgeInsets.all(5),
              child: Column(children: [
                _row('anyupi', Icons.phone_android_rounded, 'Any UPI app', 'GPay, PhonePe, Paytm & more', badge: 'FASTEST'),
                _row('upiid', Icons.alternate_email_rounded, 'Enter UPI ID', 'Pay using your UPI address'),
                if (_sel == 'upiid')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 4, 12, 12),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _vpa,
                          decoration: InputDecoration(
                            hintText: 'yourname@okbank',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PillBtn('Verify', kind: BtnKind.dark, height: 46, fontSize: 14, onTap: () => toast(context, 'UPI ID verified')),
                    ]),
                  ),
              ]),
            ),
            const SectionLabel('More ways to pay'),
            WhiteCard(
              radius: 20,
              padding: const EdgeInsets.all(5),
              child: Column(children: [
                _row('card', Icons.credit_card_rounded, 'Credit / Debit card', 'Visa, Mastercard, RuPay'),
                _row('netbank', Icons.account_balance_outlined, 'Net banking', 'All major Indian banks'),
              ]),
            ),
          ]),
        ),
        BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: C.muted),
              SizedBox(width: 6),
              Text('Secure, encrypted payments', style: TextStyle(fontSize: 12, color: C.muted)),
            ]),
            const SizedBox(height: 10),
            PillBtn('Pay ${inr(app.total)}',
                kind: BtnKind.dark,
                height: 56,
                expand: true,
                icon: Icons.arrow_forward_rounded,
                onTap: _left == 0 ? null : () => Navigator.pushNamedAndRemoveUntil(context, '/success', ModalRoute.withName('/home'))),
          ]),
        ),
      ]),
    );
  }
}
