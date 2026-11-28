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
  var checking = false;
  final applied = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      Future<void> tryCode(String raw) async {
        final code = raw.trim().toUpperCase();
        if (checking) return;
        if (code.isEmpty) {
          set(() => error = 'Enter a coupon code');
          shake.currentState?.shake();
          return;
        }
        set(() => checking = true);
        try {
          await api.checkCoupon(code);
        } on ApiError catch (e) {
          set(() {
            checking = false;
            error = e.message;
          });
          shake.currentState?.shake();
          return;
        }
        set(() => checking = false);
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
          margin: const EdgeInsets.only(bottom: Sp.md),
          decoration: BoxDecoration(
            color: dim ? C.tint(P.grey95) : C.card,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: on ? C.ink : C.border, width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: Sp.lg),
              decoration: BoxDecoration(
                color: dim ? C.tint(P.grey89) : C.limeBg,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(R.lg)),
              ),
              child: Column(children: [
                Icon(c.code == 'BACK8' ? Icons.savings_rounded : Icons.local_offer_rounded, size: Ic.md, color: dim ? C.muted2 : C.ink),
                const SizedBox(height: Sp.xs),
                Text(c.code, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: dim ? C.muted2 : C.ink)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.sm, Sp.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(c.title,
                          style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: dim ? C.muted : C.ink)),
                    ),
                    if (!dim && c.code == best) ...[
                      const SizedBox(width: Sp.sm),
                      Tag('Best', bg: C.inkBg, fg: C.lime),
                    ],
                  ]),
                  const SizedBox(height: Sp.xxs),
                  Text(c.desc, style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.35)),
                  const SizedBox(height: Sp.xs),
                  Text(dim ? problem : couponSaving(c.code),
                      style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: dim ? C.red : C.green)),
                ]),
              ),
            ),
            if (!dim)
              Padding(
                padding: const EdgeInsets.only(right: Sp.md),
                child: PillBtn(on ? 'Applied' : 'Apply',
                    kind: on ? BtnKind.soft : BtnKind.dark, height: 36, fontSize: Fs.base, onTap: on ? null : () => Navigator.pop(ctx, c.code)),
              ),
          ]),
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: Sp.md),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs))),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.md, Sp.xs),
              child: Row(children: [
                const Expanded(child: Text('Apply coupon', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800))),
                CircleBtn(icon: Icons.close_rounded, size: 38, bg: C.card, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(ctx)),
              ]),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, Sp.xxl), children: [
                Shake(key: shake, child: Container(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.xs, Sp.sm, Sp.xs),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(R.lg),
                    border: Border.all(color: error != null ? C.red : C.border, width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => set(() => error = null),
                        onSubmitted: tryCode,
                        style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                        decoration: const InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w400, letterSpacing: 0, color: P.hint),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    PillBtn('Apply', kind: BtnKind.dark, height: 40, fontSize: Fs.base, loading: checking, onTap: () => tryCode(ctrl.text)),
                  ]),
                )),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.sm, Sp.xs, 0),
                    child: Text(error!, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.red)),
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
                const SizedBox(height: Sp.xs),
                Text('One coupon per booking.', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
              ]),
            ),
          ]),
        ),
      );
    }),
  );
  // Wait for the sheet's close animation before freeing the text box.
  Future<void>.delayed(const Duration(milliseconds: 600), ctrl.dispose);
  if (applied == null) return;
  app.set(() => app.couponCode = applied);
  if (context.mounted) toast(context, '$applied applied · ${couponSaving(applied)}');
}
