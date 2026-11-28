import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class _Part {
  final String title, range;
  final List<int> hours;
  final IconData icon;
  final Color tile, fg;
  const _Part(this.title, this.range, this.hours, this.icon, this.tile, [this.fg = P.ink]);
}

List<_Part> get _parts => [
  _Part('Morning', '6 AM – 11 AM', [6, 7, 8, 9, 10, 11], Icons.wb_twilight_rounded, P.amberSoft),
  _Part('Afternoon', '12 PM – 4 PM', [12, 13, 14, 15, 16], Icons.wb_sunny_rounded, P.lime88),
  _Part('Evening', '5 PM – 8 PM', [17, 18, 19, 20], Icons.brightness_6_rounded, P.orange91),
  _Part('Night', '9 PM – 5 AM', [21, 22, 23, 24, 25, 26, 27, 28, 29], Icons.nightlight_rounded, C.inkBg, C.white),
];

class TimeSelectScreen extends StatefulWidget {
  const TimeSelectScreen({super.key});
  @override
  State<TimeSelectScreen> createState() => _TimeSelectScreenState();
}

class _TimeSelectScreenState extends State<TimeSelectScreen> {
  late int _part;

  bool _past(int h) => app.isToday && h < app.earliestHour;

  @override
  void initState() {
    super.initState();
    final i = _parts.indexWhere((p) => p.hours.any((h) => !_past(h)));
    _part = i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final part = _parts[_part];
        final soon = app.earliestHour;
        final hasPick = app.hour != null;
        String withDay(int h) => '${hourLabel(h)}${h >= 24 ? ' +1' : ''}';
        return Scaffold(
          body: Column(children: [
            SheetHeader(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  BackBtn(bg: C.bg, shadow: false),
                  const SizedBox(width: Sp.md),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Check-in time', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Text('Step 2 of 2 · ${dateLabel(app.date)}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  ]),
                ]),
                const SizedBox(height: Sp.lg),
                Row(children: [
                  Text('Stay for', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.muted)),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: SegmentPill(
                      options: const ['3 hrs', '6 hrs', '9 hrs', '12 hrs'],
                      selected: [3, 6, 9, 12].indexOf(app.slot),
                      height: 34,
                      track: C.tint(P.grey93),
                      onChanged: (i) => app.set(() => app.slot = [3, 6, 9, 12][i]),
                    ),
                  ),
                ]),
                const SizedBox(height: Sp.md),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.1,
                  child: Row(
                  children: List.generate(_parts.length, (i) {
                    final p = _parts[i];
                    final open = p.hours.where((h) => !_past(h)).length;
                    final on = i == _part;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < Sp.xs ? Sp.sm : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _part = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 56,
                            decoration: BoxDecoration(
                              color: on ? C.limeBg : C.card,
                              borderRadius: BorderRadius.circular(R.lg),
                              border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(p.title, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                              const SizedBox(height: Sp.xxs),
                              Text(open > 0 ? '$open open' : 'Closed', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w600, color: C.muted2)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.xxl), children: [
                WhiteCard(
                  color: C.inkBg,
                  radius: R.xl,
                  padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
                  onTap: () => setState(() {
                    app.set(() => app.hour = soon);
                    final i = _parts.indexWhere((p) => p.hours.contains(soon));
                    if (i >= 0) _part = i;
                  }),
                  child: Row(children: [
                    IconTile(Icons.bolt_rounded, bg: C.limeBg, size: 40, radius: 20),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NEED IT NOW?', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.faint, letterSpacing: 0.6)),
                        const SizedBox(height: Sp.xxs),
                        Text('Check in at ${withDay(soon)}', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: C.white)),
                      ]),
                    ),
                    Text(app.hour == soon ? 'Selected ✓' : 'Pick', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.lime)),
                  ]),
                ),
                const SizedBox(height: Sp.lg),
                WhiteCard(
                  padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.lg),
                  child: Column(children: [
                    Row(children: [
                      IconTile(part.icon, bg: part.tile, fg: part.fg, size: 34, radius: 10),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(part.title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                          Text(part.range, style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: Sp.md),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.75,
                      children: part.hours.map((h) {
                        final past = _past(h);
                        final on = app.hour == h;
                        return GestureDetector(
                          onTap: past ? null : () => app.set(() => app.hour = h),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: on ? C.limeBg : (past ? C.bg : C.white),
                              borderRadius: BorderRadius.circular(R.lg),
                              border: Border.all(color: on ? C.lime : (past ? C.bg : C.border), width: 1.5),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(hourLabel(h),
                                  style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: past ? C.faint : C.ink)),
                              const SizedBox(height: Sp.xxs),
                              Text(past ? 'Not available' : 'till ${hourLabel(h + app.slot, short: true)}',
                                  style: TextStyle(
                                      fontSize: Fs.xs,
                                      fontWeight: FontWeight.w600,
                                      color: on ? C.limeInk : (past ? P.disabled : C.muted2))),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                ),
              ]),
            ),
            BottomBar(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('${app.place ?? 'Chennai'} · ${dateLabel(app.date)}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    const SizedBox(height: Sp.xxs),
                    Text(hasPick ? '${hourLabel(app.checkInHour)} – ${withDay(app.checkOutHour)}' : 'Pick a time',
                        style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                  ]),
                ),
                PillBtn('Search', icon: Icons.arrow_forward_rounded, onTap: hasPick ? () => Navigator.pushNamed(context, '/results') : null),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
