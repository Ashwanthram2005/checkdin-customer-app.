import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

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
  final d = app.fullDay ? app.inDate : app.date;
  final checkIn = DateTime(d.year, d.month, d.day, app.fullDay ? 12 : app.checkInHour % 24);
  final freeTill = checkIn.subtract(Duration(hours: app.fullDay ? 24 : 2));
  final free = now.isBefore(freeTill);
  final refund = free ? app.total : 0;
  String fmt(DateTime t) => '${hourLabel(t.hour)}, ${dateLabel(t)}';

  String? picked;
  final other = TextEditingController();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      final isOther = picked == 'Other reason';
      final ready = picked != null && (!isOther || other.text.trim().isNotEmpty);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          decoration: const BoxDecoration(color: C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Cancel booking?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${app.hotel.name} · ${app.whenShort}', style: const TextStyle(fontSize: 13.5, color: C.muted)),
              const SizedBox(height: 14),
              // refund preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: free ? C.limeSoft : C.redSoft, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Icon(free ? Icons.account_balance_wallet_outlined : Icons.info_outline_rounded, color: free ? C.ink : C.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(free ? 'You\'ll get ${inr(refund)} back' : 'No refund for this booking',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                          free
                              ? 'Free cancellation till ${fmt(freeTill)}. Refund to your UPI in 5–7 working days.'
                              : 'Free cancellation ended at ${fmt(freeTill)}.',
                          style: const TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
                    ]),
                  ),
                ]),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx, false);
                  Navigator.pushNamed(context, '/cancel-policy');
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('View cancellation policy',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Why are you cancelling?', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (final r in reasons)
                GestureDetector(
                  onTap: () => setSheet(() => picked = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: picked == r ? C.limeSoft : C.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: picked == r ? C.ink : C.border, width: 1.5),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(r, style: TextStyle(fontSize: 14.5, fontWeight: picked == r ? FontWeight.w800 : FontWeight.w600))),
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
                TextField(
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
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: PillBtn('Keep booking', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pop(ctx, false))),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: ready ? () => Navigator.pop(ctx, true) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: ready ? C.red : const Color(0xFFEFEFEA), borderRadius: BorderRadius.circular(999)),
                      child: Text('Cancel booking',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ready ? C.white : C.muted2)),
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
  other.dispose();
  if (ok != true) return false;
  app.set(() {
    app.bookingCancelled = true;
    app.cancelRefund = refund;
  });
  if (context.mounted) {
    toast(context, refund > 0 ? 'Booking cancelled. ${inr(refund)} refund started.' : 'Booking cancelled.');
  }
  return true;
}
