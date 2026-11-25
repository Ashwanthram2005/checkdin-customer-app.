import 'package:flutter/material.dart';

import '../policies.dart';
import '../state.dart';
import '../theme.dart';
import 'cancel_sheet.dart' show checkInTime;
import 'policy_doc.dart';

class CancelPolicyScreen extends StatelessWidget {
  const CancelPolicyScreen({super.key});

  static const _steps = [
    'Open My bookings and find your upcoming stay.',
    'Tap Cancel booking and pick a reason.',
    'Check the exact refund and confirm.',
  ];

  Widget _tier(String when, String value, String sub, Color bg, Color fg) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(when, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .6, color: fg)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            Text(sub, style: TextStyle(fontSize: 11.5, color: C.muted)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ci = checkInTime();
    String at(Duration d) {
      final t = ci.subtract(d);
      return '${hourLabel(t.hour)}, ${dateLabel(t)}';
    }

    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Cancellation & refund'),
              const SizedBox(height: 22),
              const Highlight(before: 'Plans changed?\nHere\'s what ', marked: 'you get back.', size: 28, height: 1.18),
              const SizedBox(height: 8),
              Text('Your refund depends on how early you cancel before check-in.', style: TextStyle(fontSize: 14, color: C.muted)),
              const SectionLabel('Refund on the amount you paid'),
              Row(children: [
                _tier('5+ HRS BEFORE', '50%', 'refund', C.limeSoft, C.limeInk),
                const SizedBox(width: 8),
                _tier('5–3 HRS BEFORE', '25%', 'refund', const Color(0xFFFFF4D6), const Color(0xFF8A6A00)),
                const SizedBox(width: 8),
                _tier('UNDER 3 HRS', '0%', 'no refund', C.redSoft, C.red),
              ]),
              const SectionLabel('For your booking'),
              WhiteCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${app.hotel.name} · check-in ${hourLabel(ci.hour)}, ${dateLabel(ci)}',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 10,
                      child: Row(children: [
                        Expanded(flex: 5, child: ColoredBox(color: C.limeBg)),
                        SizedBox(width: 3),
                        Expanded(flex: 2, child: ColoredBox(color: Color(0xFFF2B705))),
                        SizedBox(width: 3),
                        Expanded(flex: 3, child: ColoredBox(color: C.red)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final r in [
                    [C.lime, '50% back', 'if you cancel before ${at(const Duration(hours: 5))}'],
                    [const Color(0xFFF2B705), '25% back', 'until ${at(const Duration(hours: 3))}'],
                    [C.red, 'No refund', 'after that, or if you don\'t turn up within 1 hour of check-in'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                            width: 10, height: 10, margin: const EdgeInsets.only(top: 5, right: 10), decoration: BoxDecoration(color: r[0] as Color, shape: BoxShape.circle)),
                        Expanded(
                          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5, height: 1.45), children: [
                            TextSpan(text: '${r[1]} ', style: const TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(text: r[2] as String, style: TextStyle(color: C.muted)),
                          ])),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 4),
                  Text('Approved refunds usually reach your original payment method in 3–5 working days.',
                      style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.45)),
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
                      decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: TextStyle(color: C.lime, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_steps[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  ]),
                ),
              const SectionLabel('Full policy'),
              const PolicyBody(cancellationPolicy),
            ],
          ),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(child: PillBtn('Get help', kind: BtnKind.outline, expand: true, onTap: () => Navigator.pushNamed(context, '/help'))),
            const SizedBox(width: 12),
            Expanded(child: PillBtn('Got it', kind: BtnKind.dark, expand: true, onTap: () => Navigator.maybePop(context))),
          ]),
        ),
      ]),
    );
  }
}
