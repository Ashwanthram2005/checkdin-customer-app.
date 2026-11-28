import 'package:flutter/material.dart';

import '../theme.dart';

/// Filter choices kept for the session so the sheet reopens as the user left it.
class Filters {
  static String sort = 'Recommended';
  static final Set<String> price = {};
  static String? rating;
  static String? distance;
  static final Set<String> policies = {};
  static final Set<String> amenities = {};

  static int get count =>
      (sort == 'Recommended' ? 0 : 1) +
      price.length +
      (rating == null ? 0 : 1) +
      (distance == null ? 0 : 1) +
      policies.length +
      amenities.length;

  static int get stays {
    final n = 24 - 4 * count;
    return n < 2 ? 2 : n;
  }

  static void clear() {
    sort = 'Recommended';
    price.clear();
    rating = null;
    distance = null;
    policies.clear();
    amenities.clear();
  }
}

/// Opens the Filters & sort bottom sheet. Returns when it is closed.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: P.inkA55,
    builder: (_) => const FilterSheet(),
  );
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});
  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  static const _sorts = [
    'Recommended',
    'Price: low to high',
    'Price: high to low',
    'Rating: high to low',
    'Distance: nearest first',
  ];

  Widget _chip(String label, bool on, VoidCallback tap) => GestureDetector(
        onTap: () => setState(tap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
          decoration: BoxDecoration(
            color: on ? C.limeBg : C.card,
            borderRadius: BorderRadius.circular(R.pill),
            border: Border.all(color: on ? C.lime : C.border, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (on) ...[const Icon(Icons.check_rounded, size: Ic.sm), const SizedBox(width: Sp.xs)],
            Text(label, style: TextStyle(fontSize: Fs.base, fontWeight: on ? FontWeight.w700 : FontWeight.w600)),
          ]),
        ),
      );

  Widget _multi(String title, List<String> opts, Set<String> set) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in opts) _chip(o, set.contains(o), () => set.contains(o) ? set.remove(o) : set.add(o)),
          ]),
        ],
      );

  Widget _single(String title, List<String> opts, String? value, void Function(String?) setVal) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in opts) _chip(o, value == o, () => setVal(value == o ? null : o)),
          ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final n = Filters.count;
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: Sp.md),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs))),
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.md, Sp.xs),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Filters & sort', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
                const SizedBox(height: Sp.xxs),
                Text(n == 0 ? 'No filters applied' : '$n ${n == 1 ? 'filter' : 'filters'} applied',
                    style: TextStyle(fontSize: Fs.base, color: C.muted)),
              ]),
            ),
            CircleBtn(icon: Icons.close_rounded, size: 40, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(context)),
          ]),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.xl),
            children: [
              const SectionLabel('Sort by'),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
                child: Column(children: [
                  for (var i = 0; i < _sorts.length; i++)
                    InkWell(
                      onTap: () => setState(() => Filters.sort = _sorts[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          border: i == _sorts.length - 1 ? null : Border(bottom: BorderSide(color: C.line)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(_sorts[i],
                                style: TextStyle(
                                    fontSize: Fs.md,
                                    fontWeight: Filters.sort == _sorts[i] ? FontWeight.w800 : FontWeight.w500)),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Filters.sort == _sorts[i] ? C.inkBg : C.card,
                              border: Border.all(color: Filters.sort == _sorts[i] ? C.ink : C.border, width: 2),
                            ),
                            child: Filters.sort == _sorts[i]
                                ? Center(
                                    child: Container(
                                        width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle)))
                                : null,
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
              _multi('Price for your slot', const ['Under ₹700', '₹700 – ₹1,000', '₹1,000 – ₹1,500', '₹1,500+'], Filters.price),
              _single('Guest rating', const ['3.5+', '4.0+', '4.5+'], Filters.rating, (v) => Filters.rating = v),
              _single('Distance', const ['Within 1 km', '3 km', '5 km', '10 km'], Filters.distance, (v) => Filters.distance = v),
              _multi('Hotel policies', const ['Couple friendly', 'Local ID accepted', 'Pay at check-in'], Filters.policies),
              _multi('Amenities', const ['AC', 'Free Wi-Fi', 'Parking', 'Smart TV', 'Power backup', 'Room service'],
                  Filters.amenities),
            ],
          ),
        ),
        BottomBar(
          child: Row(children: [
            PillBtn('Clear all', kind: BtnKind.outline, onTap: n == 0 ? null : () => setState(Filters.clear)),
            const SizedBox(width: Sp.md),
            Expanded(
              child: PillBtn('Show ${Filters.stays} stays', kind: BtnKind.dark, expand: true, onTap: () => Navigator.pop(context)),
            ),
          ]),
        ),
      ]),
    );
  }
}
