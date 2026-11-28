import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

const referCode = 'ASHW100';
const _link = 'https://checkdin.in/r/ASHW100';
const _msg =
    'I book hotel rooms by the hour on Checkdin. Use my code ASHW100 and get ₹100 off your first stay in Chennai: $_link';

/// Opens WhatsApp with the invite message ready to send.
Future<void> shareOnWhatsApp(BuildContext context) async {
  final ok = await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_msg)}'), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'WhatsApp isn\'t installed');
}

class _Friend {
  final String name, status, when;
  final int earned; // 0 = not yet
  const _Friend(this.name, this.status, this.when, this.earned);
}

const _friends = [
  _Friend('Priya', 'Booked a stay', '22 Nov', 100),
  _Friend('Karthik', 'Signed up · first stay pending', '19 Nov', 0),
  _Friend('Meera', 'Invite sent', '15 Nov', 0),
];

class ReferScreen extends StatelessWidget {
  const ReferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earned = _friends.fold<int>(0, (a, f) => a + f.earned);
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Refer & earn'),
              const SizedBox(height: Sp.lg),
              Container(
                padding: const EdgeInsets.all(Sp.xl),
                decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.xl)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Give ₹100,\nget ₹100', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.05)),
                  const SizedBox(height: Sp.sm),
                  Text('Your friend gets ₹100 off their first stay. You get ₹100 in Checkdin credits when they check in.',
                      style: TextStyle(fontSize: Fs.base, height: 1.45, color: C.limeInk)),
                  const SizedBox(height: Sp.lg),
                  Container(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.sm, Sp.sm),
                    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.lg)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('YOUR CODE', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: C.muted)),
                          Text(referCode, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        ]),
                      ),
                      PillBtn('Copy', kind: BtnKind.soft, height: 40, fontSize: Fs.base, icon: Icons.copy_rounded, trailingIcon: false, onTap: () {
                        Clipboard.setData(const ClipboardData(text: referCode));
                        toast(context, 'Code copied');
                      }),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: Sp.md),
              Row(children: [
                Expanded(
                  child: PillBtn('Share on WhatsApp',
                      kind: BtnKind.dark, height: 54, icon: Icons.chat_rounded, trailingIcon: false, expand: true, onTap: () => shareOnWhatsApp(context)),
                ),
                const SizedBox(width: Sp.md),
                CircleBtn(
                  icon: Icons.link_rounded,
                  size: 54,
                  bg: C.card,
                  shadow: false,
                  tooltip: 'Copy invite link',
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _msg));
                    toast(context, 'Invite link copied');
                  },
                ),
              ]),
              const SectionLabel('Your rewards'),
              Row(children: [
                Expanded(child: _stat('Earned', inr(earned), C.limeSoft)),
                const SizedBox(width: Sp.md),
                Expanded(child: _stat('Friends joined', '${_friends.where((f) => f.status != 'Invite sent').length}', C.white)),
                const SizedBox(width: Sp.md),
                Expanded(child: _stat('Pending', inr(100 * _friends.where((f) => f.earned == 0 && f.status != 'Invite sent').length), C.white)),
              ]),
              const SectionLabel('Friends you invited'),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xxs),
                child: Column(children: [
                  for (var i = 0; i < _friends.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(border: i == _friends.length - 1 ? null : Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: _friends[i].earned > 0 ? C.limeBg : C.bg, shape: BoxShape.circle),
                          child: Icon(_friends[i].earned > 0 ? Icons.check_rounded : Icons.person_outline_rounded, size: Ic.md),
                        ),
                        const SizedBox(width: Sp.md),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_friends[i].name, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                            Text('${_friends[i].status} · ${_friends[i].when}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                          ]),
                        ),
                        if (_friends[i].earned > 0)
                          Text('+${inr(_friends[i].earned)}', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: C.green))
                        else
                          GestureDetector(
                            onTap: () => shareOnWhatsApp(context),
                            child: const Text('Remind', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                          ),
                      ]),
                    ),
                ]),
              ),
              const SectionLabel('How it works'),
              for (final s in [
                ['1', 'Share your code', 'Send it on WhatsApp or copy the link.'],
                ['2', 'Friend books', 'They get ₹100 off their first stay with your code.'],
                ['3', 'You earn', '₹100 credits land in your wallet after they check in.'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.md),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle),
                      child: Text(s[0], style: TextStyle(color: C.lime, fontWeight: FontWeight.w700, fontSize: Fs.base)),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s[1], style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                        Text(s[2], style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
              const SizedBox(height: Sp.sm),
              Text('Up to 10 rewards per month. Credits expire 90 days after they\'re added. Self-referrals and fake accounts aren\'t eligible.',
                  style: TextStyle(fontSize: Fs.sm, color: C.muted2, height: 1.45)),
            ],
          ),
        ),
      ]),
    );
  }

  static Widget _stat(String k, String v, Color bg) => Container(
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.lg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: Sp.xxs),
          Text(k, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
        ]),
      );
}
