import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import 'coming_soon.dart';
import 'states.dart';

class SearchPickerScreen extends StatefulWidget {
  const SearchPickerScreen({super.key});
  @override
  State<SearchPickerScreen> createState() => _SearchPickerScreenState();
}

class _Item {
  final String name, sub, type;
  const _Item(this.name, this.sub, this.type);
}

class _SearchPickerScreenState extends State<SearchPickerScreen> {
  final _q = TextEditingController();

  late final List<_Item> _all = [
    ...areas.map((a) => _Item(a, a == 'OMR' ? 'IT Corridor' : 'Chennai', 'Area')),
    ...landmarks.map((l) => _Item(l[0], l[1], 'Landmark')),
    ...hotels.map((h) => _Item(h.name, 'Hotel · ${h.area}', 'Hotel')),
  ];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _pick(String name) => Navigator.pop(context, name);

  Widget _row(_Item it, bool last) {
    final icon = it.type == 'Landmark' ? Icons.flag_outlined : it.type == 'Hotel' ? Icons.bed_outlined : Icons.place_outlined;
    final bg = it.type == 'Landmark' ? C.limeSoft : it.type == 'Hotel' ? const Color(0xFFFFF1C7) : C.bg;
    return InkWell(
      onTap: () => _pick(it.name),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          IconTile(icon, bg: bg, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(it.sub, style: TextStyle(fontSize: 12.5, color: C.muted)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A92)),
        ]),
      ),
    );
  }

  Widget _list(List<_Item> items) => WhiteCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        radius: 20,
        child: Column(children: [for (var i = 0; i < items.length; i++) _row(items[i], i == items.length - 1)]),
      );

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final hits = _all.where((x) => '${x.name} ${x.sub}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      body: Column(children: [
        SheetHeader(
          child: Column(children: [
            Row(children: [
              BackBtn(bg: C.bg, shadow: false),
              SizedBox(width: 10),
              Text('Where to?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.search_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _q,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search area, landmark or hotel'),
                  ),
                ),
                if (q.isNotEmpty)
                  CircleBtn(icon: Icons.close_rounded, size: 28, shadow: false, tooltip: 'Clear', onTap: () => setState(() => _q.clear())),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
            if (q.isEmpty) ...[
              WhiteCard(
                color: C.limeBg,
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () async {
                  if (await useMyLocation(context)) _pick('Current location');
                },
                child: Row(children: [
                  IconTile(Icons.near_me_rounded, bg: C.card, size: 40, radius: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Use my current location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Stays near you, right now', style: TextStyle(fontSize: 12.5, color: C.limeInk)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ]),
              ),
              const SectionLabel('Popular areas'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.9,
                children: areas
                    .map((a) => WhiteCard(
                          radius: 18,
                          padding: const EdgeInsets.all(12),
                          onTap: () => _pick(a),
                          child: Row(children: [
                            const IconTile(Icons.place_outlined, size: 34, radius: 10),
                            const SizedBox(width: 10),
                            Expanded(child: Text(a, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                          ]),
                        ))
                    .toList(),
              ),
              const SectionLabel('Near landmarks'),
              _list(_all.where((x) => x.type == 'Landmark').toList()),
            ] else ...[
              if (soonCityFor(q) != null)
                WhiteCard(
                  radius: 20,
                  padding: const EdgeInsets.all(14),
                  onTap: () => Navigator.pushNamed(context, '/coming-soon', arguments: soonCityFor(q)),
                  child: Row(children: [
                    IconTile(Icons.location_city_rounded, bg: C.limeBg, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(soonCityFor(q)!, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Coming soon · get notified', style: TextStyle(fontSize: 12.5, color: C.muted)),
                      ]),
                    ),
                    Tag('SOON', bg: C.inkBg, fg: C.lime),
                  ]),
                ),
              for (final t in ['Area', 'Landmark', 'Hotel'])
                if (hits.any((x) => x.type == t)) ...[
                  SectionLabel('${t}s'),
                  _list(hits.where((x) => x.type == t).toList()),
                ],
              if (hits.isEmpty && soonCityFor(q) == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                  child: Column(children: [
                    Text('No matches for “${_q.text}”', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text("Try an area like T. Nagar or OMR. We're adding new hotels every week.",
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.5)),
                  ]),
                ),
            ],
          ]),
        ),
      ]),
    );
  }
}
