import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

class _Txn {
  final String title, sub, date, month;
  final int amount; // + earned, - used/expired
  final IconData icon;
  final bool expired;
  const _Txn(this.title, this.sub, this.date, this.month, this.amount, this.icon, {this.expired = false});
}

// Newest first. Running balance ends at ₹120.
const _txns = [
  _Txn('Credits expired', 'Unused part of welcome bonus', '25 Nov', 'November 2026', -32, Icons.hourglass_bottom_rounded, expired: true),
  _Txn('Used on a booking', 'The Grand Residency · 3 hrs', '24 Nov', 'November 2026', -150, Icons.shopping_bag_outlined),
  _Txn('Referral bonus', 'Priya joined with your code ASHW100', '22 Nov', 'November 2026', 100, Icons.card_giftcard_rounded),
  _Txn('8% back with BACK8', 'Skyline Suites · 12 hrs', '10 Nov', 'November 2026', 152, Icons.local_offer_outlined),
  _Txn('Welcome bonus', 'Thanks for joining Checkdin', '28 Oct', 'October 2026', 50, Icons.celebration_outlined),
];

class CreditsHistoryScreen extends StatefulWidget {
  const CreditsHistoryScreen({super.key});
  @override
  State<CreditsHistoryScreen> createState() => _CreditsHistoryScreenState();
}

class _CreditsHistoryScreenState extends State<CreditsHistoryScreen> {
  int _filter = 0; // 0 all, 1 earned, 2 used

  @override
  Widget build(BuildContext context) {
    // running balance after each transaction (list is newest first)
    final after = <int>[];
    var bal = 120;
    for (final t in _txns) {
      after.add(bal);
      bal -= t.amount;
    }
    final earned = _txns.where((t) => t.amount > 0).fold<int>(0, (a, t) => a + t.amount);
    final used = _txns.where((t) => t.amount < 0).fold<int>(0, (a, t) => a - t.amount);
    final shown = [
      for (var i = 0; i < _txns.length; i++)
        if (_filter == 0 || (_filter == 1 && _txns[i].amount > 0) || (_filter == 2 && _txns[i].amount < 0)) i
    ];
    final months = <String>[];
    for (final i in shown) {
      if (!months.contains(_txns[i].month)) months.add(_txns[i].month);
    }

    return Scaffold(
      body: Loader<void>(
        load: api.creditsHistory,
        cacheKey: 'credits',
        skeleton: const SkPage(title: 'Checkdin credits', child: SkRows(count: 6)),
        builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          const TitleBar(title: 'Checkdin credits'),
          const SizedBox(height: 18),
          WhiteCard(
            color: C.inkBg,
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AVAILABLE BALANCE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: C.faint)),
              const SizedBox(height: 6),
              Text('₹120', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: C.lime, height: 1)),
              const SizedBox(height: 6),
              Text('Used automatically at checkout', style: TextStyle(fontSize: 12.5, color: C.faint)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _stat('Earned', inr(earned))),
                Container(width: 1, height: 34, color: const Color(0xFF333333)),
                const SizedBox(width: 16),
                Expanded(child: _stat('Used & expired', inr(used))),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.tint(Color(0xFFFFF4D6)), borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF8A6A00)),
              SizedBox(width: 8),
              Expanded(
                child: Text('₹100 expires on 31 Dec 2026. Use it on your next stay.',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B5200))),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SegmentPill(options: const ['All', 'Earned', 'Used'], selected: _filter, onChanged: (i) => setState(() => _filter = i)),
          if (shown.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Nothing here yet', style: TextStyle(fontSize: 14, color: C.muted))),
            ),
          for (final m in months) ...[
            SectionLabel(m),
            WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                for (final i in shown.where((i) => _txns[i].month == m).toList().asMap().entries)
                  Builder(builder: (_) {
                    final t = _txns[i.value];
                    final inMonth = shown.where((k) => _txns[k].month == m).length;
                    final plus = t.amount > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(border: i.key == inMonth - 1 ? null : Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        IconTile(t.icon, bg: plus ? C.limeSoft : (t.expired ? const Color(0xFFFFF4D6) : C.bg), size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${t.sub} · ${t.date}', style: TextStyle(fontSize: 12, color: C.muted)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${plus ? '+' : '−'}${inr(t.amount.abs())}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: plus ? C.green : (t.expired ? const Color(0xFF8A6A00) : C.ink))),
                          const SizedBox(height: 2),
                          Text('Bal ${inr(after[i.value])}', style: TextStyle(fontSize: 11.5, color: C.muted2)),
                        ]),
                      ]),
                    );
                  }),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          const SectionLabel('How credits work'),
          WhiteCard(
            padding: const EdgeInsets.all(16),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _HowRow('Earn from offers like BACK8, referrals and goodwill refunds.'),
              _HowRow('Credits are used automatically at checkout, before you pay.'),
              _HowRow('Each credit has an expiry date shown in your history.'),
              _HowRow('Credits can\'t be withdrawn as cash.', last: true),
            ]),
          ),
        ],
      ),
      ),
    );
  }

  Widget _stat(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: TextStyle(fontSize: 12, color: C.faint)),
        const SizedBox(height: 2),
        Text(v, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.white)),
      ]);
}

class _HowRow extends StatelessWidget {
  final String text;
  final bool last;
  const _HowRow(this.text, {this.last = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.check_circle_rounded, size: 18, color: C.green)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.45))),
        ]),
      );
}
