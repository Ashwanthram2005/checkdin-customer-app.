import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import 'filter_sort.dart';
import 'full_day_search.dart';
import 'maps.dart';

const _allStays = [...hotels, ...fullDayOnly];

class FullDayResultsScreen extends StatefulWidget {
  const FullDayResultsScreen({super.key});
  @override
  State<FullDayResultsScreen> createState() => _FullDayResultsScreenState();
}

class _FullDayResultsScreenState extends State<FullDayResultsScreen> {
  String? _area;
  double? _minRating;

  List<Hotel> get _list {
    var l = orderForPlace(_allStays.where((h) => (_area == null || h.area == _area) && (_minRating == null || double.parse(h.rating) >= _minRating!)).toList());
    switch (Filters.sort) {
      case 'Price: low to high':
        l.sort((a, b) => a.night.compareTo(b.night));
        break;
      case 'Price: high to low':
        l.sort((a, b) => b.night.compareTo(a.night));
        break;
      case 'Rating: high to low':
        l.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Distance: nearest first':
        l.sort((a, b) => kmFor(a).compareTo(kmFor(b)));
        break;
    }
    return l;
  }

  Future<void> _pickArea() async {
    final opts = <String?>[null, ..._allStays.map((h) => h.area).toSet()];
    final r = await showModalBottomSheet<List<String?>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OptionSheet(
        title: 'Location',
        options: opts.map((o) => o ?? 'All areas').toList(),
        selected: _area ?? 'All areas',
      ),
    );
    if (r != null) setState(() => _area = r.first == 'All areas' ? null : r.first);
  }

  Future<void> _pickRating() async {
    final r = await showModalBottomSheet<List<String?>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OptionSheet(
        title: 'Guest rating',
        options: const ['Any rating', '3.5+', '4.0+', '4.5+'],
        selected: _minRating == null ? 'Any rating' : '${_minRating!.toStringAsFixed(1)}+',
      ),
    );
    if (r != null) setState(() => _minRating = r.first == 'Any rating' ? null : double.parse(r.first!.replaceAll('+', '')));
  }

  Widget _chip(String label, IconData icon, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? C.inkBg : C.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? C.ink : C.border, width: 1.5),
            ),
            child: Row(children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? C.lime : C.ink)),
              const SizedBox(width: 5),
              Icon(icon, size: 17, color: active ? C.lime : C.ink),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = _list;
        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: list.isEmpty
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: C.inkBg,
                  foregroundColor: C.lime,
                  elevation: 4,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaysMapScreen(list: list, nightly: true))),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Map', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
          body: Column(children: [
            SheetHeader(
              child: Column(children: [
                Row(children: [
                  BackBtn(bg: C.bg, shadow: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: C.bg,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.maybePop(context),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(app.place ?? 'Chennai',
                                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 1),
                                GestureDetector(
                                  onTap: () => pickStayDates(context),
                                  child: Text(
                                      '${dateLabel(app.inDate)} – ${dateLabel(app.outDate)} · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.adults}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.5, color: C.muted)),
                                ),
                              ]),
                            ),
                            const CircleBtn(icon: Icons.edit_outlined, size: 34, shadow: false, tooltip: 'Edit search'),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _chip(_area ?? 'Location', Icons.keyboard_arrow_down_rounded, _area != null, _pickArea),
                    _chip(_minRating == null ? 'Ratings' : '${_minRating!.toStringAsFixed(1)}+ ★', Icons.keyboard_arrow_down_rounded,
                        _minRating != null, _pickRating),
                    _chip(Filters.count > 0 ? 'Filters · ${Filters.count}' : 'Filters', Icons.tune_rounded, Filters.count > 0, () async {
                      await showFilterSheet(context);
                      if (mounted) setState(() {});
                    }),
                    _chip('Sort', Icons.swap_vert_rounded, Filters.sort != 'Recommended', () async {
                      await showFilterSheet(context);
                      if (mounted) setState(() {});
                    }),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: Loader<List<Hotel>>(
                reloadKey: '${app.place}|${app.inDate}|${app.outDate}|${app.rooms}',
                load: () => api.searchHotels(place: app.place, fullDay: true),
                skeleton: const SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(), padding: EdgeInsets.fromLTRB(20, 16, 20, 28), child: SkHotelList()),
                builder: (context, _) => RefreshIndicator(
                  color: C.ink,
                  onRefresh: () async {
                    try {
                      await api.searchHotels(place: app.place, fullDay: true);
                    } on ApiError catch (e) {
                      if (context.mounted) toast(context, e.message);
                    }
                  },
                  child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  Text.rich(TextSpan(style: TextStyle(fontSize: 14, color: C.muted), children: [
                    const TextSpan(text: 'Showing '),
                    TextSpan(text: '${list.length} ${list.length == 1 ? 'stay' : 'stays'}', style: TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
                    TextSpan(text: ' for ${app.stayLabel} in ${_area ?? 'Chennai'}'),
                  ])),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(children: [
                        IconTile(Icons.search_off_rounded, bg: C.limeBg, size: 64, radius: 22),
                        const SizedBox(height: 14),
                        const Text('No stays match', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        PillBtn('Clear filters', kind: BtnKind.dark, height: 44, onTap: () => setState(() {
                              _area = null;
                              _minRating = null;
                            })),
                      ]),
                    ),
                  for (final h in list) Padding(padding: const EdgeInsets.only(bottom: 16), child: _NightCard(h)),
                ],
              ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  const _OptionSheet({required this.title, required this.options, required this.selected});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final o in options)
          InkWell(
            onTap: () => Navigator.pop(context, [o]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(children: [
                Expanded(child: Text(o, style: TextStyle(fontSize: 15, fontWeight: o == selected ? FontWeight.w800 : FontWeight.w500))),
                if (o == selected) Icon(Icons.check_circle_rounded, color: C.ink),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _NightCard extends StatefulWidget {
  final Hotel h;
  const _NightCard(this.h);
  @override
  State<_NightCard> createState() => _NightCardState();
}

class _NightCardState extends State<_NightCard> {
  final _page = PageController();
  int _i = 0;
  static const _shots = ['Room', 'Bathroom', 'Lobby'];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _open() {
    app.set(() => app.hotel = widget.h);
    Navigator.pushNamed(context, '/hotel');
  }

  void _quickView() {
    final h = widget.h;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            RatingBadge(h.rating, reviews: h.reviews),
          ]),
          const SizedBox(height: 4),
          Text(h.address, style: TextStyle(fontSize: 13, color: C.muted)),
          const SizedBox(height: 14),
          for (final r in [
            [Icons.login_rounded, 'Check-in from 12:00 PM · check-out by 11:00 AM'],
            [Icons.badge_outlined, 'Original photo ID needed for every guest'],
            [Icons.event_available_outlined, '50% refund if you cancel 5+ hrs before check-in'],
            [Icons.wifi_rounded, 'AC · Free Wi-Fi · Room service'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Icon(r[0] as IconData, size: 18, color: C.muted),
                const SizedBox(width: 10),
                Expanded(child: Text(r[1] as String, style: const TextStyle(fontSize: 13.5))),
              ]),
            ),
          const SizedBox(height: 6),
          PillBtn('View hotel', kind: BtnKind.dark, expand: true, onTap: () {
            Navigator.pop(ctx);
            _open();
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.h;
    final saved = app.saved.contains(h.id);
    final perNight = h.night * app.rooms;
    final taxes = (perNight * 0.05).round();
    final total = perNight * app.nights;
    Widget arrow(IconData icon, bool left) => Positioned(
          left: left ? 10 : null,
          right: left ? null : 10,
          top: 0,
          bottom: 0,
          child: Center(
            child: CircleBtn(
              icon: icon,
              size: 32,
              shadow: false,
              bg: const Color(0xCCFFFFFF),
              tooltip: left ? 'Previous photo' : 'Next photo',
              onTap: () => _page.animateToPage((_i + (left ? -1 : 1)).clamp(0, _shots.length - 1).toInt(),
                  duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
            ),
          ),
        );
    return Material(
      color: C.card,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 200,
            child: Stack(children: [
              PageView.builder(
                controller: _page,
                itemCount: _shots.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => PhotoPlaceholder(height: 200, label: _shots[i]),
              ),
              Positioned(left: 12, top: 12, child: RatingBadge(h.rating, reviews: h.reviews, dark: false)),
              Positioned(
                right: 12,
                top: 12,
                child: CircleBtn(
                  icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: saved ? const Color(0xFFE5484D) : C.ink,
                  size: 38,
                  shadow: false,
                  tooltip: 'Save',
                  onTap: () => app.set(() => saved ? app.saved.remove(h.id) : app.saved.add(h.id)),
                ),
              ),
              if (_i > 0) arrow(Icons.chevron_left_rounded, true),
              if (_i < _shots.length - 1) arrow(Icons.chevron_right_rounded, false),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var k = 0; k < _shots.length; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: k == _i ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: k == _i ? C.card : const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(3)),
                    ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 3),
                  Text('${h.area} · ${kmLabel(h)}', style: TextStyle(fontSize: 13, color: C.muted)),
                ]),
              ),
              GestureDetector(
                onTap: _quickView,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.info_outline_rounded, size: 15),
                    SizedBox(width: 4),
                    Text('Quick view', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(spacing: 14, runSpacing: 6, children: [
              for (final t in h.tags.take(2))
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      t.startsWith('Couple')
                          ? Icons.people_outline_rounded
                          : t.startsWith('Local')
                              ? Icons.badge_outlined
                              : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: C.muted),
                  const SizedBox(width: 5),
                  Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.tx(Color(0xFF3F3F38)))),
                ]),
            ]),
          ),
          Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 0), child: Divider(color: C.line, height: 1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: app.nights > 1
                    ? Text('${inr(total)} for ${app.stayLabel}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.green))
                    : Text('50% refund till 5 hrs before', style: TextStyle(fontSize: 12, color: C.green, fontWeight: FontWeight.w600)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: inr(perNight), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  TextSpan(text: ' /night · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'}', style: TextStyle(fontSize: 12, color: C.muted)),
                ])),
                Text('+${inr(taxes)} taxes', style: TextStyle(fontSize: 12, color: C.muted2)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
