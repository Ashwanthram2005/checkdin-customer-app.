import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../state.dart';
import '../theme.dart';
import 'location_settings.dart';

/// Friendly empty / error block used across screens.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final String? primary, secondary;
  final VoidCallback? onPrimary, onSecondary;
  final Color? _tile;
  Color get tile => _tile ?? C.limeBg;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.primary,
    this.onPrimary,
    this.secondary,
    this.onSecondary,
    Color? tile,
  }) : _tile = tile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.xxl, Sp.x4, Sp.xxl, Sp.xxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: tile, shape: BoxShape.circle),
          child: Icon(icon, size: Ic.xxl, color: C.ink),
        ),
        const SizedBox(height: Sp.xl),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: Sp.sm),
        Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
        if (primary != null) ...[
          const SizedBox(height: Sp.xl),
          PillBtn(primary!, kind: BtnKind.dark, height: 50, onTap: onPrimary),
        ],
        if (secondary != null) ...[
          const SizedBox(height: Sp.sm),
          TextButton(
            onPressed: onSecondary,
            child: Text(secondary!, style: TextStyle(color: C.ink, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ],
      ]),
    );
  }
}

/// Covers the app with a "You're offline" screen while there is no connection.
class OfflineGate extends StatefulWidget {
  final Widget child;
  const OfflineGate({super.key, required this.child});
  @override
  State<OfflineGate> createState() => _OfflineGateState();
}

class _OfflineGateState extends State<OfflineGate> {
  bool _offline = false;
  bool _checking = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOff(List<ConnectivityResult> r) => r.isEmpty || r.every((x) => x == ConnectivityResult.none);

  @override
  void initState() {
    super.initState();
    if (kQaMode) return;
    Connectivity().checkConnectivity().then((r) {
      if (mounted) setState(() => _offline = _isOff(r));
    });
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _offline = _isOff(r));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    final r = await Connectivity().checkConnectivity();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {
      _offline = _isOff(r);
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_offline)
        Positioned.fill(
          child: Material(
            color: C.bg,
            child: SafeArea(
              child: Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  tile: C.limeSoft,
                  title: 'You\'re offline',
                  body: 'Check your mobile data or Wi-Fi. Your search and booking details are safe, and we\'ll pick up where you left off.',
                  primary: _checking ? 'Checking…' : 'Try again',
                  onPrimary: _checking ? null : _retry,
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// Asks for location. Returns true when the app may use it; shows the right help otherwise.
Future<bool> useMyLocation(BuildContext context) async {
  if (!app.useLocation) {
    final on = await _locationSheet(
      context,
      icon: Icons.location_disabled_rounded,
      title: 'Location is off in Checkdin',
      body: 'You turned off location for Checkdin. Turn it back on to see stays near you, or search by area or landmark.',
      primary: 'Turn on location',
    );
    if (on != true) return false;
    await setLocationChoice(true);
    if (!context.mounted) return false;
  }
  if (!await Geolocator.isLocationServiceEnabled()) {
    if (context.mounted) {
      await _locationSheet(
        context,
        icon: Icons.location_off_rounded,
        title: 'Turn on location',
        body: 'Your phone\'s location is off. Turn it on to see stays near you, or search by area instead.',
        primary: 'Open location settings',
        onPrimary: Geolocator.openLocationSettings,
      );
    }
    return false;
  }
  var p = await Geolocator.checkPermission();
  if (p == LocationPermission.denied) {
    if (!context.mounted) return false;
    final go = await _locationSheet(
      context,
      icon: Icons.near_me_rounded,
      title: 'Find stays near you',
      body: 'Checkdin uses your location only while you search, to show the closest hotels. We never track you in the background.',
      primary: 'Allow location',
    );
    if (go != true) return false;
    p = await Geolocator.requestPermission();
  }
  if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
    if (context.mounted) {
      await _locationSheet(
        context,
        icon: Icons.location_disabled_rounded,
        title: 'Location permission is off',
        body: p == LocationPermission.deniedForever
            ? 'You\'ve turned off location for Checkdin. Turn it on in Settings › Permissions › Location, or search by area.'
            : 'Without location we can\'t show stays near you. You can still search by area, landmark or hotel.',
        primary: p == LocationPermission.deniedForever ? 'Open app settings' : null,
        onPrimary: Geolocator.openAppSettings,
      );
    }
    return false;
  }
  return true;
}

Future<bool?> _locationSheet(BuildContext context,
    {required IconData icon, required String title, required String body, String? primary, Future<bool> Function()? onPrimary}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + MediaQuery.of(ctx).padding.bottom),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs))),
        EmptyState(
          icon: icon,
          title: title,
          body: body,
          primary: primary,
          onPrimary: () async {
            if (onPrimary != null) await onPrimary();
            if (ctx.mounted) Navigator.pop(ctx, true);
          },
          secondary: 'Search by area instead',
          onSecondary: () => Navigator.pop(ctx, false),
        ),
      ]),
    ),
  );
}
