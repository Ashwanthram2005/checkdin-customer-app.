import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

/// Shared date-range picker in brand colours.
Future<void> pickStayDates(BuildContext context) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final r = await showDateRangePicker(
    context: context,
    firstDate: today,
    lastDate: today.add(const Duration(days: 180)),
    initialDateRange: DateTimeRange(start: app.inDate.isBefore(today) ? today : app.inDate, end: app.outDate.isBefore(today.add(const Duration(days: 1))) ? today.add(const Duration(days: 1)) : app.outDate),
    helpText: 'Select check-in & check-out',
    saveText: 'Done',
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: C.ink, onPrimary: C.lime, secondary: C.lime, secondaryContainer: C.limeSoft),
        datePickerTheme: DatePickerThemeData(rangeSelectionBackgroundColor: C.limeSoft, headerBackgroundColor: C.bg),
      ),
      child: child!,
    ),
  );
  if (r == null) return;
  app.set(() {
    app.inDate = r.start;
    app.outDate = r.end.difference(r.start).inDays < 1 ? r.start.add(const Duration(days: 1)) : r.end;
  });
}

class FullDaySearchScreen extends StatelessWidget {
  const FullDaySearchScreen({super.key});

  static const _popular = [
    ['T. Nagar', Icons.shopping_bag_rounded, P.orange86],
    ['OMR', Icons.business_rounded, P.blue87],
    ['Chennai Airport', Icons.flight_takeoff_rounded, P.lime85],
    ['Guindy', Icons.apartment_rounded, P.amber85],
    ['Egmore', Icons.train_rounded, P.purple87],
    ['Anna Nagar', Icons.park_rounded, P.green86],
    ['Porur', Icons.local_hospital_rounded, P.red87],
  ];

  Widget _stepper(String label, String sub, int value, int min, int max, ValueChanged<int> onChange, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
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
          SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800))),
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

  Widget _dateTile(String label, DateTime d, String time, CrossAxisAlignment a) => Column(crossAxisAlignment: a, children: [
        Text(label, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: C.muted)),
        const SizedBox(height: Sp.xs),
        Text(dateLabel(d), style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(time, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
      ]);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final place = app.place;
        return Scaffold(
          body: Column(children: [
            SheetHeader(
              child: Column(children: [
                Row(children: [
                  BackBtn(bg: C.bg, shadow: false),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: SegmentPill(
                      options: const ['Hourly stay', 'Full-day stay'],
                      selected: 1,
                      height: 38,
                      onChanged: (i) {
                        if (i == 0) {
                          app.set(() => app.fullDay = false);
                          Navigator.pushReplacementNamed(context, '/search');
                        }
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: Sp.lg),
                Material(
                  color: C.bg,
                  borderRadius: BorderRadius.circular(R.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(R.lg),
                    onTap: () async {
                      final r = await Navigator.pushNamed(context, '/picker');
                      if (r is String) app.set(() => app.place = r);
                    },
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
                      child: Row(children: [
                        const Icon(Icons.search_rounded),
                        const SizedBox(width: Sp.md),
                        Expanded(
                          child: Text(place ?? 'Search area, landmark or hotel',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: Fs.md, fontWeight: place == null ? FontWeight.w400 : FontWeight.w700, color: place == null ? C.muted : C.ink)),
                        ),
                        if (place != null)
                          GestureDetector(
                            onTap: () => app.set(() => app.place = null),
                            child: Icon(Icons.close_rounded, size: Ic.md, color: C.muted),
                          ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xs, Sp.xl, Sp.xxl),
                children: [
                  const SizedBox(height: Sp.lg),
                  const Highlight(before: 'Book a room\n', marked: 'for the night.', size: 28, height: 1.2),
                  const SizedBox(height: Sp.sm),
                  Text('Check in at 12 PM, check out by 11 AM.', style: TextStyle(fontSize: Fs.md, color: C.muted)),
                  const SectionLabel('Your stay'),
                  WhiteCard(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.sm),
                    child: Column(children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(R.lg),
                        onTap: () => pickStayDates(context),
                        child: Container(
                          padding: const EdgeInsets.all(Sp.lg),
                          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
                          child: Row(children: [
                            Expanded(child: _dateTile('CHECK-IN', app.inDate, 'from 12:00 PM', CrossAxisAlignment.start)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
                              decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.pill)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.nightlight_rounded, size: Ic.sm),
                                const SizedBox(width: Sp.xs),
                                Text(app.stayLabel, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                            Expanded(child: _dateTile('CHECK-OUT', app.outDate, 'by 11:00 AM', CrossAxisAlignment.end)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: Sp.xs),
                      _stepper('Rooms', 'Up to 3 guests per room', app.rooms, 1, 5, (v) => app.set(() {
                            app.rooms = v;
                            if (app.adults < v) app.adults = v;
                          })),
                      _stepper('Guests', 'Aged 5+ · main guest 18+', app.adults, app.rooms, app.rooms * 3,
                          (v) => app.set(() => app.adults = v), last: true),
                    ]),
                  ),
                  const SectionLabel('Popular in Chennai'),
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popular.length,
                      separatorBuilder: (_, __) => const SizedBox(width: Sp.md),
                      itemBuilder: (_, i) {
                        final name = _popular[i][0] as String;
                        final on = place == name;
                        return GestureDetector(
                          onTap: () => app.set(() => app.place = name),
                          child: SizedBox(
                            width: 84,
                            child: Column(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: _popular[i][2] as Color,
                                  borderRadius: BorderRadius.circular(R.xl),
                                  border: Border.all(color: on ? C.ink : Colors.transparent, width: 2),
                                ),
                                child: Icon(_popular[i][1] as IconData, size: Ic.xl, color: C.tx(P.ink2)),
                              ),
                              const SizedBox(height: Sp.sm),
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: Fs.sm, fontWeight: on ? FontWeight.w700 : FontWeight.w600)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SectionLabel('Your past searches'),
                  WhiteCard(
                    radius: R.xl,
                    padding: const EdgeInsets.all(Sp.lg),
                    onTap: () {
                      final t = DateTime.now();
                      app.set(() {
                        app.place = 'T. Nagar';
                        app.inDate = DateTime(t.year, t.month, t.day);
                        app.outDate = app.inDate.add(const Duration(days: 1));
                        app.rooms = 1;
                        app.adults = 2;
                      });
                      Navigator.pushNamed(context, '/fullday-results');
                    },
                    child: Row(children: [
                      const IconTile(Icons.history_rounded, size: 42),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('T. Nagar, Chennai', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                          const SizedBox(height: Sp.xxs),
                          Text('${dateLabel(DateTime.now())} – ${dateLabel(DateTime.now().add(const Duration(days: 1)))} · 1 room · 2 guests',
                              style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                  const SizedBox(height: Sp.lg),
                  Container(
                    padding: const EdgeInsets.all(Sp.lg),
                    decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.xl)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Need it for just a few hours?', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                          SizedBox(height: Sp.xs),
                          Text('Hourly stays from ₹699 for 3 hrs.', style: TextStyle(fontSize: Fs.base, color: C.limeInk)),
                        ]),
                      ),
                      PillBtn('Try hourly', kind: BtnKind.dark, height: 40, fontSize: Fs.base, onTap: () {
                        app.set(() => app.fullDay = false);
                        Navigator.pushReplacementNamed(context, '/search');
                      }),
                    ]),
                  ),
                ],
              ),
            ),
            BottomBar(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(place ?? 'All of Chennai', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.xxs),
                    Text('${app.stayLabel} · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.guestsLabel}',
                        style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  ]),
                ),
                PillBtn('Search', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pushNamed(context, '/fullday-results')),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
