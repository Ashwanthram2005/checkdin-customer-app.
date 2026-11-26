import 'package:flutter/material.dart';

import '../state.dart';
import '../avatar.dart';
import '../theme.dart';
import 'states.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  Widget _stepper(String label, String sub, int value, int min, int max, ValueChanged<int> onChange, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
          CircleBtn(
              icon: Icons.remove_rounded,
              size: 34,
              shadow: false,
              bg: C.bg,
              tooltip: 'Less',
              iconColor: value > min ? C.ink : C.faint,
              onTap: value > min ? () => onChange(value - 1) : null),
          SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          CircleBtn(
              icon: Icons.add_rounded,
              size: 34,
              shadow: false,
              bg: value < max ? C.limeBg : C.bg,
              tooltip: 'More',
              iconColor: value < max ? C.ink : C.faint,
              onTap: value < max ? () => onChange(value + 1) : null),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final place = app.place;
        final recent = [
          ['T. Nagar', '13 Nov · 3 hrs', 3],
          ['Porur', '10 Nov · 6 hrs', 6],
          ['OMR', '2 Nov · 12 hrs', 12],
        ];
        return Scaffold(
          body: Column(children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
                children: [
                  Row(children: [
                    const BackBtn(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SegmentPill(
                        options: const ['Hourly stay', 'Full-day stay'],
                        selected: 0,
                        height: 38,
                        onChanged: (i) {
                          if (i == 1) {
                            app.set(() => app.fullDay = true);
                            Navigator.pushReplacementNamed(context, '/fullday');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/account'),
                      child: const Avatar(size: 44),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const Highlight(before: 'Where do you\nwant to ', marked: 'check in?', size: 28, height: 1.2),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        final r = await Navigator.pushNamed(context, '/picker');
                        if (r is String) app.set(() => app.place = r);
                      },
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: place != null ? C.ink : C.white, width: 1.5),
                          boxShadow: const [BoxShadow(color: Color(0x0F111111), blurRadius: 20, offset: Offset(0, 6))],
                        ),
                        child: Row(children: [
                          Icon(Icons.search_rounded, color: C.ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(place ?? 'Search area, landmark or hotel',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: place != null ? FontWeight.w700 : FontWeight.w400,
                                    color: place != null ? C.ink : const Color(0xFF7C7C74))),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  WhiteCard(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: Border.all(color: place == 'Current location' ? C.ink : C.white, width: 1.5),
                    onTap: () async {
                      if (await useMyLocation(context)) app.set(() => app.place = 'Current location');
                    },
                    child: Row(children: [
                      IconTile(Icons.near_me_rounded, bg: C.limeSoft, size: 38, radius: 19),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Use my current location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Find stays near you', style: TextStyle(fontSize: 12.5, color: C.muted)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A92)),
                    ]),
                  ),
                  const SectionLabel('How many hours?'),
                  Row(
                    children: [3, 6, 9, 12].map((h) {
                      final on = app.slot == h;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: h == 12 ? 0 : 8),
                          child: GestureDetector(
                            onTap: () => app.set(() => app.slot = h),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 56,
                              decoration: BoxDecoration(
                                color: on ? C.limeBg : C.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                              ),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('$h', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.1)),
                                Text('hours', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: C.muted)),
                              ]),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SectionLabel('Rooms & guests'),
                  WhiteCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Column(children: [
                      _stepper('Rooms', 'Up to 3 guests per room', app.rooms, 1, 5, (v) => app.set(() {
                            app.rooms = v;
                            if (app.adults < v) app.adults = v;
                            if (app.adults > v * 3) app.adults = v * 3;
                          })),
                      _stepper('Guests', 'Aged 12 and above', app.adults, app.rooms, app.rooms * 3, (v) => app.set(() => app.adults = v)),
                      _stepper('Children', 'Below 5 years, stay free', app.kids, 0, 2, (v) => app.set(() => app.kids = v), last: true),
                    ]),
                  ),
                  const SectionLabel('Popular in Chennai'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: areas.map((a) {
                      final on = place == a;
                      return GestureDetector(
                        onTap: () => app.set(() => app.place = a),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: on ? C.limeBg : C.card, borderRadius: BorderRadius.circular(999)),
                          child: Text(a, style: TextStyle(fontSize: 13.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SectionLabel('Recent searches'),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final r = recent[i];
                        return GestureDetector(
                          onTap: () => app.set(() {
                            app.place = r[0] as String;
                            app.slot = r[2] as int;
                            app.fullDay = false;
                          }),
                          child: Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(r[0] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(r[1] as String, style: TextStyle(fontSize: 12.5, color: C.muted)),
                                ]),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 20),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            BottomBar(
              child: place == null
                  ? const PillBtn('Continue', expand: true)
                  : Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(place, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('${app.slot}-hour stay · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.guestsLabel}',
                              style: TextStyle(fontSize: 12.5, color: C.muted)),
                        ]),
                      ),
                      PillBtn('Continue', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pushNamed(context, '/date')),
                    ]),
            ),
          ]),
        );
      },
    );
  }
}
