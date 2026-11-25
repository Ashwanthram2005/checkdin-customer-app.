import 'package:flutter/material.dart';

import '../appearance.dart';
import '../theme.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  void _pick(AppTheme m) {
    Appearance.set(m);
    setState(() {});
  }

  Widget _preview(bool dark) {
    final bg = Color(dark ? 0xFF10120F : 0xFFF5F6F0);
    final card = Color(dark ? 0xFF1B1E19 : 0xFFFFFFFF);
    final ink = Color(dark ? 0xFFF1F2EC : 0xFF111111);
    final lime = Color(dark ? 0xFF56661A : 0xFFD1F148);
    Widget bar(double w, Color c, [double h = 6]) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)));
    return Container(
      width: 64,
      height: 84,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        bar(28, ink),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(7)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            bar(34, ink.withAlpha(204), 4),
            const SizedBox(height: 4),
            bar(22, ink.withAlpha(102), 4),
          ]),
        ),
        const Spacer(),
        bar(double.infinity, lime, 12),
      ]),
    );
  }

  Widget _systemPreview() => SizedBox(
        width: 64,
        height: 84,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            _preview(false),
            ClipPath(clipper: _Diagonal(), child: _preview(true)),
          ]),
        ),
      );

  Widget _option(AppTheme m, String sub) {
    final on = Appearance.mode == m;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WhiteCard(
        radius: 22,
        padding: const EdgeInsets.all(12),
        border: Border.all(color: on ? C.ink : Colors.transparent, width: 2),
        onTap: () => _pick(m),
        child: Row(children: [
          m == AppTheme.system ? _systemPreview() : _preview(m == AppTheme.dark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(sub, style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? C.inkBg : Colors.transparent,
              border: Border.all(color: on ? C.inkBg : C.faint, width: 2),
            ),
            child: on ? Icon(Icons.check_rounded, size: 15, color: C.lime) : null,
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
          const TitleBar(title: 'Appearance'),
          const SizedBox(height: 10),
          Text('Choose how Checkdin looks on this phone.', style: TextStyle(fontSize: 14, color: C.muted, height: 1.45)),
          const SectionLabel('Theme'),
          _option(AppTheme.light, 'Bright and clear — best in daylight.'),
          _option(AppTheme.dark, 'Easy on the eyes at night and saves battery.'),
          _option(AppTheme.system,
              'Follows your phone\'s setting${Appearance.mode == AppTheme.system ? ' (now ${Appearance.systemIsDark ? 'dark' : 'light'})' : ''}.'),
        ]),
      ),
    );
  }
}

class _Diagonal extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(_) => false;
}
