import 'package:flutter/material.dart';

import '../state.dart';
import '../policies.dart';
import '../theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _open = 0;

  static const _faqs = faqs;

  Widget _topic(IconData icon, String title, String sub, bool lime, String route, [Object? arg]) => Expanded(
        child: WhiteCard(
          radius: R.xl,
          padding: const EdgeInsets.all(Sp.lg),
          onTap: () => Navigator.pushNamed(context, route, arguments: arg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon, bg: lime ? C.limeBg : C.bg, size: 40),
            const SizedBox(height: Sp.md),
            Text(title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: Sp.xs),
            Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24), children: [
            const TitleBar(title: 'Help'),
            const SizedBox(height: Sp.xl),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Highlight(before: "We're here\nfor ", marked: 'you.', size: 32, height: 1.1),
                  SizedBox(height: Sp.sm),
                  Text('Most answers in under a minute.', style: TextStyle(fontSize: Fs.md, color: C.muted)),
                ]),
              ),
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.lg)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        3,
                        (_) => Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.symmetric(horizontal: Sp.xs),
                              decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle),
                            )),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle, border: Border.all(color: C.bg, width: 3)),
                    child: const Icon(Icons.check_rounded, size: Ic.sm),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: Sp.lg),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.lg)),
              child: Row(children: [
                Icon(Icons.search_rounded, color: C.muted),
                SizedBox(width: Sp.md),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'Search for help, e.g. refund'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: Sp.lg),
            WhiteCard(
              color: C.inkBg,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOUR LAST BOOKING', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: C.faint)),
                    const SizedBox(height: Sp.sm),
                    Text('${h.name} · ${app.slot} hrs', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800, color: C.white)),
                    Text('${inr(app.total)} · ${dateLabel(app.date)}', style: TextStyle(fontSize: Fs.sm, color: C.faint)),
                  ]),
                ),
                PillBtn('Get help', height: 42, fontSize: Fs.md, onTap: () => Navigator.pushNamed(context, '/chat')),
              ]),
            ),
            const SectionLabel('Browse topics'),
            Row(children: [
              _topic(Icons.key_rounded, 'Check-in & stay', 'ID rules, couples, local ID', true, '/policy', 'checkin'),
              const SizedBox(width: Sp.md),
              _topic(Icons.currency_rupee_rounded, 'Cancellation & refund', 'Refund %, no-shows', false, '/cancel-policy'),
            ]),
            const SizedBox(height: Sp.md),
            Row(children: [
              _topic(Icons.shield_rounded, 'Privacy policy', 'Your data and rights', false, '/legal', 'privacy'),
              const SizedBox(width: Sp.md),
              _topic(Icons.account_balance_wallet_rounded, 'Payments & credits', 'Credits history', false, '/credits'),
            ]),
            const SectionLabel('Popular questions'),
            WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xxs),
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final open = _open == i;
                  return Container(
                    decoration: BoxDecoration(border: i == _faqs.length - 1 ? null : Border(bottom: BorderSide(color: C.line))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      InkWell(
                        onTap: () => setState(() => _open = open ? -1 : i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                          child: Row(children: [
                            Expanded(child: Text(_faqs[i][0], style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600))),
                            AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 150), child: const Icon(Icons.expand_more_rounded)),
                          ]),
                        ),
                      ),
                      if (open)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Sp.lg),
                          child: Text(_faqs[i][1], style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.55)),
                        ),
                    ]),
                  );
                }),
              ),
            ),
            const SizedBox(height: Sp.sm),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Sp.sm),
              title: const Text('Something else? Report an issue', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => toast(context, 'Opening issue form…'),
            ),
          ]),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(
              child: PillBtn('Chat with us',
                  kind: BtnKind.dark, icon: Icons.chat_bubble_outline_rounded, trailingIcon: false, fontSize: Fs.md, onTap: () => Navigator.pushNamed(context, '/chat')),
            ),
            const SizedBox(width: Sp.md),
            CircleBtn(icon: Icons.mail_outline_rounded, size: 52, shadow: false, bg: C.bg, tooltip: 'Email hello@checkdin.in', onTap: () => toast(context, 'hello@checkdin.in')),
          ]),
        ),
      ]),
    );
  }
}
