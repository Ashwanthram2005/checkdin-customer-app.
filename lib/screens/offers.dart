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
  _Coupon('NIGHT150', '₹150', 'OFF', '₹150 off full-day stays', 'On full-day bookings above ₹1,500.', C.tint(P.amberSoft), C.ink),
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
      padding: const EdgeInsets.only(bottom: Sp.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.xl),
        child: Container(
          color: C.card,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 88,
                color: c.stub,
                padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(c.big, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: c.stubFg, height: 1)),
                  const SizedBox(height: Sp.xs),
                  Text(c.unit, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: c.stubFg)),
                ]),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.lg),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: C.border, width: 2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.xs),
                    Text(c.desc, style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
                    const SizedBox(height: Sp.md),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(R.sm), border: Border.all(color: C.ink, width: 1.5)),
                        child: Text(c.code, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                      const Spacer(),
                      Flexible(flex: 3, child: PillBtn('Copy code', kind: BtnKind.dark, height: 34, fontSize: Fs.sm, onTap: () => _copy(c.code))),
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
        const SizedBox(height: Sp.lg),
        const Text('Offers', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -1)),
        Text('Save more on every stay', style: TextStyle(fontSize: Fs.base, color: C.muted)),
        const SizedBox(height: Sp.lg),
        WhiteCard(
          color: C.inkBg,
          radius: R.xl,
          padding: const EdgeInsets.all(Sp.lg),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CHECKDIN CREDITS', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: C.faint)),
                SizedBox(height: Sp.sm),
                Text('₹120', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -1, color: C.lime, height: 1)),
                SizedBox(height: Sp.sm),
                Text('Used automatically at checkout', style: TextStyle(fontSize: Fs.sm, color: C.faint)),
              ]),
            ),
            PillBtn('History', height: 38, fontSize: Fs.base, onTap: () => Navigator.pushNamed(context, '/credits')),
          ]),
        ),
        const SizedBox(height: Sp.lg),
        Shake(key: _shake, child: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.sm, Sp.sm),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: _valid == null ? C.white : (_valid! ? C.green : C.red), width: 1.5),
          ),
          child: Row(children: [
            const Icon(Icons.percent_rounded, size: Ic.md),
            const SizedBox(width: Sp.md),
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _valid = null),
                style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Have a code? Enter it here'),
              ),
            ),
            PillBtn('Apply',
                kind: BtnKind.dark,
                height: 44,
                fontSize: Fs.md,
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
            padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.sm, Sp.xs, 0),
            child: Text(_valid! ? '$code saved. It will apply at checkout.' : "That code isn't valid. Check and try again.",
                style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: _valid! ? C.green : C.red)),
          ),
        const SizedBox(height: Sp.x3),
        const Text('Coupons for you', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: Sp.md),
        ..._coupons.map(_coupon),
        const SizedBox(height: Sp.lg),
        const Text('Refer & earn', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: Sp.md),
        WhiteCard(
          color: C.tint(P.amberSoft),
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(children: [
            Row(children: [
              IconTile(Icons.card_giftcard_rounded, bg: C.card, size: 46, radius: 14),
              SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Give ₹100, get ₹100', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                  SizedBox(height: Sp.xxs),
                  Text('When a friend books their first stay', style: TextStyle(fontSize: Fs.sm, color: C.tx(P.orange24))),
                ]),
              ),
            ]),
            const SizedBox(height: Sp.lg),
            Row(children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.sm, Sp.sm),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.lg)),
                  child: Row(children: [
                    const Expanded(child: Text('ASHW100', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                    PillBtn('Copy', kind: BtnKind.soft, height: 34, fontSize: Fs.sm, onTap: () => _copy('ASHW100')),
                  ]),
                ),
              ),
              const SizedBox(width: Sp.sm),
              PillBtn('Invite', kind: BtnKind.dark, height: 46, fontSize: Fs.md, icon: Icons.share_rounded, trailingIcon: false, onTap: () => Navigator.pushNamed(context, '/refer')),
            ]),
          ]),
        ),
        const SizedBox(height: Sp.lg),
        Text('One coupon per booking. Offers may change.', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
      ]),
      ),
    );
  }
}
