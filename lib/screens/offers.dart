import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _Coupon {
  final String code, big, unit, title, desc;
  final Color stub, stubFg;
  const _Coupon(this.code, this.big, this.unit, this.title, this.desc, this.stub, this.stubFg);
}

List<_Coupon> get _coupons => [
  _Coupon('NEWSTAY', '25%', 'OFF', '25% off your first stay', 'Up to ₹200 off on any hourly booking.', C.limeBg, C.ink),
  _Coupon('BACK8', '8%', 'BACK', '8% back as credits', 'On your next booking. Credits added after checkout.', C.inkBg, C.lime),
  _Coupon('NIGHT150', '₹150', 'OFF', '₹150 off full-day stays', 'On full-day bookings above ₹1,500.', C.tint(const Color(0xFFFFF1C7)), C.ink),
];

class _OffersScreenState extends State<OffersScreen> {
  final _code = TextEditingController();
  bool? _valid;
  final _shake = GlobalKey<ShakeState>();
  bool _checking = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    toast(context, '$code copied');
  }

  Widget _coupon(_Coupon c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: C.card,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 88,
                color: c.stub,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(c.big, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: c.stubFg, height: 1)),
                  const SizedBox(height: 3),
                  Text(c.unit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: c.stubFg)),
                ]),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: C.border, width: 2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(c.desc, style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: C.ink, width: 1.5)),
                        child: Text(c.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                      const Spacer(),
                      PillBtn('Copy code', kind: BtnKind.dark, height: 34, fontSize: 12.5, onTap: () => _copy(c.code)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _code.text.trim().toUpperCase();
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const BottomNav(current: 'Offers'),
      body: Loader<void>(
        load: api.offers,
        cacheKey: 'offers',
        skeleton: const SkPage(title: 'Offers', child: SkCards(count: 3, height: 120)),
        builder: (context, _) => ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 120), children: [
        const Align(alignment: Alignment.centerLeft, child: BackBtn()),
        const SizedBox(height: 14),
        const Text('Offers', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
        Text('Save more on every stay', style: TextStyle(fontSize: 13.5, color: C.muted)),
        const SizedBox(height: 18),
        WhiteCard(
          color: C.inkBg,
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CHECKDIN CREDITS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: C.faint)),
                SizedBox(height: 6),
                Text('₹120', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: C.lime, height: 1)),
                SizedBox(height: 6),
                Text('Used automatically at checkout', style: TextStyle(fontSize: 12.5, color: C.faint)),
              ]),
            ),
            PillBtn('History', height: 38, fontSize: 13, onTap: () => Navigator.pushNamed(context, '/credits')),
          ]),
        ),
        const SizedBox(height: 14),
        Shake(key: _shake, child: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _valid == null ? C.white : (_valid! ? C.green : C.red), width: 1.5),
          ),
          child: Row(children: [
            const Icon(Icons.percent_rounded, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _valid = null),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Have a code? Enter it here'),
              ),
            ),
            PillBtn('Apply',
                kind: BtnKind.dark,
                height: 44,
                fontSize: 14,
                loading: _checking,
                onTap: () async {
                  if (code.isNotEmpty) {
                    setState(() => _checking = true);
                    try {
                      await api.checkCoupon(code);
                    } on ApiError catch (e) {
                      if (mounted) toast(context, e.message);
                    }
                    if (!mounted) return;
                    setState(() => _checking = false);
                  }
                  setState(() => _valid = code.isNotEmpty && _coupons.any((c) => c.code == code));
                  if (_valid!) {
                    app.set(() => app.couponCode = code);
                  } else {
                    _shake.currentState?.shake();
                  }
                }),
          ]),
        )),
        if (_valid != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(_valid! ? '$code saved. It will apply at checkout.' : "That code isn't valid. Check and try again.",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _valid! ? C.green : C.red)),
          ),
        const SizedBox(height: 28),
        const Text('Coupons for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 12),
        ..._coupons.map(_coupon),
        const SizedBox(height: 16),
        const Text('Refer & earn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 12),
        WhiteCard(
          color: C.tint(Color(0xFFFFF1C7)),
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              IconTile(Icons.card_giftcard_rounded, bg: C.card, size: 46, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Give ₹100, get ₹100', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('When a friend books their first stay', style: TextStyle(fontSize: 12.5, color: C.tx(Color(0xFF4A4030)))),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Expanded(child: Text('ASHW100', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
                    PillBtn('Copy', kind: BtnKind.soft, height: 34, fontSize: 12, onTap: () => _copy('ASHW100')),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              PillBtn('Invite', kind: BtnKind.dark, height: 46, fontSize: 14, icon: Icons.share_outlined, trailingIcon: false, onTap: () => Navigator.pushNamed(context, '/refer')),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Text('One coupon per booking. Offers may change.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted2)),
      ]),
      ),
    );
  }
}
