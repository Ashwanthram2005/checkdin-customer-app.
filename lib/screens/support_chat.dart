import 'dart:async';

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

class _Msg {
  final String text;
  final bool me;
  final String time;
  final String? who; // agent name
  final List<String> chips;
  final String? link; // route
  final String? linkLabel;
  _Msg(this.text, {this.me = false, required this.time, this.who, this.chips = const [], this.link, this.linkLabel});
}

String _now() {
  final t = DateTime.now();
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});
  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _typing = false;
  bool _agent = false;

  static const _start = ['Check-in help', 'Refund status', 'Change my booking', 'Payment issue', 'Talk to a person'];

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
        'Hi${app.name.isEmpty ? '' : ' ${app.name}'}! I\'m the Checkdin assistant. How can I help with your stay at ${app.hotel.name}?',
        time: _now(),
        chips: _start));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  _Msg _answer(String q) {
    final t = q.toLowerCase();
    final who = _agent ? 'Divya · Checkdin' : null;
    if (t.contains('person') || t.contains('agent') || t.contains('human')) {
      return _Msg('Connecting you to our team…', time: _now());
    }
    if (t.contains('check-in') || t.contains('checkin') || t.contains('otp') || t.contains('refus')) {
      return _Msg(
          'Show your check-in OTP ${app.checkinOtp} and an original photo ID for every guest at the front desk. If the hotel refuses check-in, tell me and I\'ll call them right away.',
          time: _now(),
          who: who,
          link: '/checkin',
          linkLabel: 'Show my OTP',
          chips: const ['Hotel refused check-in', 'Talk to a person']);
    }
    if (t.contains('refund') || t.contains('cancel')) {
      return _Msg(
          app.bookingCancelled
              ? 'Your refund of ${inr(app.cancelRefund)} is requested. Approved refunds reach your original payment method in 3–5 working days.'
              : 'You haven\'t cancelled a booking yet. Cancelling 5+ hrs before check-in gets 50% back, 5–3 hrs gets 25%.',
          time: _now(),
          who: who,
          link: '/cancel-policy',
          linkLabel: 'Refund policy');
    }
    if (t.contains('change') || t.contains('date') || t.contains('time') || t.contains('extend')) {
      return _Msg(
          'You can extend during your stay from the Live stay screen. To move a booking to another slot, cancel it and book again. Refunds follow our cancellation policy.',
          time: _now(),
          who: who,
          link: app.checkedIn ? '/live' : '/bookings',
          linkLabel: app.checkedIn ? 'Extend stay' : 'My bookings');
    }
    if (t.contains('pay') || t.contains('upi') || t.contains('card') || t.contains('money')) {
      return _Msg(
          'If money left your account but the booking failed, it\'s refunded automatically in 5–7 working days. Share the UPI reference and I\'ll check right now.',
          time: _now(),
          who: who,
          chips: const ['Talk to a person']);
    }
    return _Msg('Thanks, I\'ve noted that. A team member will reply here shortly. Anything else?',
        time: _now(), who: who, chips: _agent ? const [] : const ['Talk to a person']);
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(q, me: true, time: _now()));
      _typing = true;
    });
    _toEnd();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final a = _answer(q);
    setState(() {
      _typing = false;
      _msgs.add(a);
    });
    _toEnd();
    if (a.text.startsWith('Connecting') && !_agent) {
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() {
        _agent = true;
        _msgs.add(_Msg('Hi, this is Divya from Checkdin support. I can see your booking CKD-48213 at ${app.hotel.name}. How can I help?',
            time: _now(), who: 'Divya · Checkdin'));
      });
      _toEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        SheetHeader(
          child: Row(children: [
            const BackBtn(bg: C.bg, shadow: false),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _agent ? C.ink : C.lime, shape: BoxShape.circle),
              child: Icon(_agent ? Icons.support_agent_rounded : Icons.smart_toy_outlined, color: _agent ? C.lime : C.ink, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_agent ? 'Divya · Checkdin support' : 'Checkdin support', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                Row(children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(_agent ? 'Online now' : 'Replies in about 2 min · 24×7', style: const TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: _msgs.length + (_typing ? 1 : 0) + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Center(child: Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.muted2))),
                );
              }
              final k = i - 1;
              if (k == _msgs.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(18)),
                    child: const Text('typing…', style: TextStyle(fontSize: 13, color: C.muted, fontStyle: FontStyle.italic)),
                  ),
                );
              }
              final m = _msgs[k];
              return Column(crossAxisAlignment: m.me ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                if (m.who != null)
                  Padding(padding: const EdgeInsets.only(left: 4, bottom: 3), child: Text(m.who!, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.muted))),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: m.me ? C.ink : C.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(m.me ? 18 : 4),
                      bottomRight: Radius.circular(m.me ? 4 : 18),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.text, style: TextStyle(fontSize: 14, height: 1.45, color: m.me ? C.white : C.ink)),
                    if (m.link != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, m.link!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(999)),
                          child: Text('${m.linkLabel} →', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
                  child: Text(m.me ? '${m.time} · Seen' : m.time, style: const TextStyle(fontSize: 10.5, color: C.muted2)),
                ),
                if (m.chips.isNotEmpty && k == _msgs.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in m.chips)
                        GestureDetector(
                          onTap: () => _send(c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.ink, width: 1.5)),
                            child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ]),
                  ),
              ]);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(color: C.white, boxShadow: [BoxShadow(color: Color(0x14111111), blurRadius: 20, offset: Offset(0, -6))]),
          child: Row(children: [
            CircleBtn(
                icon: Icons.add_photo_alternate_outlined, size: 44, bg: C.bg, shadow: false, tooltip: 'Attach photo', onTap: () => toast(context, 'Photo attachments arrive with the backend')),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: C.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleBtn(
              icon: Icons.send_rounded,
              size: 44,
              bg: _ctrl.text.trim().isEmpty ? C.bg : C.ink,
              iconColor: _ctrl.text.trim().isEmpty ? C.faint : C.lime,
              shadow: false,
              tooltip: 'Send',
              onTap: () => _send(_ctrl.text),
            ),
          ]),
        ),
      ]),
    );
  }
}
