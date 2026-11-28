import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../loading.dart';
import '../main.dart' show appNavigator;
import '../photos.dart';
import '../state.dart';
import '../theme.dart';
import 'maps.dart' show callHotel;
import 'states.dart' show EmptyState;

/// Screens for situations outside the normal booking flow: app too old,
/// server down, login expired, slot sold out, price changed, and so on.

const kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.checkdin.checkdin';
const kSupportPhone = '+914400000000';

// ---------------------------------------------------------------- saved choices

String? _seenVersion;

Future<void> loadSystemPrefs({required bool firstLaunch}) async {
  try {
    final p = await SharedPreferences.getInstance();
    app.notifyAsked = p.getBool('notifyAsked') ?? false;
    app.rateAsked = p.getBool('rateAsked') ?? false;
    _seenVersion = p.getString('seenVersion');
    // A fresh install has nothing "new" to announce.
    if (_seenVersion == null && firstLaunch) {
      _seenVersion = kAppVersion;
      await p.setString('seenVersion', kAppVersion);
    }
  } catch (_) {}
}

Future<void> _saveBool(String key, bool v) async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
  } catch (_) {}
}

Future<void> _openStore(BuildContext context) async {
  final ok = await launchUrl(Uri.parse(kPlayStoreUrl), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'Couldn\'t open Play Store');
}

/// Where to go after login: ask about notifications once, then Home.
String get afterLoginRoute => app.notifyAsked ? '/home' : '/notify-permission';

// ---------------------------------------------------------------- shared bits

class _BigIcon extends StatelessWidget {
  final IconData icon;
  final Color? bg;
  const _BigIcon(this.icon, {this.bg});
  @override
  Widget build(BuildContext context) => Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(color: bg ?? C.limeBg, shape: BoxShape.circle),
        child: Icon(icon, size: Ic.hero, color: P.ink),
      );
}

/// Full-screen message with the logo on top and actions at the bottom.
class _StatusPage extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final String title, body;
  final List<Widget> children;
  final List<Widget> actions;
  final bool canPop;
  const _StatusPage({
    required this.icon,
    this.iconBg,
    required this.title,
    required this.body,
    this.children = const [],
    this.actions = const [],
    this.canPop = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    // Opened from the test sheet: allow going back.
    final preview = ModalRoute.of(context)?.settings.arguments == 'preview';
    return PopScope(
      canPop: canPop || preview,
      child: Scaffold(
        body: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(Sp.xl, pad.top + Sp.lg, Sp.xl, Sp.xxl),
              children: [
                Row(children: [
                  Image.asset('assets/logo_icon.png', width: 28, height: 28),
                  const SizedBox(width: Sp.sm),
                  const Text('Checkdin', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (preview) CircleBtn(icon: Icons.close_rounded, tooltip: 'Close preview', onTap: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: Sp.x4),
                Center(child: _BigIcon(icon, bg: iconBg)),
                const SizedBox(height: Sp.xxl),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
                const SizedBox(height: Sp.md),
                Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
                if (children.isNotEmpty) const SizedBox(height: Sp.xxl),
                ...children,
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, pad.bottom + Sp.lg),
              child: Column(mainAxisSize: MainAxisSize.min, children: actions),
            ),
        ]),
      ),
    );
  }
}

Widget _bullet(IconData icon, String title, String sub) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.md)),
          child: Icon(icon, size: Ic.md, color: P.ink),
        ),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.xxs),
            Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
          ]),
        ),
      ]),
    );

/// Bottom sheet frame used by the sheets in this file.
Future<T?> _sheet<T>(BuildContext context, Widget child, {bool dismissible = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PopScope(
      canPop: dismissible,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.lg + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: C.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(R.xl))),
        child: Material(
          type: MaterialType.transparency,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs))),
            const SizedBox(height: Sp.lg),
            child,
          ]),
        ),
      ),
    ),
  );
}

/// Other hotels near the current one (for sold-out and unavailable screens).
class SimilarStays extends StatelessWidget {
  final Hotel exclude;
  const SimilarStays({super.key, required this.exclude});
  @override
  Widget build(BuildContext context) {
    final list = hotels.where((h) => h.id != exclude.id).take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Similar stays nearby'),
      for (final h in list)
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.sm),
          child: WhiteCard(
            padding: const EdgeInsets.all(Sp.md),
            onTap: () {
              Sim.soldOut = false;
              Sim.hotelUnavailable = false;
              app.set(() {
                app.hotel = h;
                app.hour = null;
              });
              Navigator.pushNamedAndRemoveUntil(context, '/hotel', ModalRoute.withName('/home'));
            },
            child: Row(children: [
              SizedBox(width: 64, height: 64, child: NetPhoto(coverOf(h), height: 64, radius: R.md, w: 240)),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  const SizedBox(height: Sp.xxs),
                  Text('${h.area} · ${h.distanceKm} km · ★ ${h.rating}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                ]),
              ),
              const SizedBox(width: Sp.sm),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(inr(h.priceFor(app.slot) ?? h.prices.whereType<int>().first),
                    style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                Text(app.fullDay ? 'per night' : '${app.slot} hrs', style: TextStyle(fontSize: Fs.xs, color: C.muted)),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- 1. force update

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _StatusPage(
      icon: Icons.system_update_rounded,
      title: 'Time to update',
      body: 'This version of Checkdin is no longer supported. Update the app to keep booking. It takes less than a minute.',
      children: [
        WhiteCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('In the new version', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.xs),
            _bullet(Icons.speed_rounded, 'Faster booking', 'Fewer steps from search to confirmed'),
            _bullet(Icons.shield_rounded, 'Safer payments', 'Latest security updates for UPI and cards'),
            _bullet(Icons.bug_report_rounded, 'Fixes', 'Problems reported by guests are fixed'),
          ]),
        ),
        const SizedBox(height: Sp.lg),
        Text('Your bookings, credits and saved hotels stay as they are.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
      ],
      actions: [
        PillBtn('Update now', kind: BtnKind.lime, expand: true, height: 56, icon: Icons.arrow_forward_rounded, trailingIcon: true,
            onTap: () => _openStore(context)),
      ],
    );
  }
}

// ---------------------------------------------------------------- 2. maintenance

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    String s = 'maintenance';
    try {
      s = await api.appStatus();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _checking = false);
    if (s == 'ok') {
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
    } else {
      toast(context, 'Still updating. Try again in a few minutes.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStay = app.name.isNotEmpty && !app.bookingCancelled;
    return _StatusPage(
      icon: Icons.construction_rounded,
      iconBg: P.amberSoft,
      title: 'We\'re making Checkdin better',
      body: 'Checkdin is down for planned maintenance. We\'ll be back by 3:00 AM. Sorry for the wait.',
      children: [
        if (hasStay)
          WhiteCard(
            color: C.inkBg,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HAVE A STAY TODAY?', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1, color: C.faint)),
                  const SizedBox(height: Sp.xs),
                  const Text('Your booking is safe. Show your check-in OTP at the hotel as usual.',
                      style: TextStyle(fontSize: Fs.base, color: Colors.white, height: 1.4)),
                ]),
              ),
              const SizedBox(width: Sp.md),
              Text(app.checkinOtp, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: 2)),
            ]),
          ),
      ],
      actions: [
        PillBtn('Try again', kind: BtnKind.dark, expand: true, height: 56, loading: _checking, onTap: _checking ? null : _retry),
        const SizedBox(height: Sp.sm),
        TapLink('Call support', onTap: () => callHotel(context, kSupportPhone)),
      ],
    );
  }
}

// ---------------------------------------------------------------- 3. session expired

bool _expiredShowing = false;

/// "Please log in again". Shown when the server says the login is no longer valid.
void showSessionExpired() {
  final ctx = appNavigator.currentContext;
  if (ctx == null || _expiredShowing) return;
  _expiredShowing = true;
  _sheet<void>(
    ctx,
    Builder(
      builder: (sheet) => Column(children: [
        const _BigIcon(Icons.lock_clock_rounded),
        const SizedBox(height: Sp.xl),
        const Text('Please log in again', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
        const SizedBox(height: Sp.sm),
        Text('For your security, you\'ve been logged out. Log in again to see your bookings. Nothing is lost.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
        const SizedBox(height: Sp.xl),
        PillBtn('Log in', kind: BtnKind.dark, expand: true, height: 54, onTap: () {
          Navigator.pop(sheet);
          appNavigator.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
        }),
      ]),
    ),
    dismissible: false,
  ).whenComplete(() => _expiredShowing = false);
}

// ---------------------------------------------------------------- 4. notifications

class NotifyPermissionScreen extends StatefulWidget {
  const NotifyPermissionScreen({super.key});
  @override
  State<NotifyPermissionScreen> createState() => _NotifyPermissionScreenState();
}

class _NotifyPermissionScreenState extends State<NotifyPermissionScreen> {
  bool _asking = false;

  Future<void> _done({required bool ask}) async {
    if (ask) {
      setState(() => _asking = true);
      try {
        if (!kQaMode) await Permission.notification.request();
      } catch (_) {}
    }
    app.notifyAsked = true;
    await _saveBool('notifyAsked', true);
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  Widget _note(String title, String body, String when, {bool lime = false}) => Container(
        margin: const EdgeInsets.only(bottom: Sp.sm),
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.lg),
          boxShadow: const [BoxShadow(color: P.inkA6, blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset('assets/logo_icon.png', width: 32, height: 32),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w800))),
                Text(when, style: TextStyle(fontSize: Fs.xs, color: C.muted)),
              ]),
              const SizedBox(height: Sp.xxs),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: body),
                  if (lime)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.only(left: Sp.xs),
                        padding: const EdgeInsets.symmetric(horizontal: Sp.xs + 2),
                        decoration: BoxDecoration(color: P.lime, borderRadius: BorderRadius.circular(R.xs + 2)),
                        child: const Text('4827', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w800, color: P.ink)),
                      ),
                    ),
                ]),
                style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4),
              ),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(Sp.xl, pad.top + Sp.x4, Sp.xl, Sp.xxl),
              children: [
                Transform.rotate(angle: -0.02, child: _note('Booking confirmed', 'The Grand Residency · Today, 2 PM', 'now')),
                Transform.rotate(angle: 0.015, child: _note('Your check-in OTP', 'Show this at the desk:', '1:55 PM', lime: true)),
                Transform.rotate(angle: -0.01, child: _note('Check-out in 30 minutes', 'Need more time? Extend in one tap.', '4:30 PM')),
                const SizedBox(height: Sp.xxl),
                const Text('Don\'t miss your check-in', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
                const SizedBox(height: Sp.md),
                Text('Turn on notifications to get your check-in OTP, booking updates and a reminder before check-out. Only about your stays, no spam.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, pad.bottom + Sp.lg),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PillBtn('Turn on notifications', kind: BtnKind.lime, expand: true, height: 56, loading: _asking,
                  icon: Icons.notifications_active_rounded, onTap: _asking ? null : () => _done(ask: true)),
              const SizedBox(height: Sp.xs),
              Center(child: TapLink('Not now', onTap: () => _done(ask: false))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- 5. slot sold out

class SoldOutScreen extends StatelessWidget {
  const SoldOutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    final from = app.checkInHour;
    final options = [for (var x = from + 1; x <= from + 4 && x <= 23; x++) x];
    final price = h.priceFor(app.slot);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(Sp.xl, MediaQuery.of(context).padding.top + Sp.md, Sp.xl, Sp.xxl),
        children: [
          Align(alignment: Alignment.centerLeft, child: BackBtn(onTap: () => popTo(context, '/reserve'))),
          const SizedBox(height: Sp.lg),
          const Center(child: _BigIcon(Icons.event_busy_rounded, bg: P.amberSoft)),
          const SizedBox(height: Sp.xl),
          const Text('This slot just got booked', textAlign: TextAlign.center,
              style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
          const SizedBox(height: Sp.md),
          Text('Someone booked the last room at ${h.name} for ${app.whenShort} moments ago.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
          const SizedBox(height: Sp.md),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.pill)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, size: Ic.sm, color: P.ink),
                SizedBox(width: Sp.xs + 2),
                Text('You haven\'t been charged', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: P.ink)),
              ]),
            ),
          ),
          if (!app.fullDay && options.isNotEmpty) ...[
            const SizedBox(height: Sp.xxl),
            SectionLabel('Other times at ${h.name}'),
            Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
              for (final x in options)
                GestureDetector(
                  onTap: () {
                    Sim.soldOut = false;
                    app.set(() => app.hour = x);
                    popTo(context, '/reserve');
                    toast(context, 'Check-in changed to ${hourLabel(x)}');
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
                    decoration: BoxDecoration(color: C.card, border: Border.all(color: C.border, width: 1.5), borderRadius: BorderRadius.circular(R.lg)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${hourLabel(x, short: true)} – ${hourLabel(x + app.slot, short: true)}',
                          style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                      if (price != null) Text(inr(price), style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                ),
            ]),
          ],
          const SizedBox(height: Sp.xxl),
          SimilarStays(exclude: h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 6. price changed

/// Returns true when the guest accepts the new price.
Future<bool> showPriceChangedSheet(BuildContext context, int oldPrice, int newPrice) async {
  final r = await _sheet<bool>(
    context,
    Builder(
      builder: (sheet) => Column(children: [
        const _BigIcon(Icons.trending_up_rounded, bg: P.amberSoft),
        const SizedBox(height: Sp.xl),
        const Text('The price just changed', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
        const SizedBox(height: Sp.sm),
        Text('${app.hotel.name} updated its price for ${app.stayLabel} while you were booking.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
        const SizedBox(height: Sp.xl),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(inr(oldPrice), style: TextStyle(fontSize: Fs.xl, color: C.muted, decoration: TextDecoration.lineThrough)),
          const SizedBox(width: Sp.md),
          const Icon(Icons.arrow_forward_rounded, size: Ic.md),
          const SizedBox(width: Sp.md),
          Text(inr(newPrice), style: const TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: Sp.xs),
        Text('${newPrice > oldPrice ? '+' : '−'}${inr((newPrice - oldPrice).abs())} ${app.fullDay ? 'per night' : 'for this slot'}${app.rooms > 1 ? ', per room' : ''}',
            style: TextStyle(fontSize: Fs.sm, color: C.muted)),
        const SizedBox(height: Sp.xl),
        PillBtn('Continue at ${inr(newPrice)}', kind: BtnKind.dark, expand: true, height: 54, onTap: () => Navigator.pop(sheet, true)),
        const SizedBox(height: Sp.xs),
        TapLink('Go back', onTap: () => Navigator.pop(sheet, false)),
      ]),
    ),
  );
  return r == true;
}

// ---------------------------------------------------------------- 8. hotel unavailable

class HotelUnavailableScreen extends StatelessWidget {
  const HotelUnavailableScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final saved = app.saved.contains(h.id);
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.fromLTRB(Sp.xl, MediaQuery.of(context).padding.top + Sp.md, Sp.xl, Sp.xxl),
            children: [
              const Align(alignment: Alignment.centerLeft, child: BackBtn()),
              const SizedBox(height: Sp.lg),
              Stack(children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.33, 0.33, 0.33, 0, 0, //
                    0.33, 0.33, 0.33, 0, 0, //
                    0.33, 0.33, 0.33, 0, 0, //
                    0, 0, 0, 0.6, 0,
                  ]),
                  child: NetPhoto(coverOf(h), height: 180, radius: R.xl),
                ),
                Positioned(
                  left: Sp.md,
                  top: Sp.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs + 2),
                    decoration: BoxDecoration(color: P.ink, borderRadius: BorderRadius.circular(R.pill)),
                    child: const Text('Not taking bookings', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: Sp.xl),
              Text('${h.name} isn\'t taking bookings', style: const TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
              const SizedBox(height: Sp.sm),
              Text('The hotel may be closed for renovation or has left Checkdin. Your past bookings, receipts and refunds are safe.',
                  style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
              if (saved) ...[
                const SizedBox(height: Sp.lg),
                PillBtn('Remove from saved', kind: BtnKind.outline, height: 48, icon: Icons.favorite_rounded, onTap: () {
                  app.set(() => app.saved.remove(h.id));
                  undoToast(context, '${h.name} removed from saved', () => app.set(() => app.saved.add(h.id)));
                }),
              ],
              const SizedBox(height: Sp.xxl),
              SimilarStays(exclude: h),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- 9. permission help

/// "Turn it on in Settings" help for a permission the guest turned off.
Future<void> showPermissionHelp(BuildContext context, {required IconData icon, required String title, required String body}) {
  return _sheet<void>(
    context,
    Builder(
      builder: (sheet) => Column(children: [
        EmptyState(
          icon: icon,
          title: title,
          body: body,
          primary: 'Open settings',
          onPrimary: () async {
            await Geolocator.openAppSettings();
            if (sheet.mounted) Navigator.pop(sheet);
          },
          secondary: 'Not now',
          onSecondary: () => Navigator.pop(sheet),
        ),
      ]),
    ),
  );
}

/// Shows the right help when the camera or photos permission is off; other errors get a short message.
Future<void> photoAccessProblem(BuildContext context, Object error, {required bool camera}) async {
  final code = error is PlatformException ? error.code : '';
  if (code == 'camera_access_denied' || (camera && code.contains('denied'))) {
    await showPermissionHelp(context,
        icon: Icons.no_photography_rounded,
        title: 'Camera access is off',
        body: 'To take a photo, allow Checkdin to use the camera in Settings › Permissions › Camera.');
  } else if (code == 'photo_access_denied' || code.contains('denied')) {
    await showPermissionHelp(context,
        icon: Icons.hide_image_rounded,
        title: 'Photo access is off',
        body: 'To pick a photo, allow Checkdin to see your photos in Settings › Permissions › Photos and videos.');
  } else if (context.mounted) {
    toast(context, 'Couldn\'t open the ${camera ? 'camera' : 'gallery'}. Try again.');
  }
}

// ---------------------------------------------------------------- 11. rate the app

Future<void> showRateAppSheet(BuildContext context) {
  app.rateAsked = true;
  _saveBool('rateAsked', true);
  var stars = 0;
  return _sheet<void>(
    context,
    StatefulBuilder(
      builder: (sheet, set) => Column(children: [
        Image.asset('assets/logo_icon.png', width: 64, height: 64),
        const SizedBox(height: Sp.lg),
        const Text('Enjoying Checkdin?', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
        const SizedBox(height: Sp.sm),
        Text('Tap a star to rate. A quick rating helps more people find rooms by the hour.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
        const SizedBox(height: Sp.lg),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: '$i star${i > 1 ? 's' : ''}',
              iconSize: 40,
              onPressed: () => set(() => stars = i),
              icon: Icon(i <= stars ? Icons.star_rounded : Icons.star_border_rounded, color: i <= stars ? P.ink : C.faint),
            ),
        ]),
        const SizedBox(height: Sp.lg),
        if (stars >= 4)
          PillBtn('Rate on Play Store', kind: BtnKind.lime, expand: true, height: 54, onTap: () {
            Navigator.pop(sheet);
            _openStore(context);
          })
        else if (stars > 0)
          PillBtn('Tell us what to fix', kind: BtnKind.dark, expand: true, height: 54, onTap: () {
            Navigator.pop(sheet);
            Navigator.pushNamed(context, '/chat');
          })
        else
          const SizedBox(height: 54),
        const SizedBox(height: Sp.xs),
        TapLink('Not now', onTap: () => Navigator.pop(sheet)),
      ]),
    ),
  );
}

// ---------------------------------------------------------------- 12. links

/// True for booking and hotel links: checkdin.in/b/<id> and checkdin.in/hotel/<id>.
bool isAppLink(String? route) => route != null && (route.startsWith('/b/') || route.startsWith('/hotel/'));

/// Opens a shared link: checks the login, then shows the booking or hotel.
class LinkScreen extends StatefulWidget {
  final String path;
  const LinkScreen({super.key, required this.path});
  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

enum _LinkState { loading, needLogin, notFound }

class _LinkScreenState extends State<LinkScreen> {
  _LinkState _state = _LinkState.loading;
  String get _id => widget.path.split('/').where((x) => x.isNotEmpty).skip(1).firstOrNull ?? '';
  bool get _isBooking => widget.path.startsWith('/b/');

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    var status = 'ok';
    var loggedIn = false;
    try {
      final r = await Future.wait([api.appStatus(), api.restoreSession().then((v) => v ? 'in' : 'out')]);
      status = r[0];
      loggedIn = r[1] == 'in';
    } catch (_) {}
    if (!mounted) return;
    if (status != 'ok') {
      Navigator.pushReplacementNamed(context, status == 'update' ? '/force-update' : '/maintenance');
      return;
    }
    if (!_isBooking) {
      final all = [...hotels, ...fullDayOnly];
      final h = all.where((x) => x.id == _id).firstOrNull;
      if (h != null) app.set(() => app.hotel = h);
      Navigator.pushReplacementNamed(context, h == null || Sim.hotelUnavailable ? '/hotel-unavailable' : '/hotel');
      return;
    }
    if (!loggedIn) {
      setState(() => _state = _LinkState.needLogin);
      return;
    }
    if (_id == app.bookingId && !app.bookingCancelled) {
      Navigator.pushReplacementNamed(context, '/booking-detail');
    } else {
      setState(() => _state = _LinkState.notFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(Sp.xl, pad.top + Sp.md, Sp.xl, pad.bottom),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackBtn(onTap: () => Navigator.canPop(context) ? Navigator.pop(context) : goHome(context)),
          ),
          Expanded(
            child: Center(
              child: switch (_state) {
                _LinkState.loading => Column(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('assets/logo_icon.png', width: 64, height: 64),
                    const SizedBox(height: Sp.xl),
                    const Spinner(size: 26),
                    const SizedBox(height: Sp.lg),
                    Text(_isBooking ? 'Opening your booking…' : 'Opening the hotel…',
                        style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  ]),
                _LinkState.needLogin => EmptyState(
                    icon: Icons.lock_rounded,
                    title: 'Log in to see this booking',
                    body: 'Booking $_id needs you to log in with the mobile number it was booked with.',
                    primary: 'Log in',
                    onPrimary: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
                  ),
                _LinkState.notFound => EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'We couldn\'t find this booking',
                    body: 'Booking $_id isn\'t on this account. It may have been made with a different mobile number.',
                    primary: 'Go to My bookings',
                    onPrimary: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                      Navigator.pushNamed(context, '/bookings');
                    },
                    secondary: 'Talk to support',
                    onSecondary: () => Navigator.pushNamed(context, '/chat'),
                  ),
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- 13. what's new

bool _whatsNewChecked = false;

/// Once per app version, for people who updated (not on a fresh install).
Future<void> maybeShowWhatsNew(BuildContext context) async {
  if (_whatsNewChecked || kQaMode) return;
  _whatsNewChecked = true;
  if (_seenVersion == kAppVersion) return;
  await Future<void>.delayed(const Duration(milliseconds: 600));
  if (context.mounted) await showWhatsNew(context);
}

Future<void> showWhatsNew(BuildContext context) async {
  _seenVersion = kAppVersion;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString('seenVersion', kAppVersion);
  } catch (_) {}
  if (!context.mounted) return;
  await _sheet<void>(
    context,
    Builder(
      builder: (sheet) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
          decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.pill)),
          child: const Text('NEW · v$kAppVersion', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1, color: P.ink)),
        ),
        const SizedBox(height: Sp.md),
        const Text('What\'s new in Checkdin', style: TextStyle(fontSize: Fs.h2, fontWeight: FontWeight.w800)),
        const SizedBox(height: Sp.md),
        _bullet(Icons.person_add_alt_1_rounded, 'Book for someone else', 'Add the guest\'s name and number; they get the check-in OTP'),
        _bullet(Icons.currency_rupee_rounded, 'Track your refunds', 'See every refund step in Account › My refunds'),
        _bullet(Icons.photo_library_rounded, 'Real hotel photos', 'Rooms, bathrooms, lobby and outside for every stay'),
        _bullet(Icons.more_time_rounded, 'Extend before you arrive', 'Add hours even before check-in'),
        const SizedBox(height: Sp.lg),
        PillBtn('Got it', kind: BtnKind.dark, expand: true, height: 54, onTap: () => Navigator.pop(sheet)),
      ]),
    ),
  );
}

// ---------------------------------------------------------------- 14. missed check-in

class MissedCheckinScreen extends StatelessWidget {
  const MissedCheckinScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    final released = hourLabel(app.checkInHour + 1);
    Widget step(String t, String s, {required bool done, bool last = false, bool red = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: red ? P.redBright : (done ? P.ink : C.border), shape: BoxShape.circle),
              child: Icon(red ? Icons.close_rounded : Icons.check_rounded, size: 14, color: Colors.white),
            ),
            if (!last) Container(width: 2, height: 36, color: C.border),
          ]),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
              Text(s, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
            ]),
          ),
        ]);
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(Sp.xl, MediaQuery.of(context).padding.top + Sp.md, Sp.xl, Sp.xxl),
            children: [
              const TitleBar(title: 'Booking status'),
              const SizedBox(height: Sp.xl),
              WhiteCard(
                color: P.amberSoft,
                child: Row(children: [
                  const Icon(Icons.schedule_rounded, size: Ic.xl, color: P.ink),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('You missed your check-in', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, color: P.ink)),
                      const SizedBox(height: Sp.xxs),
                      Text('${h.name} · ${app.inDateLabel}', style: const TextStyle(fontSize: Fs.sm, color: P.ink2)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              WhiteCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  step('Booking confirmed', 'Booking ID ${app.bookingId}', done: true),
                  step('Check-in time', '${app.inTimeLabel}, ${app.inDateLabel}', done: true),
                  step('Room released', 'The hotel held your room until $released', done: false, red: true, last: true),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              WhiteCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('Refund', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                    Text(inr(0), style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: Sp.xs),
                  Text('Free cancellation ends 1 hour before check-in. A missed check-in (no-show) isn\'t refunded.',
                      style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
                  TapLink('See cancellation policy', onTap: () => Navigator.pushNamed(context, '/cancel-policy')),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              Text('Were you there on time, or did the hotel turn you away? Tell support and we\'ll look into it.',
                  style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
            ],
          ),
        ),
        BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: PillBtn('Call hotel', kind: BtnKind.outline, height: 52, icon: Icons.call_rounded, onTap: () => callHotel(context)),
              ),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: PillBtn('Talk to support', kind: BtnKind.dark, height: 52, onTap: () => Navigator.pushNamed(context, '/chat')),
              ),
            ]),
            TapLink('Book this hotel again', onTap: () {
              app.set(() => app.hour = null);
              Navigator.pushNamed(context, '/hotel');
            }),
          ]),
        ),
      ]),
    );
  }
}
