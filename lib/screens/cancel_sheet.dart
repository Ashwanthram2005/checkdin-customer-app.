import 'package:flutter/material.dart';

import '../state.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

/// Cancel an upcoming booking: shows the refund, asks for a reason, confirms.
/// Returns true when the booking was cancelled (and marks it in [app]).
Future<bool> showCancelBookingSheet(BuildContext context) async {
  const reasons = [
    'My plans changed',
    'Found a better price elsewhere',
    'Booked the wrong date or time',
    'Want a different hotel',
    'Booked by mistake',
    'Other reason',
  ];

  final now = DateTime.now();
  final checkIn = checkInTime();
  final left = checkIn.difference(now);
  final started = !left.isNegative ? false : true;
  final pct = refundPercent(left);
  final refund = (app.total * pct / 100).round();
  String fmt(DateTime t) => '${hourLabel(t.hour)}, ${dateLabel(t)}';
  final nextStep = left > const Duration(hours: 5)
      ? 'Cancel before ${fmt(checkIn.subtract(const Duration(hours: 5)))} to keep 50% back.'
      : left > const Duration(hours: 3)
          ? 'Cancel before ${fmt(checkIn.subtract(const Duration(hours: 3)))} to keep 25% back.'
          : 'Cancellations less than 3 hours before check-in get no refund.';

  String? picked;
  final other = TextEditingController();
  final shake = GlobalKey<ShakeState>();
  var tried = false;
  var cancelling = false;
  // One key for this cancel sheet: repeats of the same request cancel once.
  final cancelKey = newIdempotencyKey();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      final isOther = picked == 'Other reason';
      final ready = !started && picked != null && (!isOther || other.text.trim().isNotEmpty);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs)))),
              const SizedBox(height: Sp.lg),
              const Text('Cancel booking?', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
              const SizedBox(height: Sp.xs),
              Text('${app.hotel.name} · ${app.whenShort}', style: TextStyle(fontSize: Fs.base, color: C.muted)),
              const SizedBox(height: Sp.lg),
              // refund preview
              Container(
                padding: const EdgeInsets.all(Sp.lg),
                decoration: BoxDecoration(color: refund > 0 ? C.limeSoft : C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
                child: Row(children: [
                  Icon(refund > 0 ? Icons.account_balance_wallet_rounded : Icons.info_outline_rounded, color: refund > 0 ? C.ink : C.red),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(refund > 0 ? 'You\'ll get ${inr(refund)} back ($pct%)' : 'No refund for this booking',
                          style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      const SizedBox(height: Sp.xxs),
                      Text(
                          refund > 0 ? '$nextStep Approved refunds reach you in 3–5 working days.' : nextStep,
                          style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
                    ]),
                  ),
                ]),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx, false);
                  Navigator.pushNamed(context, '/cancel-policy');
                },
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: Sp.lg),
                  child: Text('View cancellation policy',
                      style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              ),
              if (started)
                Container(
                  margin: const EdgeInsets.only(top: Sp.md),
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
                  child: Text('Your slot has started, so this booking can no longer be cancelled in the app. Tap Get help in Help for support.',
                      style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, color: C.tx(P.redDark), height: 1.4)),
                ),
              const SizedBox(height: Sp.lg),
              const Text('Why are you cancelling?', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
              const SizedBox(height: Sp.md),
              Shake(key: shake, child: Column(children: [
              for (final r in reasons)
                GestureDetector(
                  onTap: () => setSheet(() => picked = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: Sp.sm),
                    padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
                    decoration: BoxDecoration(
                      color: picked == r ? C.limeSoft : C.card,
                      borderRadius: BorderRadius.circular(R.lg),
                      border: Border.all(color: picked == r ? C.ink : C.border, width: 1.5),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(r, style: TextStyle(fontSize: Fs.md, fontWeight: picked == r ? FontWeight.w700 : FontWeight.w600))),
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
                TextField(
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
              ])),
              FieldError(tried && !started && !ready ? (picked == null ? 'Pick a reason to continue' : 'Tell us the reason in a few words') : null),
              const SizedBox(height: Sp.md),
              Row(children: [
                Expanded(child: PillBtn('Keep booking', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pop(ctx, false))),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: GestureDetector(
                    onTap: ready
                        ? () async {
                            if (cancelling) return;
                            setSheet(() => cancelling = true);
                            try {
                              await api.cancelBooking(app.bookingId, isOther ? other.text.trim() : picked!, idempotencyKey: cancelKey);
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } on ApiError catch (e) {
                              setSheet(() => cancelling = false);
                              if (ctx.mounted) toast(ctx, e.message);
                            }
                          }
                        : started
                            ? null
                            : () {
                                setSheet(() => tried = true);
                                shake.currentState?.shake();
                              },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: ready ? C.red : C.tint(P.line), borderRadius: BorderRadius.circular(R.pill)),
                      child: cancelling
                          ? Spinner(color: C.white)
                          : Text('Cancel booking',
                              style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: ready ? C.white : C.muted2)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      );
    }),
  );
  // Wait for the sheet's close animation before freeing the text box.
  Future<void>.delayed(const Duration(milliseconds: 600), other.dispose);
  if (ok != true) return false;
  app.set(() {
    app.bookingCancelled = true;
    app.cancelRefund = refund;
  });
  if (context.mounted) {
    toast(context, refund > 0 ? 'Booking cancelled. ${inr(refund)} refund requested.' : 'Booking cancelled.');
  }
  return true;
}

/// Scheduled check-in of the current booking.
DateTime checkInTime() {
  final d = app.fullDay ? app.inDate : app.date;
  return DateTime(d.year, d.month, d.day, app.fullDay ? 12 : app.checkInHour % 24);
}

/// Refund % from the Cancellation & Refund Policy: 50% more than 5 hrs before, 25% between 5 and 3 hrs, else none.
int refundPercent(Duration beforeCheckIn) {
  if (beforeCheckIn > const Duration(hours: 5)) return 50;
  if (beforeCheckIn >= const Duration(hours: 3)) return 25;
  return 0;
}
