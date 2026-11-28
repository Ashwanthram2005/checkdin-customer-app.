import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state.dart';
import '../theme.dart';

/// Load the in-app location choice saved on this phone.
Future<void> loadLocationChoice() async {
  try {
    final p = await SharedPreferences.getInstance();
    app.useLocation = p.getBool('useLocation') ?? true;
  } catch (_) {}
}

Future<void> setLocationChoice(bool on) async {
  app.set(() {
    app.useLocation = on;
    if (!on && app.place == 'Current location') app.place = null;
  });
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool('useLocation', on);
  } catch (_) {}
}

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});
  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> with WidgetsBindingObserver {
  LocationPermission? _perm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the phone's settings: show the new permission.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    try {
      final p = await Geolocator.checkPermission();
      if (mounted) setState(() => _perm = p);
    } catch (_) {}
  }

  bool get _allowed => _perm == LocationPermission.whileInUse || _perm == LocationPermission.always;

  @override
  Widget build(BuildContext context) {
    final status = _perm == null
        ? 'Checking…'
        : _allowed
            ? (_perm == LocationPermission.always ? 'Allowed all the time' : 'Allowed while using the app')
            : 'Not allowed';
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, Sp.x3), children: [
            const TitleBar(title: 'Location'),
            const SizedBox(height: Sp.md),
            Text('Checkdin uses your location only while you search, to show the closest stays. We never track you in the background.',
                style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.45)),
            const SectionLabel('In Checkdin'),
            WhiteCard(
              child: Row(children: [
                IconTile(Icons.near_me_rounded, bg: app.useLocation ? C.limeSoft : C.bg),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Use my location', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                    const SizedBox(height: Sp.xxs),
                    Text(app.useLocation ? 'On · "Use my current location" works' : 'Off · we won\'t read your location',
                        style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  ]),
                ),
                BrandSwitch(value: app.useLocation, onChanged: (v) => setLocationChoice(v)),
              ]),
            ),
            const SectionLabel('Phone permission'),
            WhiteCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconTile(_allowed ? Icons.check_circle_outline_rounded : Icons.location_disabled_rounded,
                      bg: _allowed ? C.limeSoft : C.redSoft, fg: _allowed ? C.ink : C.red),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Location permission', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      const SizedBox(height: Sp.xxs),
                      Text(status, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: Sp.md),
                Text(
                    'Android only lets you take back a permission from the phone\'s settings. Tap below, open Permissions › Location and choose "Don\'t allow". Come back here and it updates.',
                    style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.45)),
                const SizedBox(height: Sp.md),
                PillBtn(_allowed ? 'Change in phone settings' : 'Allow in phone settings',
                    kind: BtnKind.dark, expand: true, icon: Icons.settings_rounded, trailingIcon: false, onTap: () => Geolocator.openAppSettings()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
