import 'package:flutter/material.dart';

import '../state.dart';
import '../avatar.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: app.name);
  late final _email = TextEditingController(text: app.email);
  String _gender = '';
  String _savedGender = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailBad {
    final e = _email.text.trim();
    return e.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(e);
  }

  bool get _changed => _name.text.trim() != app.name || _email.text.trim() != app.email || _gender != _savedGender;

  Widget _field(IconData icon, String label, Widget child, {Widget? trailing, bool error = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.lg),
          border: Border.all(color: error ? C.red : C.white, width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, size: Ic.md, color: C.muted),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, color: C.muted)),
              child,
            ]),
          ),
          if (trailing != null) trailing,
        ]),
      );

  final _kName = GlobalKey<ShakeState>(), _kEmail = GlobalKey<ShakeState>();
  bool _tried = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final nameBad = _name.text.trim().length < 2;
    final ok = _changed && !nameBad && !_emailBad;
    const inputDeco = InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: Sp.xs));
    const inputStyle = TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w600);
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24), children: [
            const TitleBar(title: 'Edit profile'),
            const SizedBox(height: Sp.xxl),
            Center(
              child: GestureDetector(
                onTap: () async {
                  await changePhoto(context);
                  if (mounted) setState(() {});
                },
                child: Stack(clipBehavior: Clip.none, children: [
                  const Avatar(size: 92, border: 5),
                  Positioned(
                      right: -10,
                      bottom: -10,
                      child: CircleBtn(icon: Icons.photo_camera_rounded, size: 32, tooltip: 'Change photo', onTap: () async {
                        await changePhoto(context);
                        if (mounted) setState(() {});
                      })),
                ]),
              ),
            ),
            const SizedBox(height: Sp.lg),
            Center(child: Text(_name.text.trim().isEmpty ? 'Your name' : _name.text.trim(), style: const TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800))),
            Center(child: Text('Tap the photo to change it', style: TextStyle(fontSize: Fs.base, color: C.muted))),
            const SectionLabel('Personal details'),
            Shake(key: _kName, child: _field(
              Icons.person_outline_rounded,
              'Full name',
              TextField(controller: _name, style: inputStyle, decoration: inputDeco, onChanged: (_) => setState(() {})),
            )),
            FieldError(_tried && nameBad ? 'Enter your name (at least 2 letters)' : null),
            const SizedBox(height: Sp.md),
            _field(
              Icons.smartphone_rounded,
              'Mobile number',
              Padding(
                padding: const EdgeInsets.only(top: Sp.xs),
                child: Text(app.phone.isEmpty ? '+91 98765 43210' : '+91 ${app.phone}', style: inputStyle.copyWith(color: C.muted)),
              ),
              trailing: Tag('✓ Verified', bg: C.limeBg, fg: C.ink),
            ),
            const SizedBox(height: Sp.md),
            Shake(key: _kEmail, child: _field(
              Icons.mail_outline_rounded,
              'Email (optional)',
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: inputStyle,
                decoration: inputDeco.copyWith(hintText: 'Add email for receipts'),
                onChanged: (_) => setState(() {}),
              ),
              error: _emailBad,
            )),
            if (_emailBad)
              Padding(
                padding: EdgeInsets.fromLTRB(Sp.sm, Sp.sm, Sp.sm, 0),
                child: Text('Please enter a valid email address.', style: TextStyle(fontSize: Fs.sm, color: C.red, fontWeight: FontWeight.w600)),
              ),
            const SectionLabel('Gender (optional)'),
            Row(
              children: ['Male', 'Female', 'Other'].map((g) {
                final on = _gender == g;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: g == 'Other' ? 0 : Sp.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = on ? '' : g),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? C.inkBg : C.card,
                          borderRadius: BorderRadius.circular(R.pill),
                          border: Border.all(color: on ? C.ink : P.border, width: 1.5),
                        ),
                        child: Text(g, style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: on ? C.lime : C.ink)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Sp.md),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/help'),
              child: Text.rich(
                TextSpan(style: TextStyle(fontSize: Fs.sm, color: C.muted2), children: [
                  TextSpan(text: 'To change your mobile number, '),
                  TextSpan(text: 'contact support', style: TextStyle(color: C.ink, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  TextSpan(text: '.'),
                ]),
              ),
            ),
            const SizedBox(height: Sp.lg),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/delete-account'),
                child: Text('Delete my account', style: TextStyle(color: C.red, fontWeight: FontWeight.w700, fontSize: Fs.md)),
              ),
            ),
          ]),
        ),
        BottomBar(
          child: PillBtn('Save changes',
              kind: BtnKind.dark,
              height: 56,
              expand: true,
              loading: _saving,
              onTap: !_changed
                  ? null
                  : !ok
                  ? () {
                      setState(() => _tried = true);
                      shakeAll([if (nameBad) _kName, if (_emailBad) _kEmail]);
                    }
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await api.updateProfile();
                      } on ApiError catch (e) {
                        if (mounted) toast(context, e.message);
                        return;
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                      if (!mounted) return;
                      app.set(() {
                        app.name = _name.text.trim();
                        app.email = _email.text.trim();
                      });
                      setState(() => _savedGender = _gender);
                      toast(context, 'Profile updated');
                    }),
        ),
      ]),
    );
  }
}
