import 'package:flutter/material.dart';

import '../coupons.dart';
import '../state.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

/// Coupon picker for the current booking. Applies the chosen code to [app].
Future<void> showCouponSheet(BuildContext context) async {
  final ctrl = TextEditingController();
  String? error;
  final shake = GlobalKey<ShakeState>();
  final applied = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      void tryCode(String raw) {
        final code = raw.trim().toUpperCase();
        if (code.isEmpty) {
          set(() => error = 'Enter a coupon code');
          shake.currentState?.shake();
          return;
        }
        final c = couponByCode(code);
        if (c == null) {
          set(() => error = 'That code isn\'t valid. Check it and try again.');
          shake.currentState?.shake();
          return;
        }
        final p = couponProblem(c.code);
        if (p != null) {
          set(() => error = '${c.code}: $p');
          shake.currentState?.shake();
          return;
        }
        Navigator.pop(ctx, c.code);
      }

      final ok = allCoupons.where((c) => couponProblem(c.code) == null).toList()
        ..sort((a, b) => (couponDiscount(b.code) + couponCashback(b.code)).compareTo(couponDiscount(a.code) + couponCashback(a.code)));
      final notOk = allCoupons.where((c) => couponProblem(c.code) != null).toList();
      final best = ok.isEmpty ? null : ok.first.code;

      Widget ticket(CouponDef c, {String? problem}) {
        final dim = problem != null;
        final on = app.couponCode == c.code;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: dim ? C.tint(Color(0xFFF5F5F0)) : C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: on ? C.ink : C.border, width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: dim ? C.tint(Color(0xFFE8E8E0)) : C.limeBg,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Column(children: [
                Icon(c.code == 'BACK8' ? Icons.savings_outlined : Icons.local_offer_outlined, size: 22, color: dim ? C.muted2 : C.ink),
                const SizedBox(height: 4),
                Text(c.code, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: dim ? C.muted2 : C.ink)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(c.title,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: dim ? C.muted : C.ink)),
                    ),
                    if (!dim && c.code == best) ...[
                      const SizedBox(width: 6),
                      Tag('Best', bg: C.inkBg, fg: C.lime),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(c.desc, style: TextStyle(fontSize: 12, color: C.muted, height: 1.35)),
                  const SizedBox(height: 4),
                  Text(dim ? problem : couponSaving(c.code),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: dim ? C.red : C.green)),
                ]),
              ),
            ),
            if (!dim)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PillBtn(on ? 'Applied' : 'Apply',
                    kind: on ? BtnKind.soft : BtnKind.dark, height: 36, fontSize: 13, onTap: on ? null : () => Navigator.pop(ctx, c.code)),
              ),
          ]),
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(children: [
                const Expanded(child: Text('Apply coupon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                CircleBtn(icon: Icons.close_rounded, size: 38, bg: C.card, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(ctx)),
              ]),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
                Shake(key: shake, child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: error != null ? C.red : C.border, width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => set(() => error = null),
                        onSubmitted: tryCode,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        decoration: const InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, letterSpacing: 0, color: Color(0xFF8A8A82)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    PillBtn('Apply', kind: BtnKind.dark, height: 40, fontSize: 13.5, onTap: () => tryCode(ctrl.text)),
                  ]),
                )),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Text(error!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.red)),
                  ),
                Loader<void>(
                  load: api.offers,
                  skeleton: const SkCards(count: 3, height: 110),
                  builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionLabel('Available for this stay'),
                if (ok.isEmpty) Text('No coupons apply to this booking right now.', style: TextStyle(color: C.muted)),
                for (final c in ok) ticket(c),
                if (notOk.isNotEmpty) ...[
                  const SectionLabel('Not available for this stay'),
                  for (final c in notOk) ticket(c, problem: couponProblem(c.code)),
                ],
                  ]),
                ),
                const SizedBox(height: 4),
                Text('One coupon per booking.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted2)),
              ]),
            ),
          ]),
        ),
      );
    }),
  );
  ctrl.dispose();
  if (applied == null) return;
  app.set(() => app.couponCode = applied);
  if (context.mounted) toast(context, '$applied applied · ${couponSaving(applied)}');
}
