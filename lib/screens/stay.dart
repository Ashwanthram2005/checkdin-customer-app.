import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import 'maps.dart';

String _hm(Duration d) {
  if (d.isNegative) return '0:00:00';
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

// ───────────────────────────────── Check-in OTP

class CheckinOtpScreen extends StatefulWidget {
  const CheckinOtpScreen({super.key});
  @override
  State<CheckinOtpScreen> createState() => _CheckinOtpScreenState();
}

class _CheckinOtpScreenState extends State<CheckinOtpScreen> {
  bool _checking = false;

  Future<void> _refresh() async {
    setState(() => _checking = true);
    try {
      await api.bookingDetail(app.bookingId);
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _checking = false);
        toast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    // Demo: the hotel has entered the OTP in the partner app.
    app.set(() {
      app.checkedIn = true;
      app.stayStart = DateTime.now();
      app.extraHours = 0;
      app.extraPaid = 0;
    });
    HapticFeedback.mediumImpact();
    toast(context, 'Checked in. Enjoy your stay!');
    Navigator.pushReplacementNamed(context, '/live');
  }

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    final digits = app.checkinOtp.split('');
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Check-in OTP'),
              const SizedBox(height: Sp.xxl),
              Center(
                child: Text('Show this at the front desk',
                    style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600, color: C.muted)),
              ),
              const SizedBox(height: Sp.lg),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final d in digits)
                  Container(
                    width: 66,
                    height: 82,
                    margin: const EdgeInsets.symmetric(horizontal: Sp.xs),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.lg)),
                    child: Text(d, style: TextStyle(fontSize: Fs.display, fontWeight: FontWeight.w800, color: C.lime)),
                  ),
              ]),
              const SizedBox(height: Sp.lg),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: app.checkinOtp));
                    toast(context, 'OTP copied');
                  },
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.copy_rounded, size: Ic.sm),
                    SizedBox(width: Sp.sm),
                    Text('Copy OTP', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ]),
                ),
              ),
              const SizedBox(height: Sp.xxl),
              WhiteCard(
                padding: const EdgeInsets.all(Sp.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Sp.xxs),
                  Text('${app.whenShort} · ${app.stayLabel} · Booking ${app.bookingId}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  Divider(color: C.line, height: 24),
                  for (final r in [
                    [Icons.badge_rounded, 'Carry an original photo ID for every guest'],
                    [Icons.schedule_rounded, 'The OTP works from 30 minutes before check-in'],
                    [Icons.lock_outline_rounded, 'Share it only with hotel staff, in person'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.md),
                      child: Row(children: [
                        Icon(r[0] as IconData, size: Ic.md, color: C.muted),
                        const SizedBox(width: Sp.md),
                        Expanded(child: Text(r[1] as String, style: const TextStyle(fontSize: Fs.base))),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              Container(
                padding: const EdgeInsets.all(Sp.lg),
                decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.lg)),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: Ic.md),
                  SizedBox(width: Sp.md),
                  Expanded(
                    child: Text('Once the hotel enters this OTP, your stay starts and the timer begins.',
                        style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, height: 1.4)),
                  ),
                ]),
              ),
            ],
          ),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(
                child: PillBtn('Directions',
                    kind: BtnKind.outline, height: 52, icon: Icons.near_me_rounded, trailingIcon: false, expand: true, onTap: () => openDirections(context, app.hotel))),
            const SizedBox(width: Sp.md),
            Expanded(
              child: PillBtn('I\'m checked in', kind: BtnKind.dark, height: 52, expand: true, loading: _checking, onTap: _refresh),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────────────── Live stay

class LiveStayScreen extends StatefulWidget {
  const LiveStayScreen({super.key});
  @override
  State<LiveStayScreen> createState() => _LiveStayScreenState();
}

class _LiveStayScreenState extends State<LiveStayScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (app.stayStart == null) app.stayStart = DateTime.now();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _checkout() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Check out now?', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.sm),
          Text('Return the key at the front desk. Leaving early isn\'t refunded.', style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.4)),
          const SizedBox(height: Sp.lg),
          Row(children: [
            Expanded(child: PillBtn('Stay', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pop(ctx, false))),
            const SizedBox(width: Sp.md),
            Expanded(
                child: AsyncBtn('Check out', kind: BtnKind.dark, expand: true, onTap: () async {
              try {
                await api.checkOut(app.bookingId);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on ApiError catch (e) {
                if (ctx.mounted) toast(ctx, e.message);
              }
            })),
          ]),
        ]),
      ),
    );
    if (ok != true || !mounted) return;
    app.set(() => app.checkedIn = false);
    toast(context, 'Checked out. Thanks for staying with Checkdin!');
    Navigator.pushNamedAndRemoveUntil(context, '/rate', ModalRoute.withName('/home'),
        arguments: {'hotel': app.hotel.name, 'when': app.whenShort, 'rating': 0});
  }

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    final start = app.stayStart!;
    final end = app.stayEnd;
    final total = end.difference(start).inSeconds;
    final left = end.difference(DateTime.now());
    final frac = total <= 0 ? 0.0 : (left.inSeconds / total).clamp(0.0, 1.0);
    final soon = left.inMinutes < 30;
    final over = left.isNegative;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          Row(children: [
            const BackBtn(),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.pill)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _Pulse(),
                SizedBox(width: Sp.sm),
                Text('Checked in', style: TextStyle(color: C.lime, fontSize: Fs.sm, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: Sp.lg),
          Text(h.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
          Text('${h.area} · Deluxe room', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.base, color: C.muted)),
          const SizedBox(height: Sp.xxl),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: _Ring(frac, soon ? C.red : C.lime),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(over ? 'Time\'s up' : 'TIME LEFT',
                        style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: over ? C.red : C.muted)),
                    const SizedBox(height: Sp.xs),
                    Text(_hm(left), style: const TextStyle(fontSize: Fs.display, fontWeight: FontWeight.w800, letterSpacing: -1.5, fontFeatures: [])),
                    const SizedBox(height: Sp.xs),
                    Text('Check-out ${_clock(end)}', style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: Sp.md),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Checked in ${_clock(start)}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
            if (app.extraHours > 0) ...[
              const SizedBox(width: Sp.sm),
              Tag('+${app.extraHours} hr${app.extraHours > 1 ? 's' : ''} added', bg: C.limeSoft, fg: C.ink),
            ],
          ]),
          if (soon) ...[
            const SizedBox(height: Sp.lg),
            Container(
              padding: const EdgeInsets.all(Sp.lg),
              decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
              child: Row(children: [
                Icon(Icons.timer_rounded, color: C.red),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Text(over ? 'Your slot has ended. Extend now or check out to avoid overstay charges.' : 'Less than 30 minutes left. Need more time?',
                      style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, color: C.tx(P.redDark), height: 1.4)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: Sp.lg),
          PillBtn('Extend stay', kind: BtnKind.dark, height: 56, icon: Icons.more_time_rounded, trailingIcon: false, expand: true, onTap: () async {
            await showExtendSheet(context);
            if (mounted) setState(() {});
          }),
          const SizedBox(height: Sp.md),
          Row(children: [
            for (final a in [
              [Icons.call_rounded, 'Call hotel', () { callHotel(context); }],
              [Icons.report_gmailerrorred_rounded, 'Report issue', () { Navigator.pushNamed(context, '/report'); }],
              [Icons.chat_bubble_outline_rounded, 'Chat', () { Navigator.pushNamed(context, '/chat'); }],
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
                  child: WhiteCard(
                    radius: R.lg,
                    padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                    onTap: a[2] as VoidCallback,
                    child: Column(children: [
                      Icon(a[0] as IconData),
                      const SizedBox(height: Sp.sm),
                      Text(a[1] as String, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
          ]),
          const SectionLabel('Your stay'),
          WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
            child: Column(children: [
              for (final r in [
                ['Booking', app.bookingId],
                ['Slot', app.stayLabel + (app.extraHours > 0 ? ' + ${app.extraHours} hr' : '')],
                ['Paid', inr(app.total + app.extraPaid)],
                if (app.forSomeoneElse) ['Guest', app.stayGuestName],
                ['Guests', app.guestsLabel],
              ])
                Container(
                  padding: const EdgeInsets.symmetric(vertical: Sp.md),
                  decoration: BoxDecoration(border: r[0] == 'Guests' ? null : Border(bottom: BorderSide(color: C.line))),
                  child: Row(children: [
                    Text(r[0], style: TextStyle(fontSize: Fs.base, color: C.muted)),
                    const Spacer(),
                    Text(r[1], style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: Sp.lg),
          Center(
            child: TextButton(
              onPressed: _checkout,
              child: Text('Check out early', style: TextStyle(color: C.ink, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle)),
      );
}

class _Ring extends CustomPainter {
  final double frac;
  final Color color;
  _Ring(this.frac, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 12;
    canvas.drawCircle(c, r + 12, Paint()..color = C.white);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..color = C.line);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * frac,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_Ring o) => o.frac != frac || o.color != color;
}

// ───────────────────────────────── Extend stay

Future<void> showExtendSheet(BuildContext context) async {
  final rate = app.extendRate;
  var pick = 1;
  var paying = false;
  // One key per extend sheet so a repeated request never charges twice.
  final extendKey = newIdempotencyKey();
  const maxExtra = 3;
  final avail = maxExtra - app.extraHours;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final newEnd = app.stayEnd.add(Duration(hours: pick));
      final price = rate * pick;
      final fees = (price * 0.106).round();
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs)))),
          const SizedBox(height: Sp.lg),
          const Text('Extend your stay', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.xs),
          Text('Your room is free for up to $avail more hour${avail == 1 ? '' : 's'}. ${inr(rate)} per hour.',
              style: TextStyle(fontSize: Fs.base, color: C.muted)),
          const SizedBox(height: Sp.lg),
          if (avail <= 0)
            Container(
              padding: const EdgeInsets.all(Sp.lg),
              decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
              child: Text('This room is booked right after your slot, so it can\'t be extended further. Try booking a new slot.',
                  style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, color: C.tx(P.redDark), height: 1.4)),
            )
          else ...[
            Row(children: [
              for (var n = 1; n <= 3; n++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
                    child: GestureDetector(
                      onTap: n <= avail ? () => set(() => pick = n) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 86,
                        decoration: BoxDecoration(
                          color: n > avail ? C.tint(P.grey94) : (pick == n ? C.lime : C.white),
                          borderRadius: BorderRadius.circular(R.lg),
                          border: Border.all(color: pick == n && n <= avail ? C.lime : C.border, width: 1.5),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('+$n hr', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, color: n > avail ? C.faint : C.ink)),
                          const SizedBox(height: Sp.xxs),
                          Text(n > avail ? 'Not free' : inr(rate * n),
                              style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: n > avail ? C.faint : C.muted)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: Sp.lg),
            Container(
              padding: const EdgeInsets.all(Sp.lg),
              decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
              child: Column(children: [
                Row(children: [
                  Text('New check-out', style: TextStyle(fontSize: Fs.base, color: C.muted)),
                  const Spacer(),
                  Text(_clock(newEnd), style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: Sp.sm),
                Row(children: [
                  Text('$pick hr × ${inr(rate)} + taxes', style: TextStyle(fontSize: Fs.base, color: C.muted)),
                  const Spacer(),
                  Text(inr(price + fees), style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
            const SizedBox(height: Sp.sm),
            Text('Paid with ${app.paidWith}. Extensions can\'t be cancelled.', style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
            const SizedBox(height: Sp.lg),
            PillBtn('Pay ${inr(price + fees)} & extend',
                loading: paying,
                kind: BtnKind.dark,
                height: 56,
                expand: true,
                onTap: paying
                    ? null
                    : () async {
                        set(() => paying = true);
                        try {
                          await api.extendStay(app.bookingId, pick, idempotencyKey: extendKey);
                        } on ApiError catch (e) {
                          set(() => paying = false);
                          if (context.mounted) toast(context, e.message);
                          return;
                        }
                        app.set(() {
                          app.extraHours += pick;
                          app.extraPaid += price + fees;
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) toast(context, 'Extended till ${_clock(app.stayEnd)}');
                      }),
          ],
        ]),
      );
    }),
  );
}
