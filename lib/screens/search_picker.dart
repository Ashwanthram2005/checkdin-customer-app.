import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
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
    ...landmarks.map((l) => _Item(l.name, l.sub, 'Landmark')),
    ...hotels.map((h) => _Item(h.name, 'Hotel · ${h.area}', 'Hotel')),
  ];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _pick(String name) => Navigator.pop(context, name);

  Widget _row(_Item it, bool last) {
    final icon = it.type == 'Landmark' ? Icons.flag_rounded : it.type == 'Hotel' ? Icons.bed_rounded : Icons.place_rounded;
    final bg = it.type == 'Landmark' ? C.limeSoft : it.type == 'Hotel' ? P.amberSoft : C.bg;
    return InkWell(
      onTap: () => _pick(it.name),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          IconTile(icon, bg: bg, size: 38),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.name, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
              const SizedBox(height: Sp.xxs),
              Text(it.sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: P.iconMuted),
        ]),
      ),
    );
  }

  Widget _list(List<_Item> items) => WhiteCard(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xxs),
        radius: R.xl,
        child: Column(children: [for (var i = 0; i < items.length; i++) _row(items[i], i == items.length - 1)]),
      );

  bool _locating = false;

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
              SizedBox(width: Sp.md),
              Text('Where to?', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: Sp.md),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
              decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.lg)),
              child: Row(children: [
                const Icon(Icons.search_rounded),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: TextField(
                    controller: _q,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: Fs.md),
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
          child: ListView(padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.x3), children: [
            if (q.isEmpty) ...[
              WhiteCard(
                color: C.limeBg,
                radius: R.xl,
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
                onTap: () async {
                  if (_locating) return;
                  setState(() => _locating = true);
                  final ok = await useMyLocation(context);
                  if (!mounted) return;
                  setState(() => _locating = false);
                  if (ok) _pick('Current location');
                },
                child: Row(children: [
                  IconTile(Icons.near_me_rounded, bg: C.card, size: 40, radius: 20),
                  SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Use my current location', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      SizedBox(height: Sp.xxs),
                      Text('Stays near you, right now', style: TextStyle(fontSize: Fs.sm, color: C.limeInk)),
                    ]),
                  ),
                  _locating ? const Spinner() : const Icon(Icons.chevron_right_rounded),
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
                          radius: R.lg,
                          padding: const EdgeInsets.all(Sp.md),
                          onTap: () => _pick(a),
                          child: Row(children: [
                            const IconTile(Icons.place_rounded, size: 34, radius: 10),
                            const SizedBox(width: Sp.md),
                            Expanded(child: Text(a, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                          ]),
                        ))
                    .toList(),
              ),
              const SectionLabel('Near landmarks'),
              _list(_all.where((x) => x.type == 'Landmark').toList()),
            ] else ...[
              Loader<void>(
                reloadKey: q,
                load: () => api.suggestPlaces(q),
                skeleton: const SkSuggestions(),
                builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (soonCityFor(q) != null)
                WhiteCard(
                  radius: R.xl,
                  padding: const EdgeInsets.all(Sp.lg),
                  onTap: () => Navigator.pushNamed(context, '/coming-soon', arguments: soonCityFor(q)),
                  child: Row(children: [
                    IconTile(Icons.location_city_rounded, bg: C.limeBg, size: 42),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(soonCityFor(q)!, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                        const SizedBox(height: Sp.xxs),
                        Text('Coming soon · get notified', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
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
                  padding: const EdgeInsets.symmetric(vertical: Sp.x4, horizontal: Sp.md),
                  child: Column(children: [
                    Text('No matches for “${_q.text}”', style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                    const SizedBox(height: Sp.sm),
                    Text("Try an area like T. Nagar or OMR. We're adding new hotels every week.",
                        textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.5)),
                  ]),
                ),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
