import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import 'hotel_detail.dart' show billRow, totalBox;

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    Widget infoRow(String l, String v, {bool last = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: C.line))),
          child: Row(children: [
            Text(l, style: const TextStyle(fontSize: 14, color: C.muted)),
            const SizedBox(width: 12),
            Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          ]),
        );
    Widget contact(IconData icon, String t, String s, VoidCallback onTap) => Expanded(
          child: WhiteCard(
            radius: 18,
            padding: const EdgeInsets.all(14),
            onTap: onTap,
            child: Row(children: [
              IconTile(icon, bg: C.limeSoft, size: 38, radius: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ),
            ]),
          ),
        );
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 10),
          child: TitleBar(
            title: 'Booking details',
            trailing: CircleBtn(icon: Icons.help_outline_rounded, tooltip: 'Help', onTap: () => Navigator.pushNamed(context, '/help')),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(0, 6, 0, 28), children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: 3,
                controller: PageController(viewportFraction: 0.9),
                onPageChanged: (i) => setState(() => _photo = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: PhotoPlaceholder(height: 200, radius: 22, label: ['Room photo', 'Bathroom photo', 'Lobby photo'][i]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == _photo ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _photo ? C.ink : const Color(0xFFCFCFC7), borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 14),
                Row(children: [RatingBadge(h.rating), const SizedBox(width: 8), const Tag('Completed')]),
                const SizedBox(height: 10),
                Text(h.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
                const SizedBox(height: 6),
                Text(h.address, style: const TextStyle(fontSize: 13.5, color: C.muted, height: 1.5)),
                const SizedBox(height: 14),
                PillBtn('Get directions',
                    kind: BtnKind.outline, height: 48, expand: true, icon: Icons.near_me_outlined, trailingIcon: false, onTap: () => toast(context, 'Opening Maps…')),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    Row(children: [
                      const Expanded(child: Text('BOOKING ID · CHK240204', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1))),
                      Material(
                        color: const Color(0xA6FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => toast(context, 'Voucher downloaded'),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Row(children: [
                              Icon(Icons.download_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('Voucher', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    StayTimeline(
                      inTime: hourLabel(app.checkInHour),
                      outTime: hourLabel(app.checkOutHour),
                      inDate: dateLabel(app.date),
                      outDate: dateLabel(app.date),
                      slot: '${app.slot} hrs',
                      chip: C.white,
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  contact(Icons.call_outlined, 'Call hotel', 'Front desk', () => toast(context, 'Calling the hotel…')),
                  const SizedBox(width: 12),
                  contact(Icons.mail_outline_rounded, 'Email us', 'hello@checkdin.in', () => toast(context, 'Opening email…')),
                ]),
                const SectionLabel('Your room'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        const IconTile(Icons.bed_outlined, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Deluxe Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('Hourly stay · ${app.slot} hours · Room 204', style: const TextStyle(fontSize: 13, color: C.muted)),
                          ]),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        const Icon(Icons.group_outlined, size: 18, color: C.muted),
                        const SizedBox(width: 12),
                        Text(app.guestsLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    InkWell(
                      onTap: () => toast(context, 'Free cancellation up to 2 hours before check-in'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(children: [
                          Expanded(child: Text('View cancellation policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                          Icon(Icons.chevron_right_rounded),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SectionLabel('Guest details'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Column(children: [
                    infoRow('Name', app.name),
                    infoRow('Phone', app.phone.isEmpty ? '+91 98765 43210' : '+91 ${app.phone}'),
                    infoRow('Email', app.email.isEmpty ? '—' : app.email, last: true),
                  ]),
                ),
                const SectionLabel('Bill summary'),
                WhiteCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Column(children: [
                    billRow('Room price', inr(app.gross - app.fees)),
                    const SizedBox(height: 12),
                    if (app.coupon) ...[billRow('Coupon FIRST40', '−₹40', vColor: C.green), const SizedBox(height: 12)],
                    billRow('Taxes & fees', inr(app.fees)),
                    const SizedBox(height: 14),
                    totalBox(inr(app.total), label: 'Total paid'),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(child: PillBtn('Rate stay', kind: BtnKind.outline, onTap: () => Navigator.pushNamed(context, '/bookings'))),
            const SizedBox(width: 10),
            Expanded(child: PillBtn('Book again', onTap: () => Navigator.popUntil(context, ModalRoute.withName('/search')))),
          ]),
        ),
      ]),
    );
  }
}
