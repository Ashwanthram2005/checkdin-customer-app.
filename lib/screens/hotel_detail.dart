import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../optimistic.dart';
import '../loading.dart';
import '../api/api.dart';
import 'gallery.dart';
import 'hotel_extras.dart';
import 'maps.dart';
import 'reviews.dart';

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({super.key});
  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  final _keys = {for (final s in ['Slots', 'Room', 'Reviews', 'Location', 'Food', 'Rules']) s: GlobalKey()};

  final _scroll = ScrollController();
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > 250;
      if (c != _compact) setState(() => _compact = c);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jump(String s) {
    final ctx = _keys[s]!.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOut, alignment: 0.05);
  }

  void _priceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.x3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: C.tint(P.border), borderRadius: BorderRadius.circular(R.pill))),
          const SizedBox(height: Sp.lg),
          Row(children: [
            const Expanded(child: Text('Price details', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800))),
            CircleBtn(icon: Icons.close_rounded, size: 36, bg: C.bg, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: Sp.lg),
          _billRow('Room price · ${app.stayLabel}', inr(app.gross - app.fees)),
          const SizedBox(height: Sp.md),
          _billRow('Taxes & fees', inr(app.fees)),
          const SizedBox(height: Sp.lg),
          _totalBox(inr(app.gross)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final h = app.hotel;
        final saved = app.saved.contains(h.id);
        final price = app.unitPrice;
        return Scaffold(
          body: Column(children: [
            Expanded(
              child: CustomScrollView(controller: _scroll, slivers: [
                SliverToBoxAdapter(
                  child: Stack(children: [
                    const GalleryStrip(height: 300),
                    Positioned(left: 16, top: MediaQuery.of(context).padding.top + 10, child: const BackBtn()),
                    Positioned(
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 10,
                      child: Row(children: [
                        CircleBtn(
                          icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: saved ? P.redBright : C.ink,
                          tooltip: 'Save',
                          onTap: () => toggleSaved(context, h),
                        ),
                        const SizedBox(width: Sp.sm),
                        CircleBtn(icon: Icons.share_rounded, tooltip: 'Share', onTap: () => shareHotel(context, h)),
                      ]),
                    ),
                    
                  ]),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xl, Sp.xl, 0),
                      decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          RatingBadge(h.rating, reviews: h.reviews),
                          if (h.topRated) ...[const SizedBox(width: Sp.sm), Tag('Top rated', bg: C.limeBg, fg: C.ink)],
                        ]),
                        const SizedBox(height: Sp.md),
                        Text(h.name, style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
                        const SizedBox(height: Sp.xs),
                        Text('${h.area}, Chennai · ${kmLabel(h)}', style: TextStyle(fontSize: Fs.base, color: C.muted)),
                      ]),
                    ),
                  ),
                ),
                SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(_keys.keys.toList(), _jump,
                        compact: _compact,
                        top: MediaQuery.of(context).padding.top,
                        title: h.name,
                        saved: saved,
                        onSave: () => toggleSaved(context, h),
                        onShare: () => shareHotel(context, h))),
SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xs, Sp.xl, Sp.x3),
                    child: Loader<Hotel>(
                      reloadKey: h.id,
                      load: () => api.hotelDetails(h.id),
                      cacheKey: 'hotel|${h.id}',
                      skeleton: const SkHotelBody(),
                      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: Sp.lg),
                      WhiteCard(
                        key: _keys['Slots'],
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const StayEditors(),
                          const SizedBox(height: Sp.lg),
                          Text(app.fullDay ? 'Your stay' : 'Choose your slot', style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                          if (!app.fullDay)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.xxs),
                              child: Text.rich(TextSpan(style: TextStyle(fontSize: Fs.base, color: C.muted), children: [
                                const TextSpan(text: 'Per night '),
                                TextSpan(text: inr(h.night), style: const TextStyle(decoration: TextDecoration.lineThrough)),
                                if (price != null)
                                  TextSpan(
                                      text: '  ·  save ${((1 - price / h.night) * 100).round()}% by the hour',
                                      style: TextStyle(color: C.green, fontWeight: FontWeight.w700)),
                              ])),
                            ),
                          const SizedBox(height: Sp.md),
                          if (app.fullDay)
                            StayTimeline(
                              inTime: app.inTimeLabel,
                              outTime: app.outTimeLabel,
                              inDate: app.inDateLabel,
                              outDate: app.outDateLabel,
                              slot: app.stayLabel,
                            )
                          else
                          SizedBox(
                            height: 100,
                            child: MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.1,
                              child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [3, 6, 9, 12].map((hrs) {
                                final p = h.priceFor(hrs);
                                final on = hrs == app.slot;
                                return Padding(
                                  padding: EdgeInsets.only(right: hrs == Sp.md ? 0 : Sp.sm),
                                  child: GestureDetector(
                                    onTap: p == null ? null : () => app.set(() => app.slot = hrs),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 112,
                                      decoration: BoxDecoration(
                                        color: on ? C.limeBg : (p == null ? C.bg : C.card),
                                        borderRadius: BorderRadius.circular(R.lg),
                                        border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                                      ),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: p == null
                                          ? [
                                              Text('Not available', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.faint)),
                                              const SizedBox(height: Sp.xxs),
                                              Text('for $hrs hours', style: TextStyle(fontSize: Fs.sm, color: C.faint)),
                                            ]
                                          : [
                                              Text(inr(p), style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                                              const SizedBox(height: Sp.xxs),
                                              Text('${hourLabel(app.checkInHour, short: true)} – ${hourLabel(app.checkInHour + hrs, short: true)}',
                                                  style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600)),
                                              Text('$hrs hours', style: TextStyle(fontSize: Fs.xs, color: on ? C.limeInk : C.muted2)),
                                            ]),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            ),
                          ),
                          const SizedBox(height: Sp.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.md),
                            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.md)),
                            child: Row(children: [
                              const Icon(Icons.schedule_rounded, size: Ic.sm),
                              const SizedBox(width: Sp.sm),
                              Text.rich(TextSpan(style: TextStyle(fontSize: Fs.base, color: C.tx(P.ink2)), children: [
                                const TextSpan(text: 'Check-out at '),
                                TextSpan(
                                    text: app.fullDay ? '11:00 AM, ${dateLabel(app.outDate)}' : '${hourLabel(app.checkOutHour)}${app.checkOutHour >= 24 ? ' (next day)' : ''}',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
                              ])),
                            ]),
                          ),
                          const SizedBox(height: Sp.md),
                          Row(children: [
                            Icon(Icons.verified_rounded, size: Ic.sm, color: C.green),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: Text('Earn ${inr(((price ?? h.night) * 0.05).round())} Checkdin credits on this stay',
                                  style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.green)),
                            ),
                          ]),
                        ]),
                      ),
                      SectionLabel('Room', key: _keys['Room']),
                      RoomCard(h),
                      const SectionLabel('Facilities'),
                      WhiteCard(
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.15,
                          children: const [
                            _Facility(Icons.ac_unit_rounded, 'Air conditioning'),
                            _Facility(Icons.wifi_rounded, 'Free Wi-Fi'),
                            _Facility(Icons.tv_rounded, 'Smart TV'),
                            _Facility(Icons.local_parking_rounded, 'Parking'),
                            _Facility(Icons.support_agent_rounded, '24-hr front desk'),
                            _Facility(Icons.bolt_rounded, 'Power backup'),
                          ],
                        ),
                      ),
                      SectionLabel('Ratings & reviews', key: _keys['Reviews']),
                      WhiteCard(
                        padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.lg),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(h.rating, style: const TextStyle(fontSize: Fs.display, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1)),
                            const SizedBox(width: Sp.lg),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(Icons.star_rounded,
                                        size: Ic.md, color: i < double.parse(h.rating).round() ? C.gold : P.grey87)),
                              ),
                              const SizedBox(height: Sp.xs),
                              Text('Based on ${h.reviews} verified stays', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                            ]),
                          ]),
                          const SizedBox(height: Sp.lg),
                          for (final b in const [['Comfort', 4.5], ['Cleanliness', 4.6], ['Value', 4.1]])
                            Padding(
                              padding: const EdgeInsets.only(bottom: Sp.md),
                              child: Row(children: [
                                SizedBox(width: 92, child: Text(b[0] as String, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(R.pill),
                                    child: LinearProgressIndicator(
                                      value: (b[1] as double) / 5,
                                      minHeight: 8,
                                      backgroundColor: C.line,
                                      valueColor: AlwaysStoppedAnimation(C.ink),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: 32,
                                    child: Text('${b[1]}', textAlign: TextAlign.right, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700))),
                              ]),
                            ),
                          const SizedBox(height: Sp.xs),
                          ReviewSummary(h),
                          const SizedBox(height: Sp.lg),
                          const ReviewsPreview(),
                          const SizedBox(height: Sp.sm),
                          TapLink('See all ${h.reviews} reviews',
                              onTap: () => Navigator.pushNamed(context, '/reviews'),
                              style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                        ]),
                      ),
                      SectionLabel('Location', key: _keys['Location']),
                      Material(
                        color: C.card,
                        borderRadius: BorderRadius.circular(R.xl),
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          HotelMiniMap(h, height: 150),
                          Padding(
                            padding: const EdgeInsets.all(Sp.lg),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(h.address, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                              const SizedBox(width: Sp.md),
                              PillBtn('Directions', kind: BtnKind.outline, height: 38, fontSize: Fs.base, onTap: () => openDirections(context, h)),
                            ]),
                          ),
                          Padding(padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.md), child: NearbyCard(h)),
                        ]),
                      ),
                      SectionLabel('Food & dining', key: _keys['Food']),
                      FoodCard(h),
                      SectionLabel('Property rules', key: _keys['Rules']),
                      RulesCard(h),
                      const SizedBox(height: Sp.md),
                      const _Policies(),
                    ]),
                    ),
                  ),
                ),
              ]),
            ),
            BottomBar(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Loader<int?>(
                      reloadKey: '${app.slot}|${app.date}|${app.hour}|${app.rooms}|${app.adults}|${app.kids}|${app.fullDay}|${app.inDate}|${app.outDate}',
                      load: () => api.quote(h.id),
                      skeleton: const Skeleton(child: Bone(width: 96, height: 24)),
                      builder: (context, _) => Text(price == null ? 'Not available' : inr(app.gross), style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
                    ),
                    Text(
                        app.fullDay
                            ? '${app.stayLabel} · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · incl. taxes'
                            : '${hourLabel(app.checkInHour, short: true)} – ${hourLabel(app.checkOutHour, short: true)} (${app.slot} hrs) · incl. taxes',
                        style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    GestureDetector(
                      onTap: _priceSheet,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(top: Sp.sm, bottom: Sp.md, right: Sp.xxl),
                        child: Text('Price details',
                            style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                      ),
                    ),
                  ]),
                ),
                PillBtn('Reserve', height: 54, icon: Icons.arrow_forward_rounded, onTap: price == null ? null : () => Navigator.pushNamed(context, '/reserve')),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

Widget _billRow(String l, String v, {Color? vColor}) => Row(children: [
      Expanded(child: Text(l, style: TextStyle(fontSize: Fs.md, color: C.muted))),
      Text(v, style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: vColor ?? C.ink)),
    ]);

Widget _totalBox(String v, {String label = 'To pay'}) => Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.lg)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.xxs),
            Text('Inclusive of all taxes', style: TextStyle(fontSize: Fs.sm, color: C.limeInk)),
          ]),
        ),
        Text(v, style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
      ]),
    );

/// Shared helpers for other screens.
Widget billRow(String l, String v, {Color? vColor}) => _billRow(l, v, vColor: vColor);
Widget totalBox(String v, {String label = 'To pay'}) => _totalBox(v, label: label);

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final ValueChanged<String> onTap;
  final bool compact, saved;
  final double top;
  final String title;
  final VoidCallback onSave, onShare;
  _TabsDelegate(this.tabs, this.onTap,
      {required this.compact, required this.top, required this.title, required this.saved, required this.onSave, required this.onShare});
  double get _h => 54 + (compact ? top + 56 : 0);
  @override
  double get minExtent => _h;
  @override
  double get maxExtent => _h;
  @override
  bool shouldRebuild(covariant _TabsDelegate old) => old.compact != compact || old.saved != saved || old.top != top;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: C.bg,
      child: Column(children: [
        if (compact)
          Container(
            height: top + 56,
            padding: EdgeInsets.fromLTRB(Sp.md, top, Sp.sm, 0),
            decoration: BoxDecoration(color: C.card, border: Border(bottom: BorderSide(color: C.line))),
            child: Row(children: [
              const BackBtn(shadow: false),
              const SizedBox(width: Sp.sm),
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800))),
              IconButton(
                tooltip: 'Save',
                onPressed: onSave,
                icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: saved ? P.redBright : C.ink),
              ),
              IconButton(tooltip: 'Share', onPressed: onShare, icon: Icon(Icons.share_rounded, color: C.ink)),
            ]),
          ),
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.sm),
            children: tabs
                .map((t) => Padding(
                      padding: const EdgeInsets.only(right: Sp.sm),
                      child: ActionChip(
                        label: Text(t, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                        backgroundColor: C.card,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        onPressed: () => onTap(t),
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }
}

class _Facility extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Facility(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
        IconTile(icon, size: 44, radius: 14),
        const SizedBox(height: Sp.sm),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, height: 1.3)),
      ]);
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tile;
  const _Rule(this.icon, this.label, this.tile);
  @override
  Widget build(BuildContext context) => WhiteCard(
        radius: R.lg,
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          IconTile(icon, bg: tile, size: 32, radius: 10),
          const SizedBox(height: Sp.sm),
          Text(label, maxLines: 2, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, height: 1.3)),
        ]),
      );
}

class _Policies extends StatelessWidget {
  const _Policies();
  @override
  Widget build(BuildContext context) {
    const pol = {
      'Check-in requirements': [
        'Carry an original government photo ID for every guest: Aadhaar, passport, driving licence or voter ID.',
        'Digital copies of ID are not accepted.',
        'Local IDs are accepted at this hotel.',
        'The hotel may refuse check-in if ID rules are not met.',
      ],
      'Cancellation': [
        '50% refund if you cancel more than 5 hrs before check-in, 25% between 5 and 3 hrs, none after that.',
        'No refund for no-shows or for leaving early.',
        'Approved refunds reach you in 3–5 working days.',
      ],
    };
    return WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: pol.entries
              .map((e) => ExpansionTile(
                    title: Text(e.key, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    iconColor: C.ink,
                    collapsedIconColor: C.ink,
                    childrenPadding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
                    children: e.value
                        .map<Widget>((t) => Padding(
                              padding: const EdgeInsets.only(bottom: Sp.sm),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(top: Sp.sm, right: Sp.md),
                                  decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 1.2)),
                                ),
                                Expanded(child: Text(t, style: TextStyle(fontSize: Fs.base, color: C.tx(P.ink2), height: 1.5))),
                              ]),
                            ))
                        .toList()
                      ..addAll(e.key == 'Cancellation'
                          ? [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/cancel-policy'),
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: Sp.lg),
                                    child: Text('Read full policy',
                                        style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                                  ),
                                ),
                              ),
                            ]
                          : const <Widget>[]),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = P.grey92);
    final road = Paint()
      ..color = C.white
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, s.height * .27), Offset(s.width, s.height * .47), road..strokeWidth = 10);
    canvas.drawLine(Offset(s.width * .23, 0), Offset(s.width * .37, s.height), road..strokeWidth = 8);
    canvas.drawLine(Offset(0, s.height * .8), Offset(s.width, s.height * .63), road..strokeWidth = 6);
    canvas.drawLine(Offset(s.width * .71, 0), Offset(s.width * .6, s.height), road..strokeWidth = 7);
    final park = Paint()..color = P.lime85;
    canvas.drawRRect(RRect.fromLTRBR(s.width * .43, 10, s.width * .54, 38, const Radius.circular(R.sm)), park);
    canvas.drawRRect(RRect.fromLTRBR(s.width * .77, s.height * .66, s.width * .94, s.height * .9, const Radius.circular(R.sm)), park);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
