import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _offer = 0;

  Widget _title(String t, {String? link, VoidCallback? onLink}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4))),
          if (link != null)
            GestureDetector(onTap: onLink, child: Text(link, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.muted))),
        ]),
      );

  Widget _stayToggle(bool full) {
    Widget btn(bool forFull, IconData icon, String label) {
      final on = app.fullDay == forFull;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            app.set(() => app.fullDay = forFull);
            if (forFull) Navigator.pushNamed(context, '/fullday');
          },
          child: Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 64,
              decoration: BoxDecoration(
                color: on ? C.lime : C.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? C.lime : C.border, width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            if (forFull)
              Positioned(
                top: -10,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(999)),
                  child: const Text('NEW', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
          ]),
        ),
      );
    }

    return Row(children: [
      btn(false, Icons.bolt_rounded, 'Hourly stay'),
      const SizedBox(width: 10),
      btn(true, Icons.nightlight_outlined, 'Full-day stay'),
    ]);
  }

  Widget _offerCard(bool lime) {
    final fg = lime ? C.ink : C.white;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: lime ? C.lime : C.ink, borderRadius: BorderRadius.circular(24)),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -60,
          bottom: -80,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lime ? const Color(0x66FFFFFF) : Colors.transparent,
              border: lime ? null : Border.all(color: const Color(0xFF222222), width: 22),
            ),
          ),
        ),
        if (lime)
          Positioned(
            right: 6,
            top: 22,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                width: 92,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(12)),
                child: const Text('25%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.lime)),
              ),
            ),
          ),
        SizedBox(
          width: 210,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lime ? 'FIRST STAY OFFER' : 'COMING BACK?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: lime ? C.limeInk : C.faint)),
            const SizedBox(height: 6),
            Text(lime ? '25% off your first hourly stay' : 'Get 8% back on your next booking',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15, color: fg)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: lime ? C.white : C.lime, borderRadius: BorderRadius.circular(999)),
              child: Text(lime ? 'CODE · NEWSTAY' : 'CODE · BACK8',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: C.ink)),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const areaInfo = [
      ['T. Nagar', '24 stays', '₹699'],
      ['OMR', '18 stays', '₹749'],
      ['Porur', '9 stays', '₹599'],
      ['Velachery', '12 stays', '₹649'],
      ['Anna Nagar', '7 stays', '₹799'],
    ];
    const recent = [
      ['T. Nagar', '3 hrs · Wed, 9 AM', 3],
      ['Porur', '6 hrs · Fri, 2 PM', 6],
    ];
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        extendBody: true,
        bottomNavigationBar: const BottomNav(current: 'Home'),
        body: ListView(padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 14, bottom: 120), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Image.asset('assets/logo.png', height: 34),
              const Spacer(),
              Stack(clipBehavior: Clip.none, children: [
                CircleBtn(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onTap: () => Navigator.pushNamed(context, '/notifications')),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: C.red, shape: BoxShape.circle, border: Border.all(color: C.white, width: 1.5)),
                  ),
                ),
              ]),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/account'),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle),
                  child: Text(app.name.isEmpty ? 'A' : app.name[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hi ${app.name.isEmpty ? 'there' : app.name},', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.muted)),
              const SizedBox(height: 4),
              const Highlight(before: 'Need a room for ', marked: 'a few hours?', size: 28, height: 1.2),
              const SizedBox(height: 18),
              _stayToggle(app.fullDay),
              const SizedBox(height: 14),
              Material(
                color: C.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.pushNamed(context, app.fullDay ? '/fullday' : '/search'),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x12111111), blurRadius: 24, offset: Offset(0, 8))],
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(app.fullDay ? 'Search full-day hotels…' : 'Search hourly hotels…',
                            style: const TextStyle(fontSize: 15.5, color: C.muted)),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.arrow_forward_rounded, color: C.lime, size: 20),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          if (app.checkedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Material(
                color: C.ink,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pushNamed(context, '/live'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.hotel_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Staying at ${app.hotel.name}', style: const TextStyle(color: C.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text('Check-out ${hourLabel(app.stayEnd.hour)} · tap to extend', style: const TextStyle(color: C.faint, fontSize: 12.5)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: C.lime),
                    ]),
                  ),
                ),
              ),
            ),
          _title('Continue your search'),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => WhiteCard(
                radius: 16,
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                onTap: () {
                  app.set(() {
                    app.place = recent[i][0] as String;
                    app.slot = recent[i][2] as int;
                    app.fullDay = false;
                  });
                  Navigator.pushNamed(context, '/date');
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const IconTile(Icons.schedule_rounded, size: 36),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(recent[i][0] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(recent[i][1] as String, style: const TextStyle(fontSize: 12, color: C.muted)),
                  ]),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 160,
            child: PageView(
              controller: PageController(viewportFraction: 0.92),
              onPageChanged: (i) => setState(() => _offer = i),
              children: [_offerCard(true), _offerCard(false)],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == _offer ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: i == _offer ? C.ink : const Color(0xFFCFCFC7), borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
          _title('Popular in Chennai', link: 'See all', onLink: () => Navigator.pushNamed(context, '/search')),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: areaInfo.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 140,
                child: WhiteCard(
                  radius: 20,
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    app.set(() => app.place = areaInfo[i][0]);
                    Navigator.pushNamed(context, '/search');
                  },
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(areaInfo[i][0], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2))),
                      const IconTile(Icons.north_east_rounded, size: 26, radius: 13),
                    ]),
                    const Spacer(),
                    Text(areaInfo[i][1], style: const TextStyle(fontSize: 12, color: C.muted)),
                    Text('from ${areaInfo[i][2]}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
          _title('Top rated near you', link: 'See all', onLink: () => Navigator.pushNamed(context, '/search')),
          SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: hotels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final h = hotels[i];
                return SizedBox(
                  width: 230,
                  child: Material(
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
                          const PhotoPlaceholder(height: 120, label: ''),
                          Positioned(left: 10, top: 10, child: RatingBadge(h.rating, dark: false)),
                        ]),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            Text('${h.area} · ${h.distanceKm} km', style: const TextStyle(fontSize: 12.5, color: C.muted)),
                            const SizedBox(height: 8),
                            Text.rich(TextSpan(children: [
                              TextSpan(text: inr(h.prices.first ?? 0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const TextSpan(text: ' / 3 hrs', style: TextStyle(fontSize: 12, color: C.muted)),
                            ])),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: WhiteCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => Navigator.pushNamed(context, '/refer'),
              child: const Row(children: [
                IconTile(Icons.card_giftcard_rounded, bg: Color(0xFFFFF1C7)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Invite friends, earn ₹100', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('When they book their first stay', style: TextStyle(fontSize: 12, color: C.muted)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
