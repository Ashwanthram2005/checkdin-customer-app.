import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import 'maps.dart';
import 'cancel_sheet.dart';
import 'stay.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _Past {
  final String hotel, when, price, status, note;
  final bool cancelled, canRate;
  const _Past(this.hotel, this.when, this.price, this.status, {this.note = '', this.cancelled = false, this.canRate = false});
}

const _past = [
  _Past('The Grand Residency', 'Nov 24 · 2:00–5:00 PM · 3 hrs', '₹849', 'Completed', canRate: true),
  _Past('Hotel Marina Inn', 'Nov 18 · 11:00 AM–5:00 PM · 6 hrs', '₹1,299', 'Cancelled', note: 'Full refund sent to your UPI', cancelled: true),
  _Past('Skyline Suites', 'Nov 10 · 10:00 AM–10:00 PM · 12 hrs', '₹1,899', 'Completed', note: 'You rated this stay 4 ★'),
];

class _BookingsScreenState extends State<BookingsScreen> {
  late int _tab = app.bookingCancelled ? 1 : 0;
  bool _menu = false;
  bool _incog = false;
  int _rating = 0;

  List<_Past> get _pastAll => [
        if (app.bookingCancelled)
          _Past(app.hotel.name, '${app.whenShort} · ${app.stayLabel}', inr(app.total), 'Cancelled',
              note: app.cancelRefund > 0 ? 'Refund of ${inr(app.cancelRefund)} requested · 3–5 working days' : 'No refund · cancelled less than 3 hrs before check-in',
              cancelled: true),
        ..._past,
      ];

  Widget _noUpcoming() => Padding(
        padding: const EdgeInsets.only(top: Sp.x3),
        child: Column(children: [
          IconTile(Icons.event_busy_rounded, bg: C.limeBg, size: 72, radius: 24),
          const SizedBox(height: Sp.lg),
          const Text('No upcoming stays', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.sm),
          Text(
              app.cancelRefund > 0
                  ? 'Your booking was cancelled. A refund of ${inr(app.cancelRefund)} is on its way, usually in 3–5 working days.'
                  : 'Your booking was cancelled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.45)),
          const SizedBox(height: Sp.lg),
          PillBtn('Book a stay', kind: BtnKind.dark, height: 48, onTap: () => goHome(context)),
        ]),
      );

  Widget _upcoming() {
    if (app.bookingCancelled) return _noUpcoming();
    final h = app.hotel;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Today'),
      if (Sim.missedCheckin && !app.checkedIn)
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.sm),
          child: WhiteCard(
            color: P.amberSoft,
            padding: const EdgeInsets.all(Sp.md),
            onTap: () => Navigator.pushNamed(context, '/missed-checkin'),
            child: Row(children: [
              const Icon(Icons.schedule_rounded, color: P.ink),
              const SizedBox(width: Sp.md),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Check-in time has passed', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w800, color: P.ink)),
                  Text('See what happens now', style: TextStyle(fontSize: Fs.sm, color: P.ink2)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: P.ink),
            ]),
          ),
        ),
      WhiteCard(
        radius: R.xl,
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tag('● Confirmed', bg: C.limeBg, fg: C.ink),
                const SizedBox(height: Sp.md),
                Text(h.name, style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
                Text('${h.area}, Chennai · Room 204', style: TextStyle(fontSize: Fs.base, color: C.muted)),
              ]),
            ),
            CircleBtn(icon: Icons.more_vert_rounded, size: 40, bg: C.bg, shadow: false, tooltip: 'More options', onTap: () => setState(() => _menu = !_menu)),
          ]),
          const SizedBox(height: Sp.lg),
          Container(
            padding: const EdgeInsets.all(Sp.lg),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
            child: StayTimeline(
              inTime: hourLabel(app.checkInHour),
              outTime: hourLabel(app.checkOutHour),
              inDate: dateLabel(app.date),
              outDate: dateLabel(app.date),
              slot: '${app.slot} hrs',
              chip: C.card,
            ),
          ),
          if (_menu) ...[
            const SizedBox(height: Sp.md),
            Container(
              padding: const EdgeInsets.all(Sp.lg),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(R.lg), border: Border.all(color: C.track, width: 1.5)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Incognito booking', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    SizedBox(height: Sp.xxs),
                    Text('Hide from your history 3 hrs after checkout', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  ]),
                ),
                BrandSwitch(value: _incog, onChanged: (v) => setState(() => _incog = v)),
              ]),
            ),
          ],
          const SizedBox(height: Sp.lg),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, app.checkedIn ? '/live' : '/checkin');
              if (mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.md, Sp.md),
              decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.lg)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.checkedIn ? 'YOU\'RE CHECKED IN' : 'CHECK-IN OTP',
                        style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: C.faint)),
                    const SizedBox(height: Sp.xxs),
                    app.checkedIn
                        ? Text('View time left & extend', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800, color: C.lime))
                        : Text(app.checkinOtp.split('').join('  '),
                            style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: 1)),
                  ]),
                ),
                Text(app.checkedIn ? 'Open' : 'Show at desk', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.white)),
                Icon(Icons.chevron_right_rounded, color: C.white),
              ]),
            ),
          ),
          if (!app.checkedIn) ...[
            const SizedBox(height: Sp.sm),
            GestureDetector(
              onTap: () async {
                await showExtendSheet(context);
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
                decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.lg)),
                child: Row(children: [
                  const Icon(Icons.more_time_rounded, size: Ic.md),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Text(app.extraHours > 0 ? 'Extended · check-out ${app.outTimeLabel}' : 'Need more time? Extend before you arrive',
                        style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                  ),
                  const Text('Extend', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: Sp.md),
          Row(children: [
            Expanded(child: PillBtn('Directions', height: 46, fontSize: Fs.md, icon: Icons.near_me_rounded, trailingIcon: false, onTap: () => openDirections(context, app.hotel))),
            const SizedBox(width: Sp.md),
            Expanded(
                child: PillBtn('Call hotel',
                    kind: BtnKind.outline, height: 46, fontSize: Fs.md, icon: Icons.call_rounded, trailingIcon: false, onTap: () => callHotel(context))),
          ]),
          const SizedBox(height: Sp.md),
          GestureDetector(
            onTap: () async {
              final done = await showCancelBookingSheet(context);
              if (done && mounted) setState(() {});
            },
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(R.pill), border: Border.all(color: P.red85, width: 1.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_busy_rounded, size: Ic.md, color: C.red),
                SizedBox(width: Sp.sm),
                Text('Cancel booking', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: C.red)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: Sp.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
        child: Row(children: [
          Expanded(child: Text('${inr(app.total)} paid via ${app.paidWith}', style: TextStyle(fontSize: Fs.base, color: C.muted))),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/report'),
            child: const Text('Report an issue', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _openRate(_Past b, int stars) async {
    if (_rating > 0) return;
    final r = await Navigator.pushNamed(context, '/rate', arguments: {'hotel': b.hotel, 'when': b.when, 'rating': stars});
    if (r is int && mounted) setState(() => _rating = r);
  }

  Widget _pastCard(_Past b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.lg),
      child: WhiteCard(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.hotel, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                const SizedBox(height: Sp.xs),
                Text(b.when, style: TextStyle(fontSize: Fs.base, color: C.muted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(b.price,
                  style: TextStyle(
                      fontSize: Fs.lg,
                      fontWeight: FontWeight.w800,
                      color: b.cancelled ? P.hint : C.ink,
                      decoration: b.cancelled ? TextDecoration.lineThrough : null)),
              const SizedBox(height: Sp.sm),
              b.cancelled ? Tag(b.status, bg: C.redSoft, fg: P.redDark) : Tag(b.status),
            ]),
          ]),
          if (b.canRate || b.note.isNotEmpty) ...[
            const SizedBox(height: Sp.lg),
            Divider(color: C.line, height: 1),
            const SizedBox(height: Sp.md),
          ],
          if (b.canRate)
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _rating > 0 ? null : () => _openRate(b, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_rating > 0 ? 'Review posted' : 'How was your stay?', style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                    Text(_rating > 0 ? 'Thanks for helping other guests' : 'Rate & write a review',
                        style: TextStyle(fontSize: Fs.sm, color: C.muted, decoration: _rating > 0 ? null : TextDecoration.underline)),
                  ]),
                ),
              ),
              ...List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => _openRate(b, i + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.xs),
                    child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: Ic.lg, color: i < _rating ? C.gold : C.faint),
                  ),
                ),
              ),
            ])
          else if (b.note.isNotEmpty)
            Row(children: [
              Icon(Icons.check_circle_outline_rounded, size: Ic.sm, color: C.muted),
              const SizedBox(width: Sp.sm),
              Text(b.note, style: TextStyle(fontSize: Fs.base, color: C.muted)),
            ]),
          const SizedBox(height: Sp.lg),
          Row(children: [
            Expanded(child: PillBtn('Book again', height: 44, fontSize: Fs.base, onTap: () => popTo(context, '/search'))),
            const SizedBox(width: Sp.md),
            Expanded(
                child: PillBtn('View details', kind: BtnKind.outline, height: 44, fontSize: Fs.base, onTap: () => Navigator.pushNamed(context, '/booking-detail'))),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loader<void>(
        load: api.myBookings,
        cacheKey: 'bookings',
        skeleton: const SkPage(title: 'My bookings', child: SkCards(count: 3, height: 170)),
        builder: (context, _) => ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 32), children: [
        const TitleBar(title: 'My bookings'),
        const SizedBox(height: Sp.xl),
        SegmentPill(
            options: [app.bookingCancelled ? 'Upcoming · 0' : 'Upcoming · 1', 'Past · ${_pastAll.length}'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i)),
        if (_tab == 0)
          _upcoming()
        else ...[
          const SectionLabel('November 2026'),
          ..._pastAll.map(_pastCard),
        ],
      ]),
      ),
    );
  }
}
