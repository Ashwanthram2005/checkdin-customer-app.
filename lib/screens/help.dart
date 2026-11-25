import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _open = 0;

  static const _faqs = [
    ['How do I extend my stay?', 'Open your booking and tap Extend hours. If the room is free, you pay only for the extra hours.'],
    ['When will I get my refund?', 'Refunds go back to the payment method you used. The time it takes depends on your bank.'],
    ['What ID do I need at check-in?', 'Carry a valid government photo ID, like Aadhaar, passport or driving licence, for every guest.'],
  ];

  Widget _topic(IconData icon, String title, String sub, bool lime) => Expanded(
        child: WhiteCard(
          radius: 20,
          padding: const EdgeInsets.all(14),
          onTap: () => toast(context, 'Opening $title…'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon, bg: lime ? C.lime : C.bg, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 12, color: C.muted)),
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
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Highlight(before: "We're here\nfor ", marked: 'you.', size: 32, height: 1.1),
                  SizedBox(height: 8),
                  Text('Most answers in under a minute.', style: TextStyle(fontSize: 14, color: C.muted)),
                ]),
              ),
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        3,
                        (_) => Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle),
                            )),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: C.lime, shape: BoxShape.circle, border: Border.all(color: C.bg, width: 3)),
                    child: const Icon(Icons.check_rounded, size: 15),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 18),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.search_rounded, color: C.muted),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'Search for help, e.g. refund'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            WhiteCard(
              color: C.ink,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('YOUR LAST BOOKING', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: C.faint)),
                    const SizedBox(height: 6),
                    Text('${h.name} · ${app.slot} hrs', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.white)),
                    Text('${inr(app.total)} · ${dateLabel(app.date)}', style: const TextStyle(fontSize: 12.5, color: C.faint)),
                  ]),
                ),
                PillBtn('Get help', height: 42, fontSize: 14, onTap: () => toast(context, 'Connecting you on WhatsApp…')),
              ]),
            ),
            const SectionLabel('Browse topics'),
            Row(children: [
              _topic(Icons.key_outlined, 'Check-in & stay', 'Room, ID, late check-in', true),
              const SizedBox(width: 10),
              _topic(Icons.credit_card_rounded, 'Payments & refunds', 'Failed payment, refunds', false),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _topic(Icons.schedule_rounded, 'Change or cancel', 'Slot, extend, cancel', false),
              const SizedBox(width: 10),
              _topic(Icons.person_outline_rounded, 'Account & login', 'OTP, profile, app issues', false),
            ]),
            const SectionLabel('Popular questions'),
            WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final open = _open == i;
                  return Container(
                    decoration: BoxDecoration(border: i == _faqs.length - 1 ? null : const Border(bottom: BorderSide(color: C.line))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      InkWell(
                        onTap: () => setState(() => _open = open ? -1 : i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            Expanded(child: Text(_faqs[i][0], style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                            AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 150), child: const Icon(Icons.expand_more_rounded)),
                          ]),
                        ),
                      ),
                      if (open)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(_faqs[i][1], style: const TextStyle(fontSize: 13.5, color: C.muted, height: 1.55)),
                        ),
                    ]),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: const Text('Something else? Report an issue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => toast(context, 'Opening issue form…'),
            ),
          ]),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(
              child: PillBtn('Chat with us on WhatsApp',
                  kind: BtnKind.dark, icon: Icons.chat_bubble_outline_rounded, trailingIcon: false, fontSize: 15, onTap: () => toast(context, 'Opening WhatsApp…')),
            ),
            const SizedBox(width: 10),
            CircleBtn(icon: Icons.mail_outline_rounded, size: 52, shadow: false, bg: C.bg, tooltip: 'Email hello@checkdin.in', onTap: () => toast(context, 'hello@checkdin.in')),
          ]),
        ),
      ]),
    );
  }
}
