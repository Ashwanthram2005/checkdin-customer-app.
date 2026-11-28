import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

/// Cities people search for that Checkdin doesn't serve yet. [name, aliases...]
const soonCities = [
  ['Bangalore', 'bengaluru', 'blr'],
  ['Hyderabad', 'hyd', 'secunderabad'],
  ['Coimbatore', 'kovai', 'cbe'],
  ['Madurai'],
  ['Pondicherry', 'puducherry', 'pondy'],
  ['Trichy', 'tiruchirappalli'],
  ['Mumbai', 'bombay'],
  ['Delhi', 'new delhi', 'ncr', 'gurgaon', 'gurugram', 'noida'],
  ['Pune'],
  ['Kochi', 'cochin', 'ernakulam'],
  ['Vellore'],
  ['Kolkata', 'calcutta'],
];

/// The first city a search matches (needs 3+ letters), or null.
String? soonCityFor(String q) {
  final t = q.trim().toLowerCase();
  if (t.length < 3) return null;
  for (final c in soonCities) {
    if (c.any((n) => n.toLowerCase().startsWith(t) || t.startsWith(n.toLowerCase()))) return c[0];
  }
  return null;
}

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});
  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final city = (ModalRoute.of(context)?.settings.arguments as String?) ?? 'Bangalore';
    final on = app.notifyCities.contains(city);
    final next = ['Coimbatore', 'Bangalore', 'Pondicherry'].where((c) => c != city).take(2).toList();
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const Align(alignment: Alignment.centerLeft, child: BackBtn()),
              const SizedBox(height: Sp.xxl),
              Center(
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle),
                    child: const Icon(Icons.location_city_rounded, size: Ic.hero),
                  ),
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
                      decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.pill)),
                      child: Text('SOON', style: TextStyle(color: C.lime, fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: Sp.xxl),
              Text('Checkdin isn\'t in $city yet', textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
              const SizedBox(height: Sp.md),
              Text('We\'re live in Chennai right now and opening in new cities soon. Want to know the day we launch in $city?',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
              const SizedBox(height: Sp.xxl),
              WhiteCard(
                padding: const EdgeInsets.all(Sp.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('WHERE WE ARE', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: C.muted)),
                  const SizedBox(height: Sp.md),
                  Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: C.green, shape: BoxShape.circle)),
                    const SizedBox(width: Sp.md),
                    const Expanded(child: Text('Chennai', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                    Tag('Live now', bg: C.limeSoft, fg: C.ink),
                  ]),
                  const SizedBox(height: Sp.md),
                  for (final c in [city, ...next])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.md),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: C.faint, width: 2), shape: BoxShape.circle)),
                        const SizedBox(width: Sp.md),
                        Expanded(child: Text(c, style: TextStyle(fontSize: Fs.md, fontWeight: c == city ? FontWeight.w700 : FontWeight.w600))),
                        Text(c == city ? 'Coming soon' : 'Planned', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                      ]),
                    ),
                ]),
              ),
              if (on) ...[
                const SizedBox(height: Sp.lg),
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.lg)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text('Done! We\'ll WhatsApp you${app.phone.isEmpty ? '' : ' on +91 ${app.phone}'} when Checkdin opens in $city.',
                          style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, height: 1.4)),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
        BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            PillBtn(
              on ? 'You\'ll be notified' : (_sending ? 'Saving…' : 'Notify me when it launches'),
              kind: on ? BtnKind.soft : BtnKind.dark,
              height: 54,
              icon: on ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              trailingIcon: false,
              expand: true,
              onTap: on || _sending
                  ? null
                  : () async {
                      setState(() => _sending = true);
                      await Future<void>.delayed(const Duration(milliseconds: 700));
                      if (!mounted) return;
                      app.set(() => app.notifyCities.add(city));
                      setState(() => _sending = false);
                    },
            ),
            const SizedBox(height: Sp.sm),
            PillBtn('Explore stays in Chennai', kind: BtnKind.outline, height: 48, expand: true, onTap: () {
              app.set(() => app.place = null);
              Navigator.pop(context);
            }),
          ]),
        ),
      ]),
    );
  }
}
