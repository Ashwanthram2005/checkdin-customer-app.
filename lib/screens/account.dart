import 'package:flutter/material.dart';

import '../state.dart';
import '../avatar.dart';
import '../api/api.dart';
import '../api/fake_api.dart';
import '../theme.dart';
import '../optimistic.dart';
import '../loading.dart';
import 'refunds.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final phone = app.phone.isEmpty ? '+91 98765 43210' : '+91 ${app.phone.substring(0, 5)} ${app.phone.substring(5)}';
        Widget tile(IconData icon, String label, VoidCallback onTap) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
                child: WhiteCard(
                  radius: R.xl,
                  padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                  onTap: onTap,
                  child: Column(children: [
                    IconTile(icon, size: 44, radius: 14),
                    const SizedBox(height: Sp.sm),
                    Text(label, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            );
        Widget row(IconData icon, String title, String sub, {Widget? trailing, VoidCallback? onTap, bool last = false}) => InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Sp.md),
                decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
                child: Row(children: [
                  Icon(icon, size: Ic.md),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600)),
                      const SizedBox(height: Sp.xxs),
                      Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                  trailing ?? const Icon(Icons.chevron_right_rounded, color: P.iconMuted),
                ]),
              ),
            );
        return Scaffold(
          body: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 28), children: [
            const TitleBar(title: 'Account'),
            const SizedBox(height: Sp.lg),
            WhiteCard(
              radius: R.xl,
              child: Row(children: [
                const Avatar(size: 60),
                const SizedBox(width: Sp.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.name, style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: Sp.xxs),
                    Text(phone, style: TextStyle(fontSize: Fs.base, color: C.muted)),
                  ]),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                  icon: Icon(Icons.edit_rounded, size: Ic.sm, color: C.ink),
                  label: Text('Edit', style: TextStyle(color: C.ink, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: C.ink, width: 1.5), shape: const StadiumBorder()),
                ),
              ]),
            ),
            const SizedBox(height: Sp.lg),
            Loader<void>(
              load: api.account,
              cacheKey: 'account',
              skeleton: const Skeleton(child: Bone(height: 96, radius: R.xl)),
              builder: (context, _) => WhiteCard(
              color: C.inkBg,
              radius: R.xl,
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
              onTap: () => Navigator.pushNamed(context, '/booking-detail'),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle)),
                      const SizedBox(width: Sp.sm),
                      Text('UPCOMING STAY', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: C.faint)),
                    ]),
                    const SizedBox(height: Sp.sm),
                    Text('${app.hotel.name} · ${app.slot} hrs', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800, color: C.white)),
                    const SizedBox(height: Sp.xs),
                    Text('${dateLabel(app.date)} · ${hourLabel(app.checkInHour)} – ${hourLabel(app.checkOutHour)}',
                        style: TextStyle(fontSize: Fs.base, color: C.faint)),
                  ]),
                ),
                IconTile(Icons.arrow_forward_rounded, bg: C.limeBg, size: 44, radius: 22),
              ]),
            ),
            ),
            const SizedBox(height: Sp.lg),
            Row(children: [
              tile(Icons.calendar_month_rounded, 'Bookings', () => Navigator.pushNamed(context, '/bookings')),
              tile(Icons.favorite_border_rounded, 'Saved', () => Navigator.pushNamed(context, '/saved')),
              tile(Icons.credit_card_rounded, 'Payments', () => Navigator.pushNamed(context, '/payment-methods')),
            ]),
            const SizedBox(height: Sp.md),
            Builder(builder: (context) {
              final n = myRefunds.where((r) => r.ongoing).length;
              return WhiteCard(
                radius: R.xl,
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.md, Sp.md),
                onTap: () => Navigator.pushNamed(context, '/refunds'),
                child: Row(children: [
                  const IconTile(Icons.currency_exchange_rounded, size: 44, radius: 14),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('My refunds', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      Text(n > 0 ? '$n in progress · track status' : 'All refunds completed', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                  if (n > 0) Tag('$n ongoing'),
                  const SizedBox(width: Sp.xs),
                  Icon(Icons.chevron_right_rounded, color: C.muted),
                ]),
              );
            }),
            const SectionLabel('Preferences & help'),
            WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
              child: Column(children: [
                row(Icons.chat_bubble_outline_rounded, 'WhatsApp updates', 'Booking updates & deals',
                    trailing: BrandSwitch(value: app.whatsappUpdates, onChanged: (v) => optimistic(context,
                            apply: () => app.set(() => app.whatsappUpdates = v),
                            revert: () => app.set(() => app.whatsappUpdates = !v),
                            call: () => api.setPreference('whatsapp', v)))),
                row(Icons.notifications_none_rounded, 'Notifications', 'Check-in reminders & alerts', onTap: () => Navigator.pushNamed(context, '/notifications', arguments: 'settings')),
                row(Icons.near_me_rounded, 'Location', app.useLocation ? 'On · change permission' : 'Off',
                    onTap: () => Navigator.pushNamed(context, '/location')),
                row(Icons.card_giftcard_rounded, 'Refer & earn', 'Give ₹100, get ₹100', onTap: () => Navigator.pushNamed(context, '/refer')),
                row(Icons.help_outline_rounded, 'Help & support', 'Chat with us or report a problem',
                    onTap: () => Navigator.pushNamed(context, '/help'), last: true),
              ]),
            ),
            const SizedBox(height: Sp.lg),
            WhiteCard(
              color: C.limeBg,
              onTap: () => toast(context, 'Thanks! Opening Play Store…'),
              child: Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Enjoying Checkdin?', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                    SizedBox(height: Sp.xs),
                    Text('Rate us on Play Store ›', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: Ic.md))),
              ]),
            ),
            const SizedBox(height: Sp.lg),
            PillBtn('Log out',
                kind: BtnKind.outline,
                expand: true,
                icon: Icons.logout_rounded,
                trailingIcon: false,
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
            const SizedBox(height: Sp.md),
            Center(
              child: GestureDetector(
                // Hidden test switch for the fake backend: long-press the version line.
                onLongPress: () => _netSheet(context),
                child: Text('Checkdin · v1.0.0${FakeApi.mode == NetMode.fast ? '' : ' · ${FakeApi.mode.label}'}',
                    style: const TextStyle(fontSize: Fs.sm, color: P.hint)),
              ),
            ),
          ]),
        );
      },
    );
  }
}


/// Test-only: choose how the fake backend behaves.
void _netSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: C.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(R.xl))),
        child: Material(
          type: MaterialType.transparency,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Test network', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.xs),
          Text('For testing only. Changes how fast the sample backend answers, so you can see loading and error screens.',
              style: TextStyle(fontSize: Fs.base, color: C.muted, height: 1.4)),
          const SizedBox(height: Sp.md),
          for (final m in NetMode.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(FakeApi.mode == m ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: C.ink),
              title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(switch (m) {
                NetMode.fast => 'About 0.6–1 s, like good 4G',
                NetMode.slow => 'About 2–3 s per request',
                NetMode.fail => 'Every request fails, to see error screens',
              }),
              onTap: () {
                FakeApi.mode = m;
                set(() {});
                app.set(() {});
              },
            ),
        ]),
        ),
      ),
    ),
  );
}
