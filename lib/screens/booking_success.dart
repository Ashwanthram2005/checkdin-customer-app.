import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import '../voucher.dart';
import 'stay.dart';
import 'maps.dart';
import 'cancel_sheet.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final h = app.hotel;
    void home() => goHome(context);
    Widget action(IconData icon, String label, bool lime, VoidCallback onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
            child: WhiteCard(
              radius: R.lg,
              padding: const EdgeInsets.symmetric(vertical: Sp.md),
              onTap: onTap,
              child: Column(children: [
                IconTile(icon, bg: lime ? C.limeBg : C.bg, size: 38, radius: 19),
                const SizedBox(height: Sp.sm),
                Text(label, style: const TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        body: Column(children: [
          Expanded(
            child: ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24), children: [
              Align(alignment: Alignment.centerRight, child: CircleBtn(icon: Icons.close_rounded, tooltip: 'Close', onTap: home)),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 3)),
                  child: Icon(Icons.check_rounded, size: Ic.hero, color: C.ink),
                ),
              ),
              const SizedBox(height: Sp.lg),
              const Highlight(before: 'Booking ', marked: 'confirmed.', size: 30, align: TextAlign.center),
              const SizedBox(height: Sp.sm),
              Text("Your room is ready for you. We've sent the details to your WhatsApp.",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
              const SizedBox(height: Sp.lg),
              Center(
                child: Material(
                  color: C.card,
                  borderRadius: BorderRadius.circular(R.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(R.pill),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: app.bookingId));
                      toast(context, 'Booking ID copied');
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Booking ID ', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, color: C.muted)),
                        Flexible(child: Text(app.bookingId, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700))),
                        SizedBox(width: Sp.md),
                        Icon(Icons.copy_rounded, size: Ic.sm),
                        SizedBox(width: Sp.xs),
                        Text('Copy', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.xxl),
              WhiteCard(
                radius: R.xl,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.lg),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h.name, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                            Text('Deluxe Room · ${h.area}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                          ]),
                        ),
                        const Tag('Paid'),
                      ]),
                      const SizedBox(height: Sp.lg),
                      StayTimeline(
                        inTime: app.inTimeLabel,
                        outTime: app.outTimeLabel,
                        inDate: app.inDateLabel,
                        outDate: app.outDateLabel,
                        slot: app.stayLabel,
                      ),
                    ]),
                  ),
                  Divider(color: C.line, height: 1, indent: 18, endIndent: 18),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.lg),
                    child: Row(children: [
                      Expanded(
                          child: Text('${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.guestsLabel}',
                              style: TextStyle(fontSize: Fs.base, color: C.muted))),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Paid via ${app.paidWith} ', style: TextStyle(fontSize: Fs.base, color: C.muted)),
                        TextSpan(text: inr(app.total), style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                      ])),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/checkin'),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.md, Sp.lg),
                  decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.xl)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('CHECK-IN OTP', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: C.faint)),
                        const SizedBox(height: Sp.xs),
                        Row(children: [
                          for (final d in app.checkinOtp.split(''))
                            Container(
                              width: 38,
                              height: 46,
                              margin: const EdgeInsets.only(right: Sp.sm),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: P.grey16, borderRadius: BorderRadius.circular(R.md)),
                              child: Text(d, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, color: C.lime)),
                            ),
                        ]),
                        const SizedBox(height: Sp.sm),
                        Text('Show this at the front desk', style: TextStyle(fontSize: Fs.sm, color: C.faint)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: C.white),
                  ]),
                ),
              ),
              const SizedBox(height: Sp.md),
              WhiteCard(
                radius: R.xl,
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.md, Sp.md),
                onTap: () async {
                  await showExtendSheet(context);
                },
                child: Row(children: [
                  IconTile(Icons.more_time_rounded, bg: C.limeBg, size: 40),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.extraHours > 0 ? 'Extended by ${app.extraHours} hr${app.extraHours > 1 ? 's' : ''}' : 'Need more time?',
                          style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      Text(app.extraHours > 0 ? 'New check-out ${app.outTimeLabel} · add more' : 'Extend your stay now, before you check in',
                          style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                  PillBtn('Extend', kind: BtnKind.dark, height: 38, fontSize: Fs.base, onTap: () async {
                    await showExtendSheet(context);
                  }),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              Row(children: [
                action(Icons.near_me_rounded, 'Directions', true, () => openDirections(context, app.hotel)),
                action(Icons.call_rounded, 'Call hotel', false, () => callHotel(context)),
                action(Icons.event_rounded, 'Calendar', false, () => toast(context, 'Added to your calendar')),
                ValueListenableBuilder<bool>(
                  valueListenable: voucherBusy,
                  builder: (_, busy, __) => busy
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
                            child: WhiteCard(
                              radius: R.lg,
                              padding: const EdgeInsets.symmetric(vertical: Sp.md),
                              child: const Column(children: [
                                SizedBox(height: 38, child: Center(child: Spinner())),
                                SizedBox(height: Sp.sm),
                                Text('Voucher', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        )
                      : action(Icons.download_rounded, 'Voucher', false, () => shareVoucher(context)),
                ),
              ]),
              const SizedBox(height: Sp.md),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final done = await showCancelBookingSheet(context);
                    if (done && context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/bookings', ModalRoute.withName('/home'));
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: Sp.sm),
                    child: Text.rich(TextSpan(style: TextStyle(fontSize: Fs.base), children: [
                      TextSpan(text: 'Need to cancel? ', style: TextStyle(color: C.muted)),
                      TextSpan(text: 'Cancel booking', style: TextStyle(fontWeight: FontWeight.w800, color: C.red, decoration: TextDecoration.underline)),
                    ])),
                  ),
                ),
              ),
              const SizedBox(height: Sp.md),
              if (app.forSomeoneElse) ...[
                WhiteCard(
                  radius: R.xl,
                  child: Row(children: [
                    IconTile(Icons.person_outline_rounded, bg: C.limeSoft, size: 40, radius: 12),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Booked for ${app.stayGuestName}', style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                        const SizedBox(height: Sp.xxs),
                        Text(
                            app.notifyGuest
                                ? 'We\'ve sent the booking and check-in OTP to ${app.stayGuestPhone} on WhatsApp.'
                                : 'Share the Booking ID and check-in OTP with them before they arrive.',
                            style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: Sp.md),
              ],
              WhiteCard(
                color: C.tint(P.amber93),
                radius: R.xl,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconTile(Icons.badge_rounded, bg: C.card, size: 34, radius: 10),
                  SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Before you go', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      SizedBox(height: Sp.xs),
                      Text('Carry an original photo ID for every guest. Show your Booking ID at the front desk.',
                          style: TextStyle(fontSize: Fs.sm, color: C.tx(P.orange24), height: 1.45)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          BottomBar(
            child: Row(children: [
              Expanded(child: PillBtn('Back to home', kind: BtnKind.outline, onTap: home)),
              const SizedBox(width: Sp.md),
              Expanded(child: PillBtn('View booking', onTap: () => Navigator.pushNamed(context, '/booking-detail'))),
            ]),
          ),
        ]),
      ),
    );
  }
}
