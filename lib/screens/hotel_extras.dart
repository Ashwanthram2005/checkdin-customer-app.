import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../state.dart';
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
      decoration: BoxDecoration(color: C.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
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
          Text('${dateLabel(app.date)} · you stay ${app.slot} hrs', style: TextStyle(fontSize: 13, color: C.muted)),
          const SizedBox(height: 12),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                  ),
                  child: Text(hourLabel(h, short: true),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: past ? C.faint : C.ink)),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(fontSize: 12, color: C.muted)),
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
          SizedBox(width: 38, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
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
          const SizedBox(height: 8),
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, size: 17),
              const SizedBox(width: 6),
              Flexible(child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800))),
            ]),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: _btn(Icons.calendar_today_outlined,
                app.fullDay ? '${app.inDate.day}–${dateLabel(app.outDate)}' : dateLabel(app.date), () => editStayDate(context))),
        const SizedBox(width: 8),
        Expanded(child: _btn(Icons.schedule_rounded, app.fullDay ? '12 PM' : hourLabel(app.checkInHour, short: true), () => editCheckInTime(context))),
      ]),
      const SizedBox(height: 8),
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
      [Icons.window_outlined, view],
      [Icons.bed_outlined, bed],
      [Icons.shower_outlined, '1 attached bathroom'],
    ];
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$name${app.fullDay ? '' : ' (hourly)'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/gallery'),
            child: Stack(children: [
              const SizedBox(width: 128, child: PhotoPlaceholder(height: 104, radius: 16, label: 'Room')),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xB3111111), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('6', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(f[0] as IconData, size: 18, color: C.muted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f[1] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                        ]),
                      ))
                  .toList(),
            ),
          ),
        ]),
        const SizedBox(height: 6),
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
          Text('$size sq.ft · $view · $bed · fits up to 3 guests', style: TextStyle(fontSize: 13, color: C.muted)),
          const SizedBox(height: 14),
          const Text('In the room', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Air conditioning', 'Smart TV', 'Free Wi-Fi', 'Hot water', 'Towels & toiletries', 'Drinking water', 'Wardrobe', 'Housekeeping']
                .map((t) => Tag(t, bg: C.bg, fg: C.ink))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Cancellation', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('50% refund if you cancel more than 5 hrs before check-in, 25% between 5 and 3 hrs, none after that. No refund for no-shows.',
              style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.5)),
          const SizedBox(height: 14),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded, size: 16, color: C.limeInk),
            const SizedBox(width: 6),
            Text('Summary of ${h.reviews} reviews', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.limeInk)),
          ]),
          const SizedBox(height: 10),
          for (final p in [pros[s % 5], pros[(s + 2) % 5], pros[(s + 3) % 5]]) _point(true, p),
          for (final c in [cons[s % 4], cons[(s + 1) % 4]]) _point(false, c),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 72,
        child: Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/gallery'),
                  child: PhotoPlaceholder(height: 72, radius: 14, label: ['Room', 'Bathroom', 'Lobby'][i]),
                ),
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/gallery'),
              child: Container(
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(14)),
                child: Text('+$photos\nguest photos',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.limeInk, height: 1.25)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _point(bool good, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(good ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 16, color: good ? C.green : C.tx(const Color(0xFFB26A00))),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, height: 1.35))),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.search_rounded, size: 19, color: C.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Distance from… (e.g. Apollo, Central)'),
            ),
          ),
        ]),
      ),
      if (q.isEmpty) ...[
        const SizedBox(height: 10),
        SegmentPill(options: const ['Key landmarks', 'Transport'], selected: _tab, height: 38, onChanged: (i) => setState(() => _tab = i)),
      ],
      const SizedBox(height: 6),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('No place found. Try another name.', style: TextStyle(fontSize: 13, color: C.muted)),
        ),
      for (final l in list)
        Padding(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(l.sub, style: TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ),
              Text('${kmBetween(widget.h, l).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
      if (!restaurant) (Icons.no_meals_outlined, 'No restaurant at this hotel'),
      (Icons.room_service_outlined, restaurant ? 'Room service until 11 PM' : 'Outside food allowed in rooms'),
      (Icons.delivery_dining_rounded, 'Swiggy, Zomato and Blinkit deliver here'),
      (Icons.local_cafe_outlined, 'Tea and coffee on request'),
    ];
    return WhiteCard(
      child: Column(
        children: items
            .map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    IconTile(i.$1, size: 34, radius: 10, bg: i.$2.contains('pure veg') ? C.limeSoft : C.bg),
                    const SizedBox(width: 12),
                    Expanded(child: Text(i.$2, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
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
      (Icons.badge_outlined, 'Local ID', local ? 'Chennai addresses on ID are accepted' : 'IDs with a Chennai address are not accepted', local),
      (Icons.verified_user_outlined, 'Age', 'The guest booking must be 18 or older', true),
      (Icons.groups_outlined, 'Groups', maleGroups ? 'All-male groups are allowed' : 'All-male groups are not allowed', maleGroups),
      (Icons.pets_rounded, 'Pets', 'Pets are not allowed', false),
      (Icons.smoke_free_rounded, 'Smoking & alcohol', 'Not allowed inside rooms', false),
    ];
    return WhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final r in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(r.$1, size: 34, radius: 10, bg: r.$4 ? C.limeSoft : C.redSoft, fg: r.$4 ? C.ink : C.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(r.$3, style: TextStyle(fontSize: 13, color: C.muted, height: 1.35)),
                ]),
              ),
            ]),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ID proofs accepted', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['Aadhaar', 'Passport', 'Driving licence', 'Voter ID'].map((t) => Tag(t, bg: C.card, fg: C.ink)).toList(),
            ),
            const SizedBox(height: 8),
            Text('Carry the original for every guest. PAN cards and digital copies are not accepted.',
                style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
