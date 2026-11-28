import 'package:flutter/material.dart';

import '../policies.dart';
import '../theme.dart';

/// Intro + numbered, tappable sections + closing line for a [PolicyDoc].
class PolicyBody extends StatefulWidget {
  final PolicyDoc doc;
  final bool showIntro;
  const PolicyBody(this.doc, {super.key, this.showIntro = true});
  @override
  State<PolicyBody> createState() => _PolicyBodyState();
}

class _PolicyBodyState extends State<PolicyBody> {
  int _open = 0;

  @override
  void didUpdateWidget(PolicyBody old) {
    super.didUpdateWidget(old);
    if (old.doc != widget.doc) _open = 0;
  }

  Widget _line(String l) {
    if (l.startsWith('• ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Sp.sm, left: Sp.xxs),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 6, height: 6, margin: const EdgeInsets.only(top: Sp.sm, right: Sp.md), decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle)),
          Expanded(child: Text(l.substring(2), style: TextStyle(fontSize: Fs.base, color: C.tx(P.ink2), height: 1.5))),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Text(l, style: TextStyle(fontSize: Fs.base, color: C.tx(P.ink2), height: 1.55)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.showIntro && d.intro.isNotEmpty) ...[
        Text(d.intro, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.55)),
        const SizedBox(height: Sp.lg),
      ],
      WhiteCard(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xxs),
        child: Column(children: [
          for (var i = 0; i < d.sections.length; i++)
            Container(
              decoration: BoxDecoration(border: i == d.sections.length - 1 ? null : Border(bottom: BorderSide(color: C.line))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                InkWell(
                  onTap: () => setState(() => _open = _open == i ? -1 : i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                    child: Row(children: [
                      SizedBox(
                        width: 30,
                        child: Text((i + 1).toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: C.muted2)),
                      ),
                      Expanded(child: Text(d.sections[i].heading, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                      AnimatedRotation(
                        turns: _open == i ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ]),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _open == i
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(Sp.x3, 0, 0, Sp.md),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: d.sections[i].lines.map(_line).toList()),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ]),
            ),
        ]),
      ),
      if (d.outro.isNotEmpty) ...[
        const SizedBox(height: Sp.lg),
        Text(d.outro, style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.5)),
      ],
    ]);
  }
}

/// Full-screen policy page. Route argument: 'checkin', 'cancel' or 'privacy'.
class PolicyDocScreen extends StatelessWidget {
  const PolicyDocScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final a = ModalRoute.of(context)?.settings.arguments;
    final doc = a == 'privacy'
        ? privacyPolicy
        : a == 'cancel'
            ? cancellationPolicy
            : checkinRules;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          TitleBar(title: doc == checkinRules ? 'Check-in & stay' : doc.title),
          const SizedBox(height: Sp.xl),
          Text(doc.title, style: const TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
          const SizedBox(height: Sp.md),
          PolicyBody(doc),
          const SizedBox(height: Sp.lg),
          WhiteCard(
            onTap: () => Navigator.pushNamed(context, '/help'),
            child: Row(children: [
              IconTile(Icons.support_agent_rounded, size: 38),
              SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Still have a question?', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  SizedBox(height: Sp.xxs),
                  Text('Our team replies on WhatsApp', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
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
