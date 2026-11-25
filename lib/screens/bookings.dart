import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

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
  int _tab = 1;
  bool _menu = false;
  bool _incog = false;
  int _rating = 0;

  Widget _upcoming() {
    final h = app.hotel;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Today'),
      WhiteCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Tag('● Confirmed', bg: C.lime, fg: C.ink),
                const SizedBox(height: 10),
                Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${h.area}, Chennai · Room 204', style: const TextStyle(fontSize: 13, color: C.muted)),
              ]),
            ),
            CircleBtn(icon: Icons.more_vert_rounded, size: 40, bg: C.bg, shadow: false, tooltip: 'More options', onTap: () => setState(() => _menu = !_menu)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(18)),
            child: StayTimeline(
              inTime: hourLabel(app.checkInHour),
              outTime: hourLabel(app.checkOutHour),
              inDate: dateLabel(app.date),
              outDate: dateLabel(app.date),
              slot: '${app.slot} hrs',
              chip: C.white,
            ),
          ),
          if (_menu) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.track, width: 1.5)),
              child: Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Incognito booking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Hide from your history 3 hrs after checkout', style: TextStyle(fontSize: 12, color: C.muted)),
                  ]),
                ),
                BrandSwitch(value: _incog, onChanged: (v) => setState(() => _incog = v)),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: PillBtn('Directions', height: 46, fontSize: 14, icon: Icons.near_me_rounded, trailingIcon: false, onTap: () => toast(context, 'Opening Maps…'))),
            const SizedBox(width: 10),
            Expanded(
                child: PillBtn('Call hotel',
                    kind: BtnKind.outline, height: 46, fontSize: 14, icon: Icons.call_outlined, trailingIcon: false, onTap: () => toast(context, 'Calling the hotel…'))),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [
          Expanded(child: Text('${inr(app.total)} paid via UPI', style: const TextStyle(fontSize: 13, color: C.muted))),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/help'),
            child: const Text('Need help?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ]),
      ),
    ]);
  }

  Widget _pastCard(_Past b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: WhiteCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.hotel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(b.when, style: const TextStyle(fontSize: 13, color: C.muted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(b.price,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: b.cancelled ? const Color(0xFF8A8A82) : C.ink,
                      decoration: b.cancelled ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 6),
              b.cancelled ? Tag(b.status, bg: C.redSoft, fg: const Color(0xFFA3241A)) : Tag(b.status),
            ]),
          ]),
          if (b.canRate || b.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: C.line, height: 1),
            const SizedBox(height: 12),
          ],
          if (b.canRate)
            Row(children: [
              Expanded(child: Text(_rating > 0 ? 'Thanks for rating!' : 'How was your stay?', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
              ...List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 26, color: i < _rating ? C.gold : C.faint),
                  ),
                ),
              ),
            ])
          else if (b.note.isNotEmpty)
            Row(children: [
              const Icon(Icons.check_circle_outline_rounded, size: 16, color: C.muted),
              const SizedBox(width: 8),
              Text(b.note, style: const TextStyle(fontSize: 13, color: C.muted)),
            ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: PillBtn('Book again', height: 44, fontSize: 13.5, onTap: () => popTo(context, '/search'))),
            const SizedBox(width: 10),
            Expanded(
                child: PillBtn('View details', kind: BtnKind.outline, height: 44, fontSize: 13.5, onTap: () => Navigator.pushNamed(context, '/booking-detail'))),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 32), children: [
        const TitleBar(title: 'My bookings'),
        const SizedBox(height: 20),
        SegmentPill(options: const ['Upcoming · 1', 'Past · 3'], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
        if (_tab == 0)
          _upcoming()
        else ...[
          const SectionLabel('November 2026'),
          ..._past.map(_pastCard),
        ],
      ]),
    );
  }
}
