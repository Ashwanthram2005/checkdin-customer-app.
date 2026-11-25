import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _area = 'All';

  void _remove(Hotel h) {
    app.set(() => app.saved.remove(h.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${h.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: C.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(label: 'Undo', textColor: C.lime, onPressed: () => app.set(() => app.saved.add(h.id))),
      ));
  }

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
          body: ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 120), children: [
            const Align(alignment: Alignment.centerLeft, child: BackBtn()),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Saved', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  Text(
                      left.isEmpty
                          ? 'Hotels you love, in one place'
                          : '${left.length} ${left.length > 1 ? 'hotels' : 'hotel'} for your next stay',
                      style: const TextStyle(fontSize: 13.5, color: C.muted)),
                ]),
              ),
              if (left.isNotEmpty)
                PillBtn('Find more',
                    kind: BtnKind.outline,
                    height: 40,
                    fontSize: 13,
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
                    decoration: BoxDecoration(color: C.lime, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 3)),
                    child: const Icon(Icons.favorite_rounded, size: 30),
                  ),
                  const SizedBox(height: 20),
                  const Text('No saved stays yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Tap the heart on any hotel to keep it here for your next booking.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: C.muted, height: 1.5)),
                  const SizedBox(height: 18),
                  PillBtn('Explore stays', kind: BtnKind.dark, onTap: () => Navigator.pushNamed(context, '/search')),
                ]),
              )
            else ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: zones.map((z) {
                    final on = z == _area;
                    final n = z == 'All' ? left.length : left.where((h) => h.area == z).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _area = z),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on ? C.lime : C.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                          ),
                          child: Text('$z · $n', style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              WhiteCard(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const IconTile(Icons.notifications_none_rounded, bg: C.limeSoft, size: 36),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Price-drop alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('On WhatsApp, for your saved hotels', style: TextStyle(fontSize: 12, color: C.muted)),
                    ]),
                  ),
                  BrandSwitch(value: app.priceAlerts, onChanged: (v) => app.set(() => app.priceAlerts = v)),
                ]),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.66,
                children: shown.map((h) {
                  return Material(
                    color: C.white,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        app.set(() => app.hotel = h);
                        Navigator.pushNamed(context, '/hotel');
                      },
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(children: [
                          const PhotoPlaceholder(height: 128, label: ''),
                          Positioned(left: 8, top: 8, child: RatingBadge(h.rating, dark: false)),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleBtn(
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFFE5484D),
                              size: 34,
                              shadow: false,
                              tooltip: 'Remove from saved',
                              onTap: () => _remove(h),
                            ),
                          ),
                          if (h.id == 'gr')
                            const Positioned(left: 8, bottom: 8, child: Tag('↓ ₹100 cheaper', bg: C.lime, fg: C.ink)),
                        ]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(h.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.25)),
                              const SizedBox(height: 3),
                              Text('${h.area} · ${h.distanceKm} km', style: const TextStyle(fontSize: 12, color: C.muted)),
                              const Spacer(),
                              Row(children: [
                                Expanded(
                                  child: Text.rich(TextSpan(children: [
                                    TextSpan(text: inr(h.prices.first ?? 0), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                    const TextSpan(text: ' /3h', style: TextStyle(fontSize: 11.5, color: C.muted)),
                                  ])),
                                ),
                                const IconTile(Icons.arrow_forward_rounded, bg: C.ink, fg: C.lime, size: 30, radius: 15),
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
        );
      },
    );
  }
}
