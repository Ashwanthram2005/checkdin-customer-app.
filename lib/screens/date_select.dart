import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class DateSelectScreen extends StatelessWidget {
  const DateSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final today = app.today;
        final sel = DateTime(app.date.year, app.date.month, app.date.day);
        final months = List.generate(3, (i) => DateTime(today.year, today.month + i, 1));
        return Scaffold(
          body: Column(children: [
            SheetHeader(
              child: Row(children: [
                BackBtn(bg: C.bg, shadow: false),
                const SizedBox(width: Sp.md),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Check-in date', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                  SizedBox(height: 1),
                  Text('Step 1 of 2', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                ]),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.xxl),
                itemCount: months.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.lg),
                itemBuilder: (context, i) {
                  final m = months[i];
                  final lead = m.weekday % 7; // Sunday first
                  final days = DateTime(m.year, m.month + 1, 0).day;
                  return WhiteCard(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                        child: Text('${monthsLong[m.month - 1]} ${m.year}', style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: Sp.md),
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1,
                        children: [
                          for (final w in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                            Center(child: Text(w, style: const TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: P.hint))),
                          for (var b = 0; b < lead; b++) const SizedBox(),
                          for (var d = 1; d <= days; d++)
                            Builder(builder: (_) {
                              final dt = DateTime(m.year, m.month, d);
                              final past = dt.isBefore(today);
                              final on = dt == sel;
                              final isToday = dt == today;
                              return Center(
                                child: GestureDetector(
                                  onTap: past ? null : () => app.set(() {
                                    app.date = dt;
                                    app.hour = null;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: on ? C.limeBg : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: isToday && !on ? Border.all(color: C.ink, width: 1.5) : null,
                                    ),
                                    child: Text('$d',
                                        style: TextStyle(
                                            fontSize: Fs.md,
                                            fontWeight: on || isToday ? FontWeight.w800 : FontWeight.w600,
                                            color: past ? P.disabled : C.ink)),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ]),
                  );
                },
              ),
            ),
            BottomBar(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('${app.place ?? 'Chennai'} · ${app.slot}-hour stay', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    const SizedBox(height: Sp.xxs),
                    Text('${dateLabel(sel)}${sel == today ? ' · Today' : ''}', style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                  ]),
                ),
                PillBtn('Select time', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pushNamed(context, '/time')),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
