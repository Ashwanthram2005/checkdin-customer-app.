import 'package:flutter/material.dart';

import '../policies.dart';
import '../theme.dart';
import 'policy_doc.dart';

/// Terms of use + Privacy policy. Pass 'privacy' as the route argument to open the second tab.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});
  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  bool _terms = true;
  int _open = 0;
  bool _argRead = false;

  static const _tSummary = [
    'Checkdin connects you with partner hotels; the hotel provides your stay.',
    'Carry an original photo ID for every guest.',
    'Cancel 5+ hrs before check-in for a 50% refund.',
  ];
  static const _tSections = [
    ['Who we are', 'Checkdin is an online platform that lets you book hotel rooms by the hour or by the day in partner hotels. The hotel is responsible for your stay, rooms and services.'],
    ['Your account', 'You sign in with your mobile number and a one-time code sent on WhatsApp. Keep your phone secure. You are responsible for bookings made from your account.'],
    ['Bookings and payment', 'Prices shown include taxes unless stated. Your booking is confirmed only after payment succeeds and you receive a Booking ID.'],
    ['Check-in rules', 'Every guest must show an original government photo ID. Hotels may refuse check-in if their rules are not met, including age and local ID rules shown on the hotel page.'],
    ['Cancellations and refunds', 'Cancel more than 5 hours before check-in for a 50% refund, or between 5 and 3 hours for 25%. Later cancellations and no-shows are not refunded. See the Cancellation & Refund Policy for details.'],
    ['Fair use', 'Do not misuse the app, share false details, or use the hotel for illegal activity. We may suspend accounts that break these terms.'],
    ['Changes to these terms', 'We may update these terms. We will tell you in the app when we make important changes.'],
  ];
  static const _pSummary = [
    'We never see your card number, UPI PIN or bank password.',
    'We share your details only with the hotel you book and partners who run the service.',
    'We do not sell your data. Email dpo@checkdin.in to access or delete it.',
  ];
  static const _pSections = [
    ['What we collect', 'Your name, mobile number, optional email and gender, your bookings, and payment status. Card details are stored by our payment partner, not by Checkdin.'],
    ['How we use it', 'To create your account, confirm bookings, send OTPs and booking updates on WhatsApp, give support, and improve the app.'],
    ['Who we share it with', 'The hotel you book (name, phone, booking time) and service providers such as our payment and messaging partners. We do not sell your data.'],
    ['Location', 'If you allow it, we use your location only to show stays near you. You can turn this off in your phone settings.'],
    ['Marketing messages', 'Deals on WhatsApp are optional. Turn them off anytime in Account → WhatsApp updates.'],
    ['Your rights', 'Under India’s Digital Personal Data Protection Act, you can access, correct or delete your data. Use Edit profile → Delete my account, or write to us.'],
    ['How long we keep data', 'We keep booking records as long as the law requires for tax and safety, then delete them.'],
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argRead) {
      _argRead = true;
      if (ModalRoute.of(context)?.settings.arguments == 'privacy') _terms = false;
    }
  }

  Widget _tab(String label, bool on, VoidCallback tap) => Expanded(
        child: GestureDetector(
          onTap: tap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? C.card : Colors.transparent,
              borderRadius: BorderRadius.circular(R.pill),
              boxShadow: on ? kShadow : null,
            ),
            child: Text(label, style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: on ? C.ink : C.muted2)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final summary = _terms ? _tSummary : _pSummary;
    final sections = _terms ? _tSections : _pSections;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 30 + MediaQuery.of(context).padding.bottom),
        children: [
          const TitleBar(title: 'Legal'),
          const SizedBox(height: Sp.lg),
          Container(
            padding: const EdgeInsets.all(Sp.xs),
            decoration: BoxDecoration(color: C.track, borderRadius: BorderRadius.circular(R.pill)),
            child: Row(children: [
              _tab('Terms of use', _terms, () => setState(() {
                    _terms = true;
                    _open = 0;
                  })),
              _tab('Privacy policy', !_terms, () => setState(() {
                    _terms = false;
                    _open = 0;
                  })),
            ]),
          ),
          const SizedBox(height: Sp.xxl),
          Text(_terms ? 'Terms of use' : 'Privacy policy',
              style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
          const SizedBox(height: Sp.xs),
          Text(_terms ? 'Last updated 25 Nov 2026 · Draft' : 'From checkdin.in', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
          const SizedBox(height: Sp.lg),
          Container(
            padding: const EdgeInsets.all(Sp.lg),
            decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.xl)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('IN SHORT', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, letterSpacing: 1, color: C.limeInk)),
              const SizedBox(height: Sp.md),
              for (final s in summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.sm),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: EdgeInsets.only(top: Sp.xxs), child: Icon(Icons.check_rounded, size: Ic.sm, color: C.green)),
                    const SizedBox(width: Sp.sm),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, height: 1.45))),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: Sp.lg),
          if (!_terms) const PolicyBody(privacyPolicy, showIntro: false) else WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xxs),
            child: Column(children: [
              for (var i = 0; i < sections.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == sections.length - 1 ? null : Border(bottom: BorderSide(color: C.line)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InkWell(
                      onTap: () => setState(() => _open = _open == i ? -1 : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                        child: Row(children: [
                          SizedBox(
                            width: 28,
                            child: Text((i + 1).toString().padLeft(2, '0'),
                                style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.muted2)),
                          ),
                          Expanded(child: Text(sections[i][0], style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                          AnimatedRotation(
                            turns: _open == i ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ]),
                      ),
                    ),
                    if (_open == i)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Sp.x3, 0, 0, Sp.lg),
                        child: Text(sections[i][1], style: TextStyle(fontSize: Fs.base, color: C.tx(P.ink2), height: 1.6)),
                      ),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: Sp.lg),
          WhiteCard(
            onTap: () => Navigator.pushNamed(context, '/help'),
            child: Row(children: [
              IconTile(Icons.mail_outline_rounded, size: 38),
              SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Questions about this?', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  SizedBox(height: Sp.xxs),
                  Text('Write to hello@checkdin.in', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ],
      ),
    );
  }
}
