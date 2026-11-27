import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';

enum RefundStatus { underReview, initiated, processing, completed, failed }

class Refund {
  final String hotel, bookingId, to, reason;
  final int amount;
  final RefundStatus status;
  final DateTime requested;
  final String? rrn;
  const Refund(this.hotel, this.bookingId, this.amount, this.to, this.status, this.requested, {this.rrn, this.reason = 'Booking cancelled'});

  bool get toCredits => to.startsWith('Checkdin credits');
  bool get ongoing => status != RefundStatus.completed && status != RefundStatus.failed;
  DateTime get doneOn => requested.add(Duration(days: toCredits ? 0 : 5));
}

String _d(DateTime d) => '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}, ${d.year}';

List<Refund> get myRefunds {
  final t = DateTime.now();
  final day = DateTime(t.year, t.month, t.day);
  return [
    if (app.bookingCancelled && app.cancelRefund > 0)
      Refund(app.hotel.name, 'CHK240204', app.cancelRefund, app.paidWith == 'UPI' ? 'UPI' : app.paidWith, RefundStatus.underReview, day,
          reason: 'You cancelled this booking'),
    Refund('Hotel Sapphire Inn', 'CHK239871', 540, 'Card (XXX-0121)', RefundStatus.processing, day.subtract(const Duration(days: 2))),
    Refund('Le Royal Stays', 'CHK239655', 299, 'UPI', RefundStatus.initiated, day.subtract(const Duration(days: 1)),
        reason: 'Hotel couldn\'t honour the booking'),
    Refund('The Grand Egmore', 'CHK238120', 899, 'Card (XXX-0121)', RefundStatus.completed, day.subtract(const Duration(days: 34)),
        rrn: '790393289617637720'),
    Refund('OMR Business Suites', 'CHK237402', 150, 'Checkdin credits', RefundStatus.completed, day.subtract(const Duration(days: 58))),
    Refund('Porur Comfort Rooms', 'CHK236911', 420, 'UPI', RefundStatus.completed, day.subtract(const Duration(days: 71)), rrn: '601284937551204836'),
  ];
}

class RefundsScreen extends StatefulWidget {
  const RefundsScreen({super.key});
  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  final _open = <String>{};
  final _answered = <String>{};

  ({String label, Color fg, Color bg, IconData icon}) _chip(RefundStatus s) => switch (s) {
        RefundStatus.underReview => (label: 'Under review', fg: C.tx(const Color(0xFF8A5A00)), bg: C.tint(const Color(0xFFFFF1C7)), icon: Icons.hourglass_top_rounded),
        RefundStatus.initiated => (label: 'Initiated', fg: C.tx(const Color(0xFF1F5FAF)), bg: C.tint(const Color(0xFFE3EEFC)), icon: Icons.send_rounded),
        RefundStatus.processing => (label: 'With your bank', fg: C.tx(const Color(0xFF6A3FB5)), bg: C.tint(const Color(0xFFEEE6FB)), icon: Icons.account_balance_outlined),
        RefundStatus.completed => (label: 'Completed', fg: C.green, bg: C.limeSoft, icon: Icons.check_circle_rounded),
        RefundStatus.failed => (label: 'Failed', fg: C.red, bg: C.redSoft, icon: Icons.error_outline_rounded),
      };

  /// Steps of the refund, and how many are done.
  List<(String, String, String)> _steps(Refund r) {
    final req = r.requested;
    if (r.toCredits) {
      return [
        ('Refund requested', _d(req), r.reason),
        ('Checkdin approved your refund', _d(req), 'Completed'),
        ('Added to Checkdin credits', _d(req), 'Completed — use it on your next booking. It never expires.'),
      ];
    }
    final st = r.status.index;
    String state(int i) => st > i || r.status == RefundStatus.completed ? 'Completed' : (st == i ? 'In progress' : 'Pending');
    return [
      ('Refund requested', _d(req), r.reason),
      ('Checkdin is reviewing it', st >= 1 ? _d(req) : 'Usually within 24 hours', st == 0 ? 'In progress — we\'re confirming with the hotel' : 'Completed'),
      ('Checkdin has initiated your refund', st >= 1 ? _d(req.add(const Duration(days: 1))) : 'Next step', state(1)),
      ('Your bank is processing it', st >= 2 ? _d(req.add(const Duration(days: 1))) : 'Takes 5–7 working days', state(2)),
      (
        'Refund credited to your ${r.to.startsWith('UPI') ? 'UPI account' : 'account'}',
        r.status == RefundStatus.completed ? _d(r.doneOn) : 'Expected by ${_d(req.add(const Duration(days: 7)))}',
        r.status == RefundStatus.completed
            ? 'Completed — the amount should be in your account. If not, contact your bank with this RRN:'
            : 'Pending'
      ),
    ];
  }

  int _done(Refund r) {
    if (r.status == RefundStatus.completed || r.toCredits) return 99;
    return r.status.index + 1; // requested + finished steps
  }

  void _whatIsRrn() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: C.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('What is an RRN?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
              'The Retrieval Reference Number is a 12–18 digit number your bank gives every transaction. If the refund isn\'t in your statement, share this number with your bank\'s customer care and they can trace it.',
              style: TextStyle(fontSize: 14, color: C.muted, height: 1.5)),
          const SizedBox(height: 16),
          PillBtn('Got it', kind: BtnKind.dark, expand: true, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    );
  }

  Widget _timeline(Refund r) {
    final steps = _steps(r);
    final done = _done(r);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          final isDone = i < done;
          final isNow = i == done && r.ongoing;
          final last = i == steps.length - 1;
          final dot = isDone ? C.green : (isNow ? C.ink : C.faint);
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 24,
                child: Column(children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNow ? C.limeBg : C.card,
                      border: Border.all(color: dot, width: isDone || isNow ? 4 : 2),
                    ),
                  ),
                  if (!last) Expanded(child: Container(width: 3, color: i + 1 < done ? C.green : C.track)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 4 : 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: isDone || isNow ? C.ink : C.muted)),
                    const SizedBox(height: 2),
                    Text(s.$2, style: TextStyle(fontSize: 12.5, color: C.muted)),
                    const SizedBox(height: 4),
                    Text(s.$3,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: isNow ? FontWeight.w700 : FontWeight.w400,
                            color: isNow ? C.ink : C.muted2)),
                    if (last && r.rrn != null && r.status == RefundStatus.completed) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: r.rrn!));
                          toast(context, 'RRN copied');
                        },
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(r.rrn!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded, size: 15, color: C.muted),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _whatIsRrn,
                        child: Text('What is RRN?',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: C.ink, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _card(Refund r) {
    final c = _chip(r.status);
    final open = _open.contains(r.bookingId);
    Widget dash() => Container(height: 1, color: C.line);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WhiteCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(r.hotel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                  decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(c.icon, size: 14, color: c.fg),
                    const SizedBox(width: 4),
                    Text(c.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.fg)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'To: ', style: TextStyle(color: C.ink, fontWeight: FontWeight.w700)),
                TextSpan(text: r.to, style: TextStyle(color: C.muted)),
              ]), style: const TextStyle(fontSize: 13.5)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: r.status == RefundStatus.completed ? 'Completed on: ' : 'Requested on: ',
                        style: TextStyle(color: C.ink, fontWeight: FontWeight.w700)),
                    TextSpan(text: _d(r.status == RefundStatus.completed ? r.doneOn : r.requested), style: TextStyle(color: C.muted)),
                  ]), style: const TextStyle(fontSize: 13.5)),
                ),
                Text(inr(r.amount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              if (r.ongoing) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.schedule_rounded, size: 16, color: C.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          r.status == RefundStatus.underReview
                              ? 'We\'re reviewing it. Expect it by ${_d(r.requested.add(const Duration(days: 7)))}.'
                              : 'Expected in your account by ${_d(r.requested.add(const Duration(days: 7)))}.',
                          style: TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ],
            ]),
          ),
          dash(),
          if (open) ...[
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/bookings'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Text('Booking ID: ', style: TextStyle(fontSize: 13.5, color: C.muted)),
                  Text('#${r.bookingId}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: C.muted),
                ]),
              ),
            ),
            dash(),
            _timeline(r),
            dash(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: r.ongoing
                  ? Row(children: [
                      Expanded(child: Text('Questions about this refund?', style: TextStyle(fontSize: 13.5, color: C.muted))),
                      TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/chat'),
                          child: Text('Chat with us', style: TextStyle(fontWeight: FontWeight.w800, color: C.ink))),
                    ])
                  : _answered.contains(r.bookingId)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('Thanks for letting us know.', style: TextStyle(fontSize: 13.5, color: C.muted)),
                        )
                      : Row(children: [
                          Expanded(child: Text('Did you receive your refund?', style: TextStyle(fontSize: 13.5, color: C.muted))),
                          TextButton.icon(
                            onPressed: () => setState(() => _answered.add(r.bookingId)),
                            icon: Icon(Icons.thumb_up_alt_outlined, size: 16, color: C.green),
                            label: Text('Yes', style: TextStyle(fontWeight: FontWeight.w800, color: C.green)),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/chat'),
                            icon: Icon(Icons.thumb_down_alt_outlined, size: 16, color: C.red),
                            label: Text('No', style: TextStyle(fontWeight: FontWeight.w800, color: C.red)),
                          ),
                        ]),
            ),
            dash(),
          ],
          InkWell(
            onTap: () => setState(() => open ? _open.remove(r.bookingId) : _open.add(r.bookingId)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(open ? 'Hide details' : 'See details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.ink)),
                const SizedBox(width: 4),
                Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: C.ink),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = myRefunds;
    final ongoing = all.where((r) => r.ongoing).toList();
    final done = all.where((r) => !r.ongoing).toList();
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
          const TitleBar(title: 'My refunds'),
          const SizedBox(height: 14),
          WhiteCard(
            child: Row(children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Refunds go back to your '),
                    TextSpan(text: 'original payment method', style: TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
                    const TextSpan(text: ' in 5–7 working days. Checkdin credits are added instantly.'),
                  ]),
                  style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.45),
                ),
              ),
              const SizedBox(width: 12),
              IconTile(Icons.currency_rupee_rounded, bg: C.limeSoft, size: 48, radius: 24),
            ]),
          ),
          if (ongoing.isNotEmpty) ...[
            SectionLabel('Ongoing refunds · ${ongoing.length}'),
            ...ongoing.map(_card),
          ],
          SectionLabel('Completed refunds · ${done.length}'),
          ...done.map(_card),
        ]),
      ),
    );
  }
}
