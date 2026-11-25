import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class CancelPolicyScreen extends StatelessWidget {
  const CancelPolicyScreen({super.key});

  static const _rules = [
    [Icons.check_circle_outline_rounded, 'Free cancellation', 'Cancel up to 2 hours before check-in and get a full refund. No questions asked.'],
    [Icons.schedule_rounded, 'Late cancellation', 'Within 2 hours of check-in, the booking can\'t be refunded. You can still change the date once from Help.'],
    [Icons.no_meeting_room_outlined, 'No-shows & leaving early', 'If you don\'t turn up, or check out before your slot ends, the full amount is charged.'],
    [Icons.account_balance_wallet_outlined, 'Refunds', 'Refunds reach your bank or UPI in 5–7 working days. Checkdin credits come back instantly.'],
  ];

  static const _steps = [
    'Open Bookings and tap your upcoming stay.',
    'Tap Cancel booking and pick a reason.',
    'See your refund amount and confirm.',
  ];

  @override
  Widget build(BuildContext context) {
    final inH = app.checkInHour;
    final freeUntil = inH - 2;
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Cancellation policy'),
              const SizedBox(height: 22),
              const Highlight(before: 'Plans changed?\nCancel ', marked: 'for free.', size: 30, height: 1.15),
              const SizedBox(height: 8),
              const Text('Free cancellation up to 2 hours before check-in.', style: TextStyle(fontSize: 14, color: C.muted)),
              const SectionLabel('For this booking'),
              WhiteCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(
                      height: 10,
                      child: Row(children: [
                        Expanded(flex: 7, child: ColoredBox(color: C.lime)),
                        SizedBox(width: 3),
                        Expanded(flex: 3, child: ColoredBox(color: C.red)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Text('Now', style: TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600)),
                    const Spacer(flex: 6),
                    Text(hourLabel(freeUntil < 0 ? 0 : freeUntil),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    const Spacer(flex: 3),
                    Text('Check-in ${hourLabel(inH)}', style: const TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(16)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('FULL REFUND',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: C.green)),
                          const SizedBox(height: 4),
                          Text('Before ${hourLabel(freeUntil < 0 ? 0 : freeUntil)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(16)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('NO REFUND',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: C.red)),
                          const SizedBox(height: 4),
                          Text('After ${hourLabel(freeUntil < 0 ? 0 : freeUntil)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SectionLabel('The rules'),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(children: [
                  for (var i = 0; i < _rules.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: i == _rules.length - 1 ? null : const Border(bottom: BorderSide(color: C.line)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        IconTile(_rules[i][0] as IconData, bg: i == 0 ? C.lime : C.bg, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_rules[i][1] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(_rules[i][2] as String, style: const TextStyle(fontSize: 13, color: C.muted, height: 1.45)),
                          ]),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SectionLabel('How to cancel'),
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: const TextStyle(color: C.lime, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_steps[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  ]),
                ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/legal'),
                  child: const Text('Read full Terms of use',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(
              child: PillBtn('Get help', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pushNamed(context, '/help')),
            ),
            const SizedBox(width: 12),
            Expanded(child: PillBtn('Got it', kind: BtnKind.dark, expand: true, onTap: () => Navigator.maybePop(context))),
          ]),
        ),
      ]),
    );
  }
}
