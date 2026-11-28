import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const _reasons = [
    'I don\'t need hourly stays anymore',
    'I had a bad experience',
    'Too many messages or notifications',
    'Privacy concerns',
    'I\'ll make a new account',
    'Other reason',
  ];
  String? _reason;
  final _other = TextEditingController();
  bool _understand = false;
  bool _working = false;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  bool get _hasUpcoming => !app.bookingCancelled;

  bool get _ok =>
      !_hasUpcoming && _reason != null && (_reason != 'Other reason' || _other.text.trim().isNotEmpty) && _understand && !_working;

  Future<void> _delete() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await api.deleteAccount();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _working = false);
        toast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    app.set(() {
      app.name = '';
      app.email = '';
      app.phone = '';
      app.saved.clear();
      app.cards.clear();
      app.myReview = null;
      app.googleAccount = false;
    });
    toast(context, 'Your account has been deleted');
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Widget _point(IconData icon, String text, {Color? tile}) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.md),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(icon, bg: tile ?? C.bg, size: 34, radius: 10),
          const SizedBox(width: Sp.md),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: Sp.sm), child: Text(text, style: const TextStyle(fontSize: Fs.base, height: 1.45)))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Delete account'),
              const SizedBox(height: Sp.xxl),
              const Text('We\'re sorry to see you go', style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: Sp.sm),
              Text(app.phone.isEmpty ? 'This deletes your Checkdin account.' : 'This deletes the Checkdin account for +91 ${app.phone}.',
                  style: TextStyle(fontSize: Fs.md, color: C.muted)),
              if (_hasUpcoming) ...[
                const SizedBox(height: Sp.lg),
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.event_busy_rounded, color: C.red),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('You have an upcoming stay', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                        const SizedBox(height: Sp.xs),
                        Text('Finish or cancel your booking at ${app.hotel.name} before deleting your account.',
                            style: TextStyle(fontSize: Fs.sm, color: C.tx(P.redDark), height: 1.4)),
                        const SizedBox(height: Sp.md),
                        PillBtn('Go to My bookings', kind: BtnKind.dark, height: 38, fontSize: Fs.base, onTap: () => Navigator.pushNamed(context, '/bookings')),
                      ]),
                    ),
                  ]),
                ),
              ],
              const SectionLabel('What happens'),
              WhiteCard(
                padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.xs),
                child: Column(children: [
                  _point(Icons.person_off_rounded, 'Your profile and contact details are deleted within 30 days.', tile: C.redSoft),
                  _point(Icons.account_balance_wallet_rounded, 'Unused credits (${inr(120)}) and saved cards are removed. Credits can\'t be refunded.', tile: C.redSoft),
                  _point(Icons.receipt_long_rounded, 'Booking, payment and invoice records are kept only as long as Indian tax law requires.'),
                  _point(Icons.backup_rounded, 'Backups are cleared within 90 days.'),
                  _point(Icons.login_rounded, 'You can sign up again later with the same number, but your history won\'t come back.'),
                ]),
              ),
              const SectionLabel('Why are you leaving?'),
              for (final r in _reasons)
                GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: Sp.sm),
                    padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: 13),
                    decoration: BoxDecoration(
                      color: _reason == r ? C.limeSoft : C.card,
                      borderRadius: BorderRadius.circular(R.lg),
                      border: Border.all(color: _reason == r ? C.ink : C.white, width: 1.5),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(r, style: TextStyle(fontSize: Fs.md, fontWeight: _reason == r ? FontWeight.w700 : FontWeight.w600))),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _reason == r ? C.inkBg : C.card, border: Border.all(color: _reason == r ? C.ink : C.border, width: 2)),
                        child: _reason == r
                            ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle)))
                            : null,
                      ),
                    ]),
                  ),
                ),
              if (_reason == 'Other reason')
                TextField(
                  controller: _other,
                  maxLength: 100,
                  maxLines: 2,
                  minLines: 2,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tell us in a few words',
                    filled: true,
                    fillColor: C.card,
                    contentPadding: const EdgeInsets.all(Sp.lg),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide.none),
                  ),
                ),
              const SizedBox(height: Sp.sm),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
                onTap: () => setState(() => _understand = !_understand),
                child: Row(children: [
                  Checkbox(value: _understand, activeColor: C.ink, checkColor: C.lime, onChanged: (v) => setState(() => _understand = v ?? false)),
                  const Expanded(
                    child: Text('I understand this can\'t be undone.', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              Text('Want only some data removed? Write to dpo@checkdin.in. We reply within 30 days.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted2, height: 1.45)),
            ],
          ),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(child: PillBtn('Keep account', kind: BtnKind.outline, expand: true, onTap: () => Navigator.maybePop(context))),
            const SizedBox(width: Sp.md),
            Expanded(
              child: GestureDetector(
                onTap: _ok ? _delete : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _ok ? C.red : C.tint(P.line), borderRadius: BorderRadius.circular(R.pill)),
                  child: _working
                      ? Spinner(color: C.white)
                      : Text('Delete account', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: _ok ? C.white : C.muted2)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
