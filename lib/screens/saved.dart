import 'package:flutter/material.dart';

import '../state.dart';
import '../photos.dart';
import '../theme.dart';
import 'gallery.dart' show hotelHeroTag;
import '../optimistic.dart';
import '../loading.dart';
import '../api/api.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _area = 'All';

  void _remove(Hotel h) => toggleSaved(context, h);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final left = hotels.where((h) => app.saved.contains(h.id)).toList();
        final zones = ['All', ...{for (final h in left) h.area}];
        if (!zones.contains(_area)) _area = 'All';
        final shown = left.where((h) => _area == 'All' || h.area == _area).toList();
        return Scaffold(
          extendBody: true,
          bottomNavigationBar: const BottomNav(current: 'Saved'),
          body: Loader<void>(
        load: api.savedHotels,
        cacheKey: 'saved',
        skeleton: const SkPage(title: 'Saved', child: SkHotelList(count: 2)),
        builder: (context, _) => ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 120), children: [
            const Align(alignment: Alignment.centerLeft, child: BackBtn()),
            const SizedBox(height: Sp.lg),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Saved', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  Text(
                      left.isEmpty
                          ? 'Hotels you love, in one place'
                          : '${left.length} ${left.length > 1 ? 'hotels' : 'hotel'} for your next stay',
                      style: TextStyle(fontSize: Fs.base, color: C.muted)),
                ]),
              ),
              if (left.isNotEmpty)
                PillBtn('Find more',
                    kind: BtnKind.outline,
                    height: 40,
                    fontSize: Fs.base,
                    icon: Icons.search_rounded,
                    trailingIcon: false,
                    onTap: () => Navigator.pushNamed(context, '/search')),
            ]),
            if (left.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 90),
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 3)),
                    child: const Icon(Icons.favorite_rounded, size: Ic.xl),
                  ),
                  const SizedBox(height: Sp.xl),
                  const Text('No saved stays yet', style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Sp.sm),
                  Text('Tap the heart on any hotel to keep it here for your next booking.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
                  const SizedBox(height: Sp.lg),
                  PillBtn('Explore stays', kind: BtnKind.dark, onTap: () => Navigator.pushNamed(context, '/search')),
                ]),
              )
            else ...[
              const SizedBox(height: Sp.lg),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: zones.map((z) {
                    final on = z == _area;
                    final n = z == 'All' ? left.length : left.where((h) => h.area == z).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: Sp.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => _area = z),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on ? C.limeBg : C.card,
                            borderRadius: BorderRadius.circular(R.pill),
                            border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                          ),
                          child: Text('$z · $n', style: TextStyle(fontSize: Fs.base, fontWeight: on ? FontWeight.w700 : FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: Sp.lg),
              WhiteCard(
                radius: R.lg,
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
                child: Row(children: [
                  IconTile(Icons.notifications_none_rounded, bg: C.limeSoft, size: 36),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Price-drop alerts', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      Text('On WhatsApp, for your saved hotels', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                  BrandSwitch(value: app.priceAlerts, onChanged: (v) => app.set(() => app.priceAlerts = v)),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.66,
                children: shown.map((h) {
                  return Material(
                    color: C.card,
                    borderRadius: BorderRadius.circular(R.xl),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        app.set(() => app.hotel = h);
                        Navigator.pushNamed(context, '/hotel');
                      },
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(children: [
                          Hero(tag: hotelHeroTag(h.id), child: NetPhoto(coverOf(h), height: 128, w: 500)),
                          Positioned(left: 8, top: 8, child: RatingBadge(h.rating, dark: false)),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleBtn(
                              icon: Icons.favorite_rounded,
                              iconColor: P.redBright,
                              size: 34,
                              shadow: false,
                              tooltip: 'Remove from saved',
                              onTap: () => _remove(h),
                            ),
                          ),
                          if (h.id == 'gr')
                            Positioned(left: 8, bottom: 8, child: Tag('↓ ₹100 cheaper', bg: C.limeBg, fg: C.ink)),
                        ]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, Sp.md),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(h.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, height: 1.25)),
                              const SizedBox(height: Sp.xs),
                              Text('${h.area} · ${h.distanceKm} km', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                              const Spacer(),
                              Row(children: [
                                Expanded(
                                  child: Text.rich(TextSpan(children: [
                                    TextSpan(text: inr(h.prices.first ?? 0), style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                                    TextSpan(text: ' /3h', style: TextStyle(fontSize: Fs.xs, color: C.muted)),
                                  ])),
                                ),
                                IconTile(Icons.arrow_forward_rounded, bg: C.inkBg, fg: C.lime, size: 30, radius: 15),
                              ]),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ]),
      ),
        );
      },
    );
  }
}
