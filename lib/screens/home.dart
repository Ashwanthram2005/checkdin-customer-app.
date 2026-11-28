import 'package:flutter/material.dart';

import '../state.dart';
import '../avatar.dart';
import '../photos.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _offer = 0;

  Widget _title(String t, {String? link, VoidCallback? onLink}) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.x3, Sp.xl, Sp.md),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(t, style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, letterSpacing: -0.4))),
          if (link != null)
            GestureDetector(onTap: onLink, child: Text(link, style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.muted))),
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
                color: on ? C.limeBg : C.card,
                borderRadius: BorderRadius.circular(R.xl),
                border: Border.all(color: on ? C.lime : C.border, width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: Ic.md),
                const SizedBox(width: Sp.md),
                Text(label, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
              ]),
            ),
            if (forFull)
              Positioned(
                top: -10,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xxs),
                  decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(R.pill)),
                  child: const Text('NEW', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
          ]),
        ),
      );
    }

    return Row(children: [
      btn(false, Icons.bolt_rounded, 'Hourly stay'),
      const SizedBox(width: Sp.md),
      btn(true, Icons.nightlight_rounded, 'Full-day stay'),
    ]);
  }

  Widget _offerCard(bool lime) {
    final fg = lime ? C.ink : C.white;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/offers'),
      child: _offerBody(lime, fg),
    );
  }

  Widget _offerBody(bool lime, Color fg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Sp.sm),
      padding: const EdgeInsets.all(Sp.xl),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: lime ? C.limeBg : C.inkBg, borderRadius: BorderRadius.circular(R.xl)),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -60,
          bottom: -80,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lime ? P.whiteA40 : Colors.transparent,
              border: lime ? null : Border.all(color: P.grey13, width: 22),
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
                decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.md)),
                child: Text('25%', style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, color: C.lime)),
              ),
            ),
          ),
        SizedBox(
          width: 210,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lime ? 'FIRST STAY OFFER' : 'COMING BACK?',
                style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: lime ? C.limeInk : C.faint)),
            const SizedBox(height: Sp.sm),
            Text(lime ? '25% off your first hourly stay' : 'Get 8% back on your next booking',
                style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15, color: fg)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
              decoration: BoxDecoration(color: lime ? C.card : C.limeBg, borderRadius: BorderRadius.circular(R.pill)),
              child: Text(lime ? 'CODE · NEWSTAY' : 'CODE · BACK8',
                  style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: C.ink)),
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
        body: Column(children: [
          Container(
            color: C.bg,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 14, bottom: 12),
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
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
              const SizedBox(width: Sp.sm),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/account'),
                child: const Avatar(size: 44),
              ),
            ]),
          ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, 0),
                child: _stayToggle(app.fullDay),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(top: Sp.sm, bottom: 120), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hi ${app.name.isEmpty ? 'there' : app.name},', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600, color: C.muted)),
              const SizedBox(height: Sp.xs),
              const Highlight(before: 'Need a room for ', marked: 'a few hours?', size: 28, height: 1.2),
              const SizedBox(height: Sp.lg),
              Material(
                color: C.card,
                borderRadius: BorderRadius.circular(R.lg),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(R.lg),
                  onTap: () => Navigator.pushNamed(context, app.fullDay ? '/fullday' : '/search'),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.sm, Sp.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.lg),
                      boxShadow: const [BoxShadow(color: P.inkA7, blurRadius: 24, offset: Offset(0, 8))],
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Text(app.fullDay ? 'Search full-day hotels…' : 'Search hourly hotels…',
                            style: TextStyle(fontSize: Fs.lg, color: C.muted)),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.lg)),
                        child: Icon(Icons.arrow_forward_rounded, color: C.lime, size: Ic.md),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          if (app.checkedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, 0),
              child: Material(
                color: C.inkBg,
                borderRadius: BorderRadius.circular(R.xl),
                child: InkWell(
                  borderRadius: BorderRadius.circular(R.xl),
                  onTap: () => Navigator.pushNamed(context, '/live'),
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.lg),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.lg)),
                        child: const Icon(Icons.hotel_rounded),
                      ),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Staying at ${app.hotel.name}', style: TextStyle(color: C.white, fontWeight: FontWeight.w700, fontSize: Fs.md)),
                          const SizedBox(height: Sp.xxs),
                          Text('Check-out ${hourLabel(app.stayEnd.hour)} · tap to extend', style: TextStyle(color: C.faint, fontSize: Fs.sm)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: C.lime),
                    ]),
                  ),
                ),
              ),
            ),
          Loader<void>(
            load: api.homeFeed,
            cacheKey: 'home',
            skeleton: const SkHome(),
            builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _title('Continue your search'),
          SizedBox(
            height: 62,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.1,
              child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: Sp.md),
              itemBuilder: (_, i) => WhiteCard(
                expand: false,
                radius: R.lg,
                padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.lg, Sp.sm),
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
                  const SizedBox(width: Sp.md),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(recent[i][0] as String, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    Text(recent[i][1] as String, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  ]),
                ]),
              ),
            ),
            ),
          ),
          const SizedBox(height: Sp.xxl),
          SizedBox(
            height: 160,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.1,
              child: PageView(
              controller: PageController(viewportFraction: 0.92),
              onPageChanged: (i) => setState(() => _offer = i),
              children: [_offerCard(true), _offerCard(false)],
            ),
            ),
          ),
          const SizedBox(height: Sp.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: Sp.xxs),
                width: i == _offer ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: i == _offer ? C.inkBg : C.tint(P.dotIdle), borderRadius: BorderRadius.circular(R.pill)),
              ),
            ),
          ),
          _title('Popular in Chennai', link: 'See all', onLink: () => Navigator.pushNamed(context, '/search')),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
              itemCount: areaInfo.length,
              separatorBuilder: (_, __) => const SizedBox(width: Sp.md),
              itemBuilder: (_, i) => SizedBox(
                width: 140,
                child: WhiteCard(
                  radius: R.xl,
                  padding: const EdgeInsets.all(Sp.lg),
                  onTap: () {
                    app.set(() => app.place = areaInfo[i][0]);
                    Navigator.pushNamed(context, '/search');
                  },
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(areaInfo[i][0], style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, height: 1.2))),
                      const IconTile(Icons.north_east_rounded, size: 26, radius: 13),
                    ]),
                    const Spacer(),
                    Text(areaInfo[i][1], style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    Text('from ${areaInfo[i][2]}', style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
          _title('Top rated near you', link: 'See all', onLink: () => Navigator.pushNamed(context, '/search')),
          SizedBox(
            height: 218,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.1,
              child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
              itemCount: hotels.length,
              separatorBuilder: (_, __) => const SizedBox(width: Sp.md),
              itemBuilder: (_, i) {
                final h = hotels[i];
                return SizedBox(
                  width: 230,
                  child: Material(
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
                          NetPhoto(coverOf(h), height: 120, w: 500),
                          Positioned(left: 10, top: 10, child: RatingBadge(h.rating, dark: false)),
                        ]),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                            Text('${h.area} · ${h.distanceKm} km', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                            const SizedBox(height: Sp.sm),
                            Text.rich(TextSpan(children: [
                              TextSpan(text: inr(h.prices.first ?? 0), style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                              TextSpan(text: ' / 3 hrs', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xxl, Sp.xl, 0),
            child: WhiteCard(
              radius: R.xl,
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
              onTap: () => Navigator.pushNamed(context, '/refer'),
              child: Row(children: [
                IconTile(Icons.card_giftcard_rounded, bg: C.tint(P.amberSoft)),
                SizedBox(width: Sp.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Invite friends, earn ₹100', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    Text('When they book their first stay', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
            ]),
          ),
        ]),
          ),
        ]),
      ),
    );
  }
}
