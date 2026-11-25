import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    void home() => Navigator.popUntil(context, ModalRoute.withName('/search'));
    Widget action(IconData icon, String label, bool lime, VoidCallback onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: WhiteCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onTap: onTap,
              child: Column(children: [
                IconTile(icon, bg: lime ? C.lime : C.bg, size: 38, radius: 19),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
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
                  decoration: BoxDecoration(color: C.lime, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 3)),
                  child: const Icon(Icons.check_rounded, size: 54, color: C.ink),
                ),
              ),
              const SizedBox(height: 16),
              const Highlight(before: 'Booking ', marked: 'confirmed.', size: 30, align: TextAlign.center),
              const SizedBox(height: 8),
              const Text("Your room is ready for you. We've sent the details to your WhatsApp.",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: C.muted, height: 1.5)),
              const SizedBox(height: 14),
              Center(
                child: Material(
                  color: C.white,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'CHK240204'));
                      toast(context, 'Booking ID copied');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Booking ID ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.muted)),
                        Text('CHK240204', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        SizedBox(width: 10),
                        Icon(Icons.copy_rounded, size: 15),
                        SizedBox(width: 4),
                        Text('Copy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              WhiteCard(
                radius: 24,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            Text('Deluxe Room · ${h.area}', style: const TextStyle(fontSize: 12.5, color: C.muted)),
                          ]),
                        ),
                        const Tag('Paid'),
                      ]),
                      const SizedBox(height: 16),
                      StayTimeline(
                        inTime: hourLabel(app.checkInHour),
                        outTime: hourLabel(app.checkOutHour),
                        inDate: dateLabel(app.date),
                        outDate: dateLabel(app.checkOutHour >= 24 ? app.date.add(const Duration(days: 1)) : app.date),
                        slot: '${app.slot} hrs',
                      ),
                    ]),
                  ),
                  const Divider(color: C.line, height: 1, indent: 18, endIndent: 18),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    child: Row(children: [
                      Expanded(
                          child: Text('${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.guestsLabel}',
                              style: const TextStyle(fontSize: 13, color: C.muted))),
                      Text.rich(TextSpan(children: [
                        const TextSpan(text: 'Paid via UPI ', style: TextStyle(fontSize: 13, color: C.muted)),
                        TextSpan(text: inr(app.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      ])),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                action(Icons.near_me_rounded, 'Directions', true, () => toast(context, 'Opening Maps…')),
                action(Icons.call_outlined, 'Call hotel', false, () => toast(context, 'Calling the hotel…')),
                action(Icons.event_outlined, 'Calendar', false, () => toast(context, 'Added to your calendar')),
                action(Icons.download_rounded, 'Voucher', false, () => toast(context, 'Voucher downloaded')),
              ]),
              const SizedBox(height: 12),
              WhiteCard(
                color: const Color(0xFFFFF6DA),
                radius: 20,
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconTile(Icons.badge_outlined, bg: C.white, size: 34, radius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Before you go', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('Carry an original photo ID for every guest. Show your Booking ID at the front desk.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF4A4030), height: 1.45)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          BottomBar(
            child: Row(children: [
              Expanded(child: PillBtn('Back to home', kind: BtnKind.outline, onTap: home)),
              const SizedBox(width: 10),
              Expanded(child: PillBtn('View booking', onTap: () => Navigator.pushNamed(context, '/booking-detail'))),
            ]),
          ),
        ]),
      ),
    );
  }
}
