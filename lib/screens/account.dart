import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: WhiteCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: onTap,
                  child: Column(children: [
                    IconTile(icon, size: 44, radius: 14),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            );
        Widget row(IconData icon, String title, String sub, {Widget? trailing, VoidCallback? onTap, bool last = false}) => InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: C.line))),
                child: Row(children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(fontSize: 12.5, color: C.muted)),
                    ]),
                  ),
                  trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A92)),
                ]),
              ),
            );
        return Scaffold(
          body: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 28), children: [
            const TitleBar(title: 'Account'),
            const SizedBox(height: 18),
            WhiteCard(
              radius: 24,
              child: Row(children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle),
                  child: Text(app.name.isEmpty ? '?' : app.name[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(phone, style: const TextStyle(fontSize: 13.5, color: C.muted)),
                  ]),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                  icon: const Icon(Icons.edit_outlined, size: 15, color: C.ink),
                  label: const Text('Edit', style: TextStyle(color: C.ink, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: C.ink, width: 1.5), shape: const StadiumBorder()),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            WhiteCard(
              color: C.ink,
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              onTap: () => Navigator.pushNamed(context, '/booking-detail'),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('UPCOMING STAY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: C.faint)),
                    ]),
                    const SizedBox(height: 8),
                    Text('${app.hotel.name} · ${app.slot} hrs', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.white)),
                    const SizedBox(height: 3),
                    Text('${dateLabel(app.date)} · ${hourLabel(app.checkInHour)} – ${hourLabel(app.checkOutHour)}',
                        style: const TextStyle(fontSize: 13, color: C.faint)),
                  ]),
                ),
                const IconTile(Icons.arrow_forward_rounded, bg: C.lime, size: 44, radius: 22),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              tile(Icons.calendar_month_outlined, 'Bookings', () => Navigator.pushNamed(context, '/bookings')),
              tile(Icons.favorite_border_rounded, 'Saved', () => Navigator.pushNamed(context, '/saved')),
              tile(Icons.credit_card_rounded, 'Payments', () => Navigator.pushNamed(context, '/payment-methods')),
            ]),
            const SectionLabel('Preferences & help'),
            WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(children: [
                row(Icons.chat_bubble_outline_rounded, 'WhatsApp updates', 'Booking updates & deals',
                    trailing: BrandSwitch(value: app.whatsappUpdates, onChanged: (v) => app.set(() => app.whatsappUpdates = v))),
                row(Icons.notifications_none_rounded, 'Notifications', 'Check-in reminders & alerts', onTap: () => Navigator.pushNamed(context, '/notifications', arguments: 'settings')),
                row(Icons.help_outline_rounded, 'Help & support', 'Chat with us or report a problem',
                    onTap: () => Navigator.pushNamed(context, '/help'), last: true),
              ]),
            ),
            const SizedBox(height: 14),
            WhiteCard(
              color: C.lime,
              onTap: () => toast(context, 'Thanks! Opening Play Store…'),
              child: Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Enjoying Checkdin?', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Rate us on Play Store ›', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 18))),
              ]),
            ),
            const SizedBox(height: 14),
            PillBtn('Log out',
                kind: BtnKind.outline,
                expand: true,
                icon: Icons.logout_rounded,
                trailingIcon: false,
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
            const SizedBox(height: 12),
            const Center(child: Text('Checkdin · v1.0.0', style: TextStyle(fontSize: 12, color: Color(0xFF7C7C74)))),
          ]),
        );
      },
    );
  }
}
