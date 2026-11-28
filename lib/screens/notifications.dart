import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../optimistic.dart';
import '../loading.dart';
import '../api/api.dart';

class _Note {
  final IconData icon;
  final String title, body, time, group, route;
  final bool lime;
  bool unread;
  _Note(this.icon, this.title, this.body, this.time, this.group, this.route, {this.lime = false, this.unread = false});
}

/// Inbox + notification settings. Route argument 'settings' opens the Settings tab.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;
  bool _argRead = false;

  final List<_Note> _inbox = [
    _Note(Icons.alarm_rounded, 'Check-in in 2 hours', 'The Grand Residency · 2:00 PM. Carry an original photo ID for every guest.', '11:58 AM',
        'Today', '/booking-detail', lime: true, unread: true),
    _Note(Icons.check_circle_outline_rounded, 'Booking confirmed', 'Booking ID ${app.bookingId} · ₹849 paid. Show this at the front desk.', '9:14 AM',
        'Today', '/booking-detail', unread: true),
    _Note(Icons.trending_down_rounded, 'Price drop on a saved stay', 'Hotel Marina Inn is now ₹100 cheaper for a 3-hour slot.', 'Yesterday',
        'Yesterday', '/saved'),
    _Note(Icons.star_outline_rounded, 'How was Skyline Suites?', 'Rate your stay and help other guests pick the right room.', 'Yesterday',
        'Yesterday', '/rate'),
    _Note(Icons.account_balance_wallet_rounded, 'Refund sent', '₹1,299 for Hotel Marina Inn is on its way to your UPI. 3–5 working days.',
        '18 Nov', 'Earlier', '/bookings'),
    _Note(Icons.local_offer_rounded, '25% off your next stay', 'Use NEWSTAY at checkout. Valid till Sunday.', '16 Nov', 'Earlier', '/offers'),
  ];

  // Settings
  final Map<String, bool> _on = {
    'Check-in reminders': true,
    'Check-out & extend reminders': true,
    'Refund updates': true,
    'Price drops on saved stays': true,
    'Offers & deals': true,
    'New stays near you': false,
    'Push notifications': true,
    'WhatsApp': true,
    'Email': false,
    'Quiet hours': true,
  };

  static const _subs = {
    'Check-in reminders': '2 hours and 30 minutes before',
    'Check-out & extend reminders': '30 minutes before your slot ends',
    'Refund updates': 'When a refund is sent and received',
    'Price drops on saved stays': 'When a saved hotel gets cheaper',
    'Offers & deals': 'Coupons and weekend deals',
    'New stays near you': 'When a new hotel joins in your area',
    'Push notifications': 'On this phone',
    'WhatsApp': 'Booking updates and OTPs',
    'Email': 'Receipts and invoices',
    'Quiet hours': '10 PM – 8 AM · booking alerts still come',
  };

  static const _icons = {
    'Check-in reminders': Icons.alarm_rounded,
    'Check-out & extend reminders': Icons.more_time_rounded,
    'Refund updates': Icons.account_balance_wallet_rounded,
    'Price drops on saved stays': Icons.trending_down_rounded,
    'Offers & deals': Icons.local_offer_rounded,
    'New stays near you': Icons.near_me_rounded,
    'Push notifications': Icons.notifications_none_rounded,
    'WhatsApp': Icons.chat_rounded,
    'Email': Icons.mail_outline_rounded,
    'Quiet hours': Icons.bedtime_rounded,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argRead) return;
    _argRead = true;
    if (ModalRoute.of(context)?.settings.arguments == 'settings') _tab = 1;
  }

  int get _unread => _inbox.where((n) => n.unread).length;

  Widget _noteTile(_Note n) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.md),
        child: WhiteCard(
          radius: R.xl,
          padding: const EdgeInsets.all(Sp.lg),
          border: Border.all(color: n.unread ? C.ink : C.white, width: 1.5),
          onTap: () {
            setState(() => n.unread = false);
            Navigator.pushNamed(context, n.route,
                arguments: n.route == '/rate'
                    ? {'hotel': 'Skyline Suites', 'when': 'Nov 10 · 10:00 AM–10:00 PM · 12 hrs', 'rating': 0}
                    : null);
          },
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(n.icon, bg: n.lime ? C.limeBg : C.bg, size: 42),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(n.title,
                        style: TextStyle(fontSize: Fs.md, fontWeight: n.unread ? FontWeight.w700 : FontWeight.w700)),
                  ),
                  Text(n.time, style: TextStyle(fontSize: Fs.xs, color: C.muted2, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: Sp.xs),
                Text(n.body, style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.4)),
              ]),
            ),
            if (n.unread) ...[
              const SizedBox(width: Sp.sm),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: Sp.xs),
                decoration: BoxDecoration(color: C.red, shape: BoxShape.circle),
              ),
            ],
          ]),
        ),
      );

  Widget _inboxView() {
    if (_inbox.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          IconTile(Icons.notifications_none_rounded, bg: C.limeBg, size: 72, radius: 24),
          const SizedBox(height: Sp.lg),
          const Text("You're all caught up", style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.sm),
          Text('Booking updates and deals will show up here.', style: TextStyle(fontSize: Fs.base, color: C.muted)),
        ]),
      );
    }
    final groups = <String>[];
    for (final n in _inbox) {
      if (!groups.contains(n.group)) groups.add(n.group);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var g = 0; g < groups.length; g++) ...[
        SectionLabel(groups[g],
            trailing: g == 0 && _unread > 0
                ? GestureDetector(
                    onTap: () {
                      final was = _inbox.where((n) => n.unread).toList();
                      optimistic(context,
                          apply: () => setState(() {
                                for (final n in _inbox) {
                                  n.unread = false;
                                }
                              }),
                          revert: () {
                            if (!mounted) return;
                            setState(() {
                              for (final n in was) {
                                n.unread = true;
                              }
                            });
                          },
                          call: api.markNotificationsRead);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: Sp.lg, horizontal: Sp.sm),
                      child: Text('Mark all read',
                          style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                    ),
                  )
                : null),
        for (final n in _inbox.where((x) => x.group == groups[g]))
          Dismissible(
            key: ValueKey(n.title),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(bottom: Sp.md),
              padding: const EdgeInsets.only(right: Sp.xl),
              decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.xl)),
              child: Icon(Icons.delete_outline_rounded, color: C.red),
            ),
            onDismissed: (_) => setState(() => _inbox.remove(n)),
            child: _noteTile(n),
          ),
      ],
      const SizedBox(height: Sp.sm),
      Center(child: Text('Swipe left to delete', style: TextStyle(fontSize: Fs.sm, color: C.muted2))),
    ]);
  }

  Widget _group(String title, List<String> keys, {Widget? top}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
            child: Column(children: [
              if (top != null) top,
              for (var i = 0; i < keys.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: Sp.md),
                  decoration: BoxDecoration(
                    border: i == keys.length - 1 ? null : Border(bottom: BorderSide(color: C.line)),
                  ),
                  child: Row(children: [
                    IconTile(_icons[keys[i]]!, size: 38),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(keys[i], style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                        const SizedBox(height: Sp.xxs),
                        Text(_subs[keys[i]]!, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                      ]),
                    ),
                    const SizedBox(width: Sp.sm),
                    BrandSwitch(
                        value: _on[keys[i]]!,
                        onChanged: (v) => optimistic(context,
                            apply: () => setState(() => _on[keys[i]] = v),
                            revert: () {
                              if (mounted) setState(() => _on[keys[i]] = !v);
                            },
                            call: () => api.setPreference(keys[i], v))),
                  ]),
                ),
            ]),
          ),
        ],
      );

  Widget _settingsView() {
    final always = Container(
      padding: const EdgeInsets.symmetric(vertical: Sp.md),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
      child: Row(children: [
        IconTile(Icons.receipt_long_rounded, bg: C.limeBg, size: 38),
        SizedBox(width: Sp.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booking confirmations', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
            SizedBox(height: Sp.xxs),
            Text('Receipts and booking changes', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
          ]),
        ),
        Tag('Always on'),
      ]),
    );
    final noChannel = !_on['Push notifications']! && !_on['WhatsApp']! && !_on['Email']!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _group('Your bookings', const ['Check-in reminders', 'Check-out & extend reminders', 'Refund updates'], top: always),
      _group('Deals & saved', const ['Price drops on saved stays', 'Offers & deals', 'New stays near you']),
      _group('Send them on', const ['Push notifications', 'WhatsApp', 'Email']),
      if (noChannel)
        Container(
          margin: const EdgeInsets.only(top: Sp.md),
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: Ic.md, color: C.red),
            SizedBox(width: Sp.sm),
            Expanded(
              child: Text("You won't get check-in reminders. Keep at least one channel on.",
                  style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, color: C.tx(P.redDark))),
            ),
          ]),
        ),
      _group('Do not disturb', const ['Quiet hours']),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loader<void>(
        load: api.notifications,
        cacheKey: 'notifications',
        skeleton: const SkPage(title: 'Notifications', child: SkRows(count: 6)),
        builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          const TitleBar(title: 'Notifications'),
          const SizedBox(height: Sp.lg),
          SegmentPill(
            options: [_unread > 0 ? 'Inbox · $_unread' : 'Inbox', 'Settings'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          if (_tab == 0) _inboxView() else _settingsView(),
        ],
      ),
      ),
    );
  }
}
