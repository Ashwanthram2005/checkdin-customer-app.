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
          padding: const EdgeInsets.fromLTRB(Sp.md, Sp.md, Sp.md, Sp.md),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.lg)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(when, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: .6, color: fg)),
            const SizedBox(height: Sp.sm),
            Text(value, style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            Text(sub, style: TextStyle(fontSize: Fs.xs, color: C.muted)),
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
              const SizedBox(height: Sp.xxl),
              const Highlight(before: 'Plans changed?\nHere\'s what ', marked: 'you get back.', size: 28, height: 1.18),
              const SizedBox(height: Sp.sm),
              Text('Your refund depends on how early you cancel before check-in.', style: TextStyle(fontSize: Fs.md, color: C.muted)),
              const SectionLabel('Refund on the amount you paid'),
              Row(children: [
                _tier('5+ HRS BEFORE', '50%', 'refund', C.limeSoft, C.limeInk),
                const SizedBox(width: Sp.sm),
                _tier('5–3 HRS BEFORE', '25%', 'refund', P.amber92, P.amber27),
                const SizedBox(width: Sp.sm),
                _tier('UNDER 3 HRS', '0%', 'no refund', C.redSoft, C.red),
              ]),
              const SectionLabel('For your booking'),
              WhiteCard(
                padding: const EdgeInsets.all(Sp.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${app.hotel.name} · check-in ${hourLabel(ci.hour)}, ${dateLabel(ci)}',
                      style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                  const SizedBox(height: Sp.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(R.pill),
                    child: SizedBox(
                      height: 10,
                      child: Row(children: [
                        Expanded(flex: 5, child: ColoredBox(color: C.limeBg)),
                        SizedBox(width: Sp.xs),
                        Expanded(flex: 2, child: ColoredBox(color: P.amber48)),
                        SizedBox(width: Sp.xs),
                        Expanded(flex: 3, child: ColoredBox(color: C.red)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  for (final r in [
                    [C.lime, '50% back', 'if you cancel before ${at(const Duration(hours: 5))}'],
                    [P.amber48, '25% back', 'until ${at(const Duration(hours: 3))}'],
                    [C.red, 'No refund', 'after that, or if you don\'t turn up within 1 hour of check-in'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.sm),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                            width: 10, height: 10, margin: const EdgeInsets.only(top: Sp.xs, right: Sp.md), decoration: BoxDecoration(color: r[0] as Color, shape: BoxShape.circle)),
                        Expanded(
                          child: Text.rich(TextSpan(style: const TextStyle(fontSize: Fs.base, height: 1.45), children: [
                            TextSpan(text: '${r[1]} ', style: const TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(text: r[2] as String, style: TextStyle(color: C.muted)),
                          ])),
                        ),
                      ]),
                    ),
                  const SizedBox(height: Sp.xs),
                  Text('Approved refunds usually reach your original payment method in 3–5 working days.',
                      style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.45)),
                ]),
              ),
              const SectionLabel('How to cancel'),
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.md),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: TextStyle(color: C.lime, fontWeight: FontWeight.w700, fontSize: Fs.base)),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(_steps[i], style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600))),
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
            const SizedBox(width: Sp.md),
            Expanded(child: PillBtn('Got it', kind: BtnKind.dark, expand: true, onTap: () => Navigator.maybePop(context))),
          ]),
        ),
      ]),
    );
  }
}
