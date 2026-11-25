import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({super.key});
  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  final _keys = {for (final s in ['Slots', 'Facilities', 'Location', 'Ratings', 'Policies']) s: GlobalKey()};

  void _jump(String s) {
    final ctx = _keys[s]!.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOut, alignment: 0.05);
  }

  void _priceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFDADAD2), borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: Text('Price details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            CircleBtn(icon: Icons.close_rounded, size: 36, bg: C.bg, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          _billRow('Room price · ${app.stayLabel}', inr(app.gross - app.fees)),
          const SizedBox(height: 12),
          _billRow('Taxes & fees', inr(app.fees)),
          const SizedBox(height: 14),
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
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Stack(children: [
                    const PhotoPlaceholder(height: 300),
                    Positioned(left: 16, top: MediaQuery.of(context).padding.top + 10, child: const BackBtn()),
                    Positioned(
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 10,
                      child: Row(children: [
                        CircleBtn(
                          icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: saved ? const Color(0xFFE5484D) : C.ink,
                          tooltip: 'Save',
                          onTap: () => app.set(() => saved ? app.saved.remove(h.id) : app.saved.add(h.id)),
                        ),
                        const SizedBox(width: 8),
                        CircleBtn(icon: Icons.share_outlined, tooltip: 'Share', onTap: () => toast(context, 'Share link copied')),
                      ]),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(999)),
                        child: const Row(children: [
                          Icon(Icons.photo_library_outlined, size: 15),
                          SizedBox(width: 6),
                          Text('All photos', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          RatingBadge(h.rating, reviews: h.reviews),
                          if (h.topRated) ...[const SizedBox(width: 8), const Tag('Top rated', bg: C.lime, fg: C.ink)],
                        ]),
                        const SizedBox(height: 10),
                        Text(h.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
                        const SizedBox(height: 4),
                        Text('${h.area}, Chennai · ${h.distanceKm} km away', style: const TextStyle(fontSize: 13.5, color: C.muted)),
                      ]),
                    ),
                  ),
                ),
                SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(_keys.keys.toList(), _jump)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      WhiteCard(
                        key: _keys['Slots'],
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(app.fullDay ? 'Your stay' : 'Choose your slot', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                            Text(app.whenShort,
                                style: const TextStyle(fontSize: 12.5, color: C.muted)),
                          ]),
                          const SizedBox(height: 12),
                          if (app.fullDay)
                            StayTimeline(
                              inTime: app.inTimeLabel,
                              outTime: app.outTimeLabel,
                              inDate: app.inDateLabel,
                              outDate: app.outDateLabel,
                              slot: app.stayLabel,
                            )
                          else
                          Row(
                            children: [3, 6, 9, 12].map((hrs) {
                              final p = h.priceFor(hrs);
                              final on = hrs == app.slot;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: hrs == 12 ? 0 : 8),
                                  child: GestureDetector(
                                    onTap: p == null ? null : () => app.set(() => app.slot = hrs),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: on ? C.lime : (p == null ? C.bg : C.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                                      ),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text('$hrs hrs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? C.limeInk : C.muted2)),
                                        const SizedBox(height: 2),
                                        Text(p == null ? 'Full' : inr(p),
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p == null ? C.faint : C.ink)),
                                      ]),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const Icon(Icons.schedule_rounded, size: 16),
                              const SizedBox(width: 8),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF3F3F38)), children: [
                                const TextSpan(text: 'Check-out at '),
                                TextSpan(
                                    text: app.fullDay ? '11:00 AM, ${dateLabel(app.outDate)}' : '${hourLabel(app.checkOutHour)}${app.checkOutHour >= 24 ? ' (next day)' : ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
                              ])),
                            ]),
                          ),
                        ]),
                      ),
                      SectionLabel('Facilities', key: _keys['Facilities']),
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
                      SectionLabel('Location', key: _keys['Location']),
                      Material(
                        color: C.white,
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _MapPainter(),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                                  child: Center(child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle))),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(h.address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                              const SizedBox(width: 10),
                              PillBtn('Map', kind: BtnKind.outline, height: 38, fontSize: 13, onTap: () => toast(context, 'Opening Maps…')),
                            ]),
                          ),
                        ]),
                      ),
                      SectionLabel('Ratings & reviews', key: _keys['Ratings']),
                      WhiteCard(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(h.rating, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1)),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(Icons.star_rounded,
                                        size: 18, color: i < double.parse(h.rating).round() ? C.gold : const Color(0xFFE2E2DA))),
                              ),
                              const SizedBox(height: 4),
                              Text('Based on ${h.reviews} verified stays', style: const TextStyle(fontSize: 12.5, color: C.muted)),
                            ]),
                          ]),
                          const SizedBox(height: 16),
                          for (final b in const [['Comfort', 4.5], ['Cleanliness', 4.6], ['Value', 4.1]])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                SizedBox(width: 92, child: Text(b[0] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: (b[1] as double) / 5,
                                      minHeight: 8,
                                      backgroundColor: C.line,
                                      valueColor: const AlwaysStoppedAnimation(C.ink),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: 32,
                                    child: Text('${b[1]}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                              ]),
                            ),
                          const Divider(color: C.line, height: 20),
                          const Row(children: [
                            Expanded(child: Text('Priya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                            Text('★ 5 · 3-hr stay', style: TextStyle(fontSize: 12, color: C.muted2)),
                          ]),
                          const SizedBox(height: 6),
                          const Text('Clean room and quick check-in. Perfect for a few hours between trains.',
                              style: TextStyle(fontSize: 13.5, color: Color(0xFF3F3F38), height: 1.5)),
                        ]),
                      ),
                      SectionLabel('Good to know', key: _keys['Policies']),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.9,
                        children: const [
                          _Rule(Icons.badge_outlined, 'Local ID accepted', C.limeSoft),
                          _Rule(Icons.favorite_border_rounded, 'Couple friendly', C.limeSoft),
                          _Rule(Icons.verified_user_outlined, '18+ guests only', C.bg),
                          _Rule(Icons.smoke_free_rounded, 'No smoking or alcohol', C.redSoft),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const _Policies(),
                    ]),
                  ),
                ),
              ]),
            ),
            BottomBar(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: price == null ? 'Full' : inr(price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      TextSpan(text: app.fullDay ? ' / night' : ' / ${app.slot} hrs', style: const TextStyle(fontSize: 13, color: C.muted)),
                    ])),
                    GestureDetector(
                      onTap: _priceSheet,
                      child: const Text('Price details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
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
      Expanded(child: Text(l, style: const TextStyle(fontSize: 14, color: C.muted))),
      Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: vColor ?? C.ink)),
    ]);

Widget _totalBox(String v, {String label = 'To pay'}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('Inclusive of all taxes', style: TextStyle(fontSize: 12, color: C.limeInk)),
          ]),
        ),
        Text(v, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      ]),
    );

/// Shared helpers for other screens.
Widget billRow(String l, String v, {Color? vColor}) => _billRow(l, v, vColor: vColor);
Widget totalBox(String v, {String label = 'To pay'}) => _totalBox(v, label: label);

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final ValueChanged<String> onTap;
  _TabsDelegate(this.tabs, this.onTap);
  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;
  @override
  bool shouldRebuild(covariant _TabsDelegate old) => false;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: C.bg,
      padding: EdgeInsets.only(top: shrinkOffset > 0 || overlapsContent ? 0 : 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        children: tabs
            .map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    backgroundColor: C.white,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: () => onTap(t),
                  ),
                ))
            .toList(),
      ),
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
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
      ]);
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tile;
  const _Rule(this.icon, this.label, this.tile);
  @override
  Widget build(BuildContext context) => WhiteCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          IconTile(icon, bg: tile, size: 32, radius: 10),
          const SizedBox(height: 8),
          Text(label, maxLines: 2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: pol.entries
              .map((e) => ExpansionTile(
                    title: Text(e.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    iconColor: C.ink,
                    collapsedIconColor: C.ink,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: e.value
                        .map<Widget>((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(top: 7, right: 10),
                                  decoration: BoxDecoration(color: C.lime, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 1.2)),
                                ),
                                Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, color: Color(0xFF3F3F38), height: 1.5))),
                              ]),
                            ))
                        .toList()
                      ..addAll(e.key == 'Cancellation'
                          ? [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/cancel-policy'),
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text('Read full policy',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
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
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFEDEEE6));
    final road = Paint()
      ..color = C.white
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, s.height * .27), Offset(s.width, s.height * .47), road..strokeWidth = 10);
    canvas.drawLine(Offset(s.width * .23, 0), Offset(s.width * .37, s.height), road..strokeWidth = 8);
    canvas.drawLine(Offset(0, s.height * .8), Offset(s.width, s.height * .63), road..strokeWidth = 6);
    canvas.drawLine(Offset(s.width * .71, 0), Offset(s.width * .6, s.height), road..strokeWidth = 7);
    final park = Paint()..color = const Color(0xFFDDE8C8);
    canvas.drawRRect(RRect.fromLTRBR(s.width * .43, 10, s.width * .54, 38, const Radius.circular(6)), park);
    canvas.drawRRect(RRect.fromLTRBR(s.width * .77, s.height * .66, s.width * .94, s.height * .9, const Radius.circular(6)), park);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
