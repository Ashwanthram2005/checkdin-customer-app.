import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import 'maps.dart';
import 'states.dart';
import 'filter_sort.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Set<String> _on = {};
  static const _chips = ['Under ₹1,000', 'Rating 4+', 'Couple friendly', 'Local ID accepted'];

  List<Hotel>? _hotels;

  Future<List<Hotel>> _fetch() async {
    final r = await api.searchHotels(place: app.place, fullDay: false);
    _hotels = r;
    return r;
  }

  Future<void> _refresh() async {
    try {
      await _fetch();
      if (mounted) setState(() {});
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = orderForPlace((_hotels ?? hotels).where((h) {
          if (_on.contains('Under ₹1,000') && (h.prices.first ?? 9999) >= 1000) return false;
          if (_on.contains('Rating 4+') && double.parse(h.rating) < 4) return false;
          if (_on.contains('Couple friendly') && !h.tags.contains('Couple friendly')) return false;
          if (_on.contains('Local ID accepted') && !h.tags.contains('Local ID accepted')) return false;
          if (Filters.distance != null) {
            final max = double.tryParse(Filters.distance!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 99;
            if (kmFor(h) > max) return false;
          }
          return true;
        }).toList());
        int price(Hotel h) => h.priceFor(app.slot) ?? 99999;
        switch (Filters.sort) {
          case 'Price: low to high':
            list.sort((a, b) => price(a).compareTo(price(b)));
            break;
          case 'Price: high to low':
            list.sort((a, b) => price(b).compareTo(price(a)));
            break;
          case 'Rating: high to low':
            list.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'Distance: nearest first':
            list.sort((a, b) => kmFor(a).compareTo(kmFor(b)));
            break;
        }
        final place = app.place ?? 'Chennai';
        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: list.isEmpty
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: C.inkBg,
                  foregroundColor: C.lime,
                  elevation: 4,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaysMapScreen(list: list))),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Map', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
          body: Column(children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 14, bottom: 14),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x0F111111), blurRadius: 24, offset: Offset(0, 8))],
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    BackBtn(bg: C.bg, shadow: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => popTo(context, '/search'),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('$place, Chennai'.replaceAll('Chennai, Chennai', 'Chennai'),
                                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                Text('${dateLabel(app.date)} · ${hourLabel(app.checkInHour, short: true)} · ${app.slot} hrs',
                                    style: TextStyle(fontSize: 12, color: C.muted)),
                              ]),
                            ),
                            const CircleBtn(icon: Icons.edit_outlined, size: 32, shadow: false, tooltip: 'Edit search'),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await showFilterSheet(context);
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Filters.count > 0 ? C.inkBg : C.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: C.ink, width: 1.5),
                          ),
                          child: Row(children: [
                            Icon(Icons.tune_rounded, size: 16, color: Filters.count > 0 ? C.lime : C.ink),
                            const SizedBox(width: 6),
                            Text(Filters.count > 0 ? 'Filters · ${Filters.count}' : 'Filters',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Filters.count > 0 ? C.lime : C.ink)),
                          ]),
                        ),
                      ),
                      for (final c in _chips)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _on.contains(c) ? _on.remove(c) : _on.add(c)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _on.contains(c) ? C.limeBg : C.card,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _on.contains(c) ? C.lime : C.border, width: 1.5),
                              ),
                              child: Text(c, style: TextStyle(fontSize: 13, fontWeight: _on.contains(c) ? FontWeight.w800 : FontWeight.w600)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Loader<List<Hotel>>(
                reloadKey: '${app.place}|${app.date}|${app.hour}|${app.rooms}',
                load: _fetch,
                skeleton: const SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(), padding: EdgeInsets.fromLTRB(20, 16, 20, 28), child: SkHotelList()),
                builder: (context, _) => RefreshIndicator(
                  color: C.ink,
                  onRefresh: _refresh,
                  child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(children: [
                    Expanded(
                        child: Text('${list.length} ${list.length == 1 ? 'stay' : 'stays'} near $place',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                    Text('Prices for ${app.slot} hrs', style: TextStyle(fontSize: 12.5, color: C.muted)),
                  ]),
                ),
                const SizedBox(height: 14),
                for (final h in list) ...[_HotelCard(h), const SizedBox(height: 16)],
                if (list.isEmpty)
                  EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No stays match',
                    body: 'Nothing near $place fits ${_on.length > 1 ? 'all ${_on.length} filters' : 'this filter'} for ${app.slot} hrs. Remove a filter or try a longer slot.',
                    primary: 'Clear filters',
                    onPrimary: () => setState(() => _on.clear()),
                    secondary: 'Try a full-day stay',
                    onSecondary: () {
                      app.set(() => app.fullDay = true);
                      Navigator.pushNamed(context, '/fullday');
                    },
                  ),
              ]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel h;
  const _HotelCard(this.h);

  @override
  Widget build(BuildContext context) {
    final saved = app.saved.contains(h.id);
    void open() {
      app.set(() => app.hotel = h);
      Navigator.pushNamed(context, '/hotel');
    }

    return Material(
      color: C.card,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            const PhotoPlaceholder(height: 180),
            Positioned(
              left: 12,
              top: 12,
              child: Row(children: [
                RatingBadge(h.rating, reviews: h.reviews, dark: false),
                if (h.topRated) ...[const SizedBox(width: 6), Tag('Top rated', bg: C.limeBg, fg: C.ink)],
              ]),
            ),
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
          ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Text('${h.area} · ${kmLabel(h)}', style: TextStyle(fontSize: 13, color: C.muted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: h.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(8)),
                          child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.tx(Color(0xFF3F3F38)))),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [3, 6, 9, 12].map((hrs) {
                  final p = h.priceFor(hrs);
                  final off = p == null;
                  final sel = hrs == app.slot && !off;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: hrs == 12 ? 0 : 6),
                      child: GestureDetector(
                        onTap: off
                            ? null
                            : () {
                                app.set(() => app.slot = hrs);
                                open();
                              },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: sel ? C.limeBg : (off ? C.bg : C.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: sel ? C.lime : (off ? C.bg : C.border), width: 1.5),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(off ? 'Full' : inr(p ?? 0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: off ? C.faint : C.ink)),
                            Text('$hrs hrs',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? C.limeInk : (off ? const Color(0xFFC9C9C1) : C.muted2))),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
