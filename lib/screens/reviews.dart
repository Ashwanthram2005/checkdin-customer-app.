import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

class _Review {
  final String name, when, stay, text, reply;
  final int rating, photos;
  final List<String> tags;
  final bool couple;
  const _Review(this.name, this.rating, this.when, this.stay, this.text,
      {this.tags = const [], this.photos = 0, this.couple = false, this.reply = ''});
}

/// Sample reviews until the backend serves real ones.
const _sample = [
  _Review('Priya S.', 5, '2 days ago', '3-hr stay', 'Clean room and quick check-in. Perfect for a few hours between trains.',
      tags: ['Clean room', 'Quick check-in'], photos: 2),
  _Review('Karthik R.', 4, '1 week ago', '6-hr stay', 'AC was cold, bed was comfy. Parking was a little tight but staff helped.',
      tags: ['Cool AC', 'Comfy bed'], reply: 'Thanks Karthik! We\'ve added two more parking spots this month.'),
  _Review('Guest', 5, '2 weeks ago', '3-hr stay', 'Couple friendly as promised. No awkward questions, just ID check. Will book again.',
      tags: ['Privacy', 'Friendly staff'], couple: true),
  _Review('Meera V.', 3, '3 weeks ago', '12-hr stay', 'Room was fine but the bathroom needed a better clean. Location is great for T. Nagar shopping.',
      tags: ['Good location']),
  _Review('Arjun', 5, '1 month ago', '9-hr stay', 'Booked last-minute after a flight delay. Got the room in 10 minutes. Lifesaver.',
      tags: ['Quick check-in', 'Value for money'], photos: 1),
];

List<_Review> _forHotel() {
  final mine = app.myReview;
  if (mine == null || mine.hotelId != app.hotel.id) return _sample;
  return [
    _Review(mine.anonymous ? 'You (anonymous)' : (app.name.isEmpty ? 'You' : '${app.name} (you)'), mine.rating, mine.when, 'Your stay',
        mine.text.isEmpty ? 'Rated ${mine.rating} stars.' : mine.text,
        tags: mine.tags, photos: mine.photos),
    ..._sample,
  ];
}

class _ReviewCard extends StatelessWidget {
  final _Review r;
  final bool flat;
  const _ReviewCard(this.r, {this.flat = false});
  @override
  Widget build(BuildContext context) {
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: r.stay == 'Your stay' ? C.limeBg : C.bg, shape: BoxShape.circle),
          child: Icon(r.name.startsWith('Guest') || r.name.contains('anonymous') ? Icons.person_outline_rounded : Icons.person_rounded, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text('${r.stay} · ${r.when}', style: TextStyle(fontSize: 12, color: C.muted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: r.rating >= 4 ? C.limeSoft : C.bg, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star_rounded, size: 14, color: C.gold),
            const SizedBox(width: 2),
            Text('${r.rating}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
      const SizedBox(height: 10),
      Text(r.text, style: TextStyle(fontSize: 13.5, color: C.tx(Color(0xFF3F3F38)), height: 1.5)),
      if (r.tags.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final t in r.tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(8)),
              child: Text('👍 $t', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
        ]),
      ],
      if (r.photos > 0) ...[
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 0; i < r.photos; i++)
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: i.isEven ? C.tint(Color(0xFFE6DDD0)) : C.tint(Color(0xFFD6E0E6)), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.image_outlined, color: Color(0xFF8A8478)),
            ),
        ]),
      ],
      if (r.reply.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reply from the hotel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(r.reply, style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.45)),
          ]),
        ),
      ],
    ]);
    return flat ? body : WhiteCard(padding: const EdgeInsets.all(16), child: body);
  }
}

/// Two latest reviews + "See all" for the hotel page.
class ReviewsPreview extends StatelessWidget {
  const ReviewsPreview({super.key});
  @override
  Widget build(BuildContext context) {
    final list = _forHotel();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final r in list.take(2)) ...[Divider(color: C.line, height: 24), _ReviewCard(r, flat: true)],
      const SizedBox(height: 14),
      PillBtn('See all ${app.hotel.reviews + (list.length - _sample.length)} reviews',
          kind: BtnKind.soft, height: 44, fontSize: 14, expand: true, onTap: () => Navigator.pushNamed(context, '/reviews')),
    ]);
  }
}

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _f = 'All';
  static const _filters = ['All', '5 ★', '4 ★', '3 ★ & below', 'With photos', 'Couples'];

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    final all = _forHotel();
    final list = all.where((r) {
      switch (_f) {
        case '5 ★':
          return r.rating == 5;
        case '4 ★':
          return r.rating == 4;
        case '3 ★ & below':
          return r.rating <= 3;
        case 'With photos':
          return r.photos > 0;
        case 'Couples':
          return r.couple;
      }
      return true;
    }).toList();
    return Scaffold(
      body: Loader<void>(
        load: () => api.hotelReviews(app.hotel.id),
        cacheKey: 'reviews|${app.hotel.id}',
        skeleton: const SkPage(title: 'Reviews', child: SkCards(count: 3, height: 130)),
        builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          const TitleBar(title: 'Ratings & reviews'),
          const SizedBox(height: 18),
          WhiteCard(
            padding: const EdgeInsets.all(18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.rating, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1)),
                const SizedBox(height: 6),
                Row(
                    children: List.generate(
                        5, (i) => Icon(Icons.star_rounded, size: 16, color: i < double.parse(h.rating).round() ? C.gold : const Color(0xFFE2E2DA)))),
                const SizedBox(height: 4),
                Text('${h.reviews} verified stays', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(children: [
                  for (var k = 0; k < 5; k++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(children: [
                        SizedBox(width: 14, child: Text('${5 - k}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: [0.62, 0.24, 0.09, 0.03, 0.02][k],
                              minHeight: 7,
                              backgroundColor: C.line,
                              valueColor: AlwaysStoppedAnimation(C.ink),
                            ),
                          ),
                        ),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _f = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _f == f ? C.inkBg : C.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _f == f ? C.ink : C.border, width: 1.5),
                      ),
                      child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _f == f ? C.lime : C.ink)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: Text('No reviews match this filter yet', style: TextStyle(color: C.muted))),
            ),
          for (final r in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ReviewCard(r)),
          const SizedBox(height: 6),
          Text('Only guests who completed a stay through Checkdin can review.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted2)),
        ],
      ),
      ),
    );
  }
}
