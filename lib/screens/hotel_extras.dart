import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../state.dart';
import '../photos.dart';
import '../theme.dart';
import 'full_day_search.dart';

/// A stable per-hotel number, so each hotel gets its own room, food and rules.
int _seed(Hotel h) => h.id.codeUnits.fold(0, (a, b) => a + b);

// ---------------------------------------------------------------- share
Future<void> shareHotel(BuildContext context, Hotel h) async {
  final p = app.unitPrice;
  final text = '${h.name}, ${h.area} — ${h.rating}★ on Checkdin.'
      '${p == null ? '' : ' ${app.fullDay ? 'From ${inr(h.night)} a night' : '${app.slot} hrs for ${inr(p)}'}.'}'
      '\nBook rooms by the hour: https://checkdin.in/hotel/${h.id}';
  try {
    await Share.share(text, subject: h.name);
  } catch (_) {
    if (context.mounted) toast(context, 'Couldn\'t open sharing on this phone');
  }
}

// ---------------------------------------------------------------- editors
Widget _sheet(BuildContext ctx, String title, Widget child) => Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + MediaQuery.of(ctx).padding.bottom),
      decoration: BoxDecoration(color: C.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(R.xl))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs)))),
        const SizedBox(height: Sp.lg),
        Text(title, style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
        const SizedBox(height: Sp.md),
        child,
      ]),
    );

Future<void> editStayDate(BuildContext context) async {
  if (app.fullDay) return pickStayDates(context);
  final now = DateTime.now();
  final d = await showDatePicker(
    context: context,
    initialDate: app.date.isBefore(DateTime(now.year, now.month, now.day)) ? now : app.date,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 90)),
    helpText: 'Check-in date',
  );
  if (d != null) {
    app.set(() {
      app.date = d;
      if (app.isToday && app.hour != null && app.hour! < app.earliestHour) app.hour = null;
    });
  }
}

Future<void> editCheckInTime(BuildContext context) async {
  if (app.fullDay) {
    toast(context, 'Full-day stays check in at 12 PM');
    return;
  }
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ListenableBuilder(
      listenable: app,
      builder: (ctx, _) => _sheet(
        ctx,
        'Check-in time',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${dateLabel(app.date)} · you stay ${app.slot} hrs', style: TextStyle(fontSize: Fs.base, color: C.muted)),
          const SizedBox(height: Sp.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(24, (h) {
              final past = app.isToday && h < app.earliestHour;
              final on = app.checkInHour == h;
              return GestureDetector(
                onTap: past
                    ? null
                    : () {
                        app.set(() => app.hour = h);
                        Navigator.pop(ctx);
                      },
                child: Container(
                  width: 78,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? C.limeBg : (past ? C.bg : C.card),
                    borderRadius: BorderRadius.circular(R.md),
                    border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                  ),
                  child: Text(hourLabel(h, short: true),
                      style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: past ? C.faint : C.ink)),
                ),
              );
            }),
          ),
        ]),
      ),
    ),
  );
}

Future<void> editGuests(BuildContext context) async {
  Widget stepper(String label, String sub, int v, int min, int max, ValueChanged<int> set) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
            ]),
          ),
          CircleBtn(
              icon: Icons.remove_rounded,
              size: 36,
              shadow: false,
              bg: C.bg,
              tooltip: 'Less',
              iconColor: v > min ? C.ink : C.faint,
              onTap: v > min ? () => set(v - 1) : null),
          SizedBox(width: 38, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800))),
          CircleBtn(
              icon: Icons.add_rounded,
              size: 36,
              shadow: false,
              bg: v < max ? C.limeBg : C.bg,
              tooltip: 'More',
              iconColor: v < max ? C.ink : C.faint,
              onTap: v < max ? () => set(v + 1) : null),
        ]),
      );
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ListenableBuilder(
      listenable: app,
      builder: (ctx, _) => _sheet(
        ctx,
        'Rooms & guests',
        Column(children: [
          stepper('Rooms', 'Up to 3 guests per room', app.rooms, 1, 5, (v) => app.set(() {
                app.rooms = v;
                if (app.adults < v) app.adults = v;
                if (app.adults > v * 3) app.adults = v * 3;
              })),
          stepper('Guests', 'Aged 5+ · main guest 18+', app.adults, app.rooms, app.rooms * 3, (v) => app.set(() => app.adults = v)),
          stepper('Children', 'Below 5 years, stay free', app.kids, 0, 2, (v) => app.set(() => app.kids = v)),
          const SizedBox(height: Sp.sm),
          PillBtn('Done', kind: BtnKind.dark, expand: true, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}

/// Date · time · guests buttons shown on the hotel page.
class StayEditors extends StatelessWidget {
  const StayEditors({super.key});
  Widget _btn(IconData i, String t, VoidCallback onTap) => Material(
        color: C.bg,
        borderRadius: BorderRadius.circular(R.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.lg),
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: Sp.md),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(R.lg), border: Border.all(color: C.border, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, size: Ic.sm),
              const SizedBox(width: Sp.sm),
              Flexible(child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: _btn(Icons.calendar_today_rounded,
                app.fullDay ? '${app.inDate.day}–${dateLabel(app.outDate)}' : dateLabel(app.date), () => editStayDate(context))),
        const SizedBox(width: Sp.sm),
        Expanded(child: _btn(Icons.schedule_rounded, app.fullDay ? '12 PM' : hourLabel(app.checkInHour, short: true), () => editCheckInTime(context))),
      ]),
      const SizedBox(height: Sp.sm),
      _btn(Icons.person_outline_rounded, '${app.guestsLabel} · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'}', () => editGuests(context)),
    ]);
  }
}

// ---------------------------------------------------------------- room
class RoomCard extends StatelessWidget {
  final Hotel h;
  const RoomCard(this.h, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = _seed(h);
    final name = ['Deluxe Double Room', 'Economy Double Room', 'Premium King Room', 'Classic Queen Room'][s % 4];
    final size = [180, 200, 220, 260][s % 4];
    final view = ['City view', 'No window view', 'Garden view', 'Street view'][(s ~/ 4) % 4];
    final bed = s.isEven ? 'King bed' : 'Queen bed';
    final facts = [
      [Icons.straighten_rounded, '$size sq.ft (${(size / 10.764).round()} sq.m)'],
      [Icons.window_rounded, view],
      [Icons.bed_rounded, bed],
      [Icons.shower_rounded, '1 attached bathroom'],
    ];
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$name${app.fullDay ? '' : ' (hourly)'}', style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
        const SizedBox(height: Sp.md),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/gallery'),
            child: Stack(children: [
              SizedBox(width: 128, child: NetPhoto(photosFor(app.hotel)[1][2], height: 104, radius: R.lg, w: 400)),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
                  decoration: BoxDecoration(color: P.inkA70, borderRadius: BorderRadius.circular(R.sm)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_library_rounded, size: Ic.sm, color: Colors.white),
                    SizedBox(width: Sp.xs),
                    Text('6', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(width: Sp.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: Sp.sm),
                        child: Row(children: [
                          Icon(f[0] as IconData, size: Ic.md, color: C.muted),
                          const SizedBox(width: Sp.sm),
                          Expanded(child: Text(f[1] as String, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600))),
                        ]),
                      ))
                  .toList(),
            ),
          ),
        ]),
        const SizedBox(height: Sp.sm),
        TapLink('Room & cancellation policy details', onTap: () => _roomPolicy(context, name, size, view, bed)),
      ]),
    );
  }

  void _roomPolicy(BuildContext context, String name, int size, String view, String bed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _sheet(
        ctx,
        name,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$size sq.ft · $view · $bed · fits up to 3 guests', style: TextStyle(fontSize: Fs.base, color: C.muted)),
          const SizedBox(height: Sp.lg),
          const Text('In the room', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
          const SizedBox(height: Sp.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Air conditioning', 'Smart TV', 'Free Wi-Fi', 'Hot water', 'Towels & toiletries', 'Drinking water', 'Wardrobe', 'Housekeeping']
                .map((t) => Tag(t, bg: C.bg, fg: C.ink))
                .toList(),
          ),
          const SizedBox(height: Sp.lg),
          const Text('Cancellation', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
          const SizedBox(height: Sp.sm),
          Text('50% refund if you cancel more than 5 hrs before check-in, 25% between 5 and 3 hrs, none after that. No refund for no-shows.',
              style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.5)),
          const SizedBox(height: Sp.lg),
          PillBtn('Read full cancellation policy', kind: BtnKind.outline, expand: true, onTap: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/cancel-policy');
          }),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- reviews summary
class ReviewSummary extends StatelessWidget {
  final Hotel h;
  const ReviewSummary(this.h, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = _seed(h);
    final pros = ['Clean, well-kept rooms', 'Quick and easy check-in', 'Staff are polite and helpful', 'Good value for a short stay', 'AC and hot water work well'];
    final cons = ['Limited parking — often on the roadside', 'Rooms facing the road can be noisy', 'Breakfast is not included', 'Lift can be slow at peak hours'];
    final photos = 40 + s % 120;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded, size: Ic.sm, color: C.limeInk),
            const SizedBox(width: Sp.sm),
            Text('Summary of ${h.reviews} reviews', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.limeInk)),
          ]),
          const SizedBox(height: Sp.md),
          for (final p in [pros[s % 5], pros[(s + 2) % 5], pros[(s + 3) % 5]]) _point(true, p),
          for (final c in [cons[s % 4], cons[(s + 1) % 4]]) _point(false, c),
        ]),
      ),
      const SizedBox(height: Sp.md),
      SizedBox(
        height: 72,
        child: Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: Sp.sm),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/gallery'),
                  child: NetPhoto(photosFor(app.hotel)[[2, 5, 6][i]][2], height: 72, radius: R.md, w: 300),
                ),
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/gallery'),
              child: Container(
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.lg)),
                child: Text('+$photos\nguest photos',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.limeInk, height: 1.25)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _point(bool good, String t) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(good ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: Ic.sm, color: good ? C.green : C.tx(P.orange35)),
          const SizedBox(width: Sp.sm),
          Expanded(child: Text(t, style: const TextStyle(fontSize: Fs.base, height: 1.35))),
        ]),
      );
}

// ---------------------------------------------------------------- nearby
class NearbyCard extends StatefulWidget {
  final Hotel h;
  const NearbyCard(this.h, {super.key});
  @override
  State<NearbyCard> createState() => _NearbyCardState();
}

class _NearbyCardState extends State<NearbyCard> {
  int _tab = 0;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _transport(Landmark l) => RegExp(r'^(Airport|Railway|Bus)').hasMatch(l.sub);

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    var list = landmarks.where((l) => q.isNotEmpty ? '${l.name} ${l.sub}'.toLowerCase().contains(q) : (_transport(l) == (_tab == 1))).toList()
      ..sort((a, b) => kmBetween(widget.h, a).compareTo(kmBetween(widget.h, b)));
    if (q.isEmpty) list = list.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: Sp.md),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
        child: Row(children: [
          Icon(Icons.search_rounded, size: Ic.md, color: C.muted),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: Fs.md),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Distance from… (e.g. Apollo, Central)'),
            ),
          ),
        ]),
      ),
      if (q.isEmpty) ...[
        const SizedBox(height: Sp.md),
        SegmentPill(options: const ['Key landmarks', 'Transport'], selected: _tab, height: 38, onChanged: (i) => setState(() => _tab = i)),
      ],
      const SizedBox(height: Sp.sm),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.md),
          child: Text('No place found. Try another name.', style: TextStyle(fontSize: Fs.base, color: C.muted)),
        ),
      for (final l in list)
        Padding(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.md),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.name, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  Text(l.sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                ]),
              ),
              Text('${kmBetween(widget.h, l).toStringAsFixed(1)} km', style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- food
class FoodCard extends StatelessWidget {
  final Hotel h;
  const FoodCard(this.h, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = _seed(h);
    final veg = s % 3 == 0;
    final restaurant = s % 4 != 1;
    final items = <(IconData, String)>[
      if (restaurant) (Icons.restaurant_rounded, veg ? 'On-site pure veg restaurant' : 'On-site restaurant · veg & non-veg'),
      if (!restaurant) (Icons.no_meals_rounded, 'No restaurant at this hotel'),
      (Icons.room_service_rounded, restaurant ? 'Room service until 11 PM' : 'Outside food allowed in rooms'),
      (Icons.delivery_dining_rounded, 'Swiggy, Zomato and Blinkit deliver here'),
      (Icons.local_cafe_rounded, 'Tea and coffee on request'),
    ];
    return WhiteCard(
      child: Column(
        children: items
            .map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                  child: Row(children: [
                    IconTile(i.$1, size: 34, radius: 10, bg: i.$2.contains('pure veg') ? C.limeSoft : C.bg),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(i.$2, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600))),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------- rules
class RulesCard extends StatelessWidget {
  final Hotel h;
  const RulesCard(this.h, {super.key});
  @override
  Widget build(BuildContext context) {
    final couple = h.tags.contains('Couple friendly');
    final local = h.tags.contains('Local ID accepted');
    final maleGroups = _seed(h) % 3 == 0;
    final rules = <(IconData, String, String, bool)>[
      (Icons.favorite_border_rounded, 'Couples', couple ? 'Unmarried couples are welcome' : 'Only married couples (marriage proof may be asked)', couple),
      (Icons.badge_rounded, 'Local ID', local ? 'Chennai addresses on ID are accepted' : 'IDs with a Chennai address are not accepted', local),
      (Icons.verified_user_rounded, 'Age', 'The guest booking must be 18 or older', true),
      (Icons.groups_rounded, 'Groups', maleGroups ? 'All-male groups are allowed' : 'All-male groups are not allowed', maleGroups),
      (Icons.pets_rounded, 'Pets', 'Pets are not allowed', false),
      (Icons.smoke_free_rounded, 'Smoking & alcohol', 'Not allowed inside rooms', false),
    ];
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final r in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(r.$1, size: 34, radius: 10, bg: r.$4 ? C.limeSoft : C.redSoft, fg: r.$4 ? C.ink : C.red),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$2, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(r.$3, style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.35)),
                ]),
              ),
            ]),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ID proofs accepted', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['Aadhaar', 'Passport', 'Driving licence', 'Voter ID'].map((t) => Tag(t, bg: C.card, fg: C.ink)).toList(),
            ),
            const SizedBox(height: Sp.sm),
            Text('Carry the original for every guest. PAN cards and digital copies are not accepted.',
                style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
