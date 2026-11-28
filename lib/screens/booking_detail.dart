import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import '../voucher.dart';
import 'maps.dart';
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
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
          child: Row(children: [
            Text(l, style: TextStyle(fontSize: Fs.md, color: C.muted)),
            const SizedBox(width: Sp.md),
            Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
          ]),
        );
    Widget contact(IconData icon, String t, String s, VoidCallback onTap) => Expanded(
          child: WhiteCard(
            radius: R.lg,
            padding: const EdgeInsets.all(Sp.lg),
            onTap: onTap,
            child: Row(children: [
              IconTile(icon, bg: C.limeSoft, size: 38, radius: 19),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  Text(s, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                ]),
              ),
            ]),
          ),
        );
    return Scaffold(
      body: Loader<void>(
        load: () => api.bookingDetail(app.bookingId),
        cacheKey: 'booking|${app.bookingId}',
        skeleton: const SkPage(title: 'Booking details', child: SkCards(count: 3, height: 140)),
        builder: (context, _) => Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 10),
          child: TitleBar(
            title: 'Booking details',
            trailing: CircleBtn(icon: Icons.help_outline_rounded, tooltip: 'Help', onTap: () => Navigator.pushNamed(context, '/help')),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(0, Sp.sm, 0, Sp.x3), children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: 3,
                controller: PageController(viewportFraction: 0.9),
                onPageChanged: (i) => setState(() => _photo = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
                  child: PhotoPlaceholder(height: 200, radius: 22, label: ['Room photo', 'Bathroom photo', 'Lobby photo'][i]),
                ),
              ),
            ),
            const SizedBox(height: Sp.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: Sp.xxs),
                  width: i == _photo ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _photo ? C.inkBg : C.tint(P.dotIdle), borderRadius: BorderRadius.circular(R.pill)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: Sp.lg),
                Row(children: [RatingBadge(h.rating), const SizedBox(width: Sp.sm), const Tag('Completed')]),
                const SizedBox(height: Sp.md),
                Text(h.name, style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
                const SizedBox(height: Sp.sm),
                Text(h.address, style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.5)),
                const SizedBox(height: Sp.lg),
                PillBtn('Get directions',
                    kind: BtnKind.outline, height: 48, expand: true, icon: Icons.near_me_rounded, trailingIcon: false, onTap: () => openDirections(context, app.hotel)),
                const SizedBox(height: Sp.xl),
                Container(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.lg),
                  decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.xl)),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: Text('BOOKING ID · ${app.bookingId}', style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, letterSpacing: 1))),
                      Material(
                        color: P.whiteA65,
                        borderRadius: BorderRadius.circular(R.pill),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(R.pill),
                          onTap: () => shareVoucher(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                            child: Row(children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: voucherBusy,
                                builder: (_, busy, __) => busy ? const Spinner(size: 15) : const Icon(Icons.download_rounded, size: Ic.sm),
                              ),
                              SizedBox(width: Sp.xs),
                              Text('Voucher', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: Sp.lg),
                    StayTimeline(
                      inTime: hourLabel(app.checkInHour),
                      outTime: hourLabel(app.checkOutHour),
                      inDate: dateLabel(app.date),
                      outDate: dateLabel(app.date),
                      slot: '${app.slot} hrs',
                      chip: C.card,
                    ),
                  ]),
                ),
                const SizedBox(height: Sp.md),
                Row(children: [
                  contact(Icons.call_rounded, 'Call hotel', 'Front desk', () => callHotel(context)),
                  const SizedBox(width: Sp.md),
                  contact(Icons.mail_outline_rounded, 'Email us', 'hello@checkdin.in', () => toast(context, 'Opening email…')),
                ]),
                const SectionLabel('Your room'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        const IconTile(Icons.bed_rounded, size: 42),
                        const SizedBox(width: Sp.md),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Deluxe Room', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                            Text('Hourly stay · ${app.slot} hours · Room 204', style: TextStyle(fontSize: Fs.base, color: C.muted)),
                          ]),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        Icon(Icons.group_rounded, size: Ic.md, color: C.muted),
                        const SizedBox(width: Sp.md),
                        Text(app.guestsLabel, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/cancel-policy'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: Sp.lg),
                        child: Row(children: [
                          Expanded(child: Text('View cancellation policy', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                          Icon(Icons.chevron_right_rounded),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: Sp.md),
                WhiteCard(
                  onTap: () => Navigator.pushNamed(context, '/report'),
                  child: Row(children: [
                    IconTile(Icons.report_gmailerrorred_rounded, bg: C.redSoft, size: 40),
                    SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Report an issue', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                        SizedBox(height: Sp.xxs),
                        Text('Room, check-in, extra charges or safety', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ]),
                ),
                const SectionLabel('Guest details'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
                  child: Column(children: [
                    if (app.forSomeoneElse) ...[
                      infoRow('Guest', app.stayGuestName),
                      infoRow('Guest phone', app.stayGuestPhone),
                      infoRow('Booked by', app.name),
                    ] else ...[
                      infoRow('Name', app.name),
                      infoRow('Phone', app.stayGuestPhone),
                    ],
                    infoRow('Email', app.email.isEmpty ? '—' : app.email, last: true),
                  ]),
                ),
                const SectionLabel('Bill summary'),
                WhiteCard(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.md),
                  child: Column(children: [
                    billRow('Room price', inr(app.gross - app.fees)),
                    const SizedBox(height: Sp.md),
                    if (app.discount > 0) ...[billRow('Coupon ${app.couponCode}', '−${inr(app.discount)}', vColor: C.green), const SizedBox(height: Sp.md)],
                    billRow('Taxes & fees', inr(app.fees)),
                    const SizedBox(height: Sp.lg),
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
            const SizedBox(width: Sp.md),
            Expanded(child: PillBtn('Book again', onTap: () => popTo(context, '/search'))),
          ]),
        ),
      ]),
      ),
    );
  }
}
