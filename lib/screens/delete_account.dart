import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

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
    setState(() => _working = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
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

  Widget _point(IconData icon, String text, {Color tile = C.bg}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(icon, bg: tile, size: 34, radius: 10),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.45)))),
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
              const SizedBox(height: 22),
              const Text('We\'re sorry to see you go', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 6),
              Text(app.phone.isEmpty ? 'This deletes your Checkdin account.' : 'This deletes the Checkdin account for +91 ${app.phone}.',
                  style: const TextStyle(fontSize: 14, color: C.muted)),
              if (_hasUpcoming) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(16)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.event_busy_outlined, color: C.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('You have an upcoming stay', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('Finish or cancel your booking at ${app.hotel.name} before deleting your account.',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFFA3241A), height: 1.4)),
                        const SizedBox(height: 10),
                        PillBtn('Go to My bookings', kind: BtnKind.dark, height: 38, fontSize: 13, onTap: () => Navigator.pushNamed(context, '/bookings')),
                      ]),
                    ),
                  ]),
                ),
              ],
              const SectionLabel('What happens'),
              WhiteCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(children: [
                  _point(Icons.person_off_outlined, 'Your profile and contact details are deleted within 30 days.', tile: C.redSoft),
                  _point(Icons.account_balance_wallet_outlined, 'Unused credits (${inr(120)}) and saved cards are removed. Credits can\'t be refunded.', tile: C.redSoft),
                  _point(Icons.receipt_long_outlined, 'Booking, payment and invoice records are kept only as long as Indian tax law requires.'),
                  _point(Icons.backup_outlined, 'Backups are cleared within 90 days.'),
                  _point(Icons.login_rounded, 'You can sign up again later with the same number, but your history won\'t come back.'),
                ]),
              ),
              const SectionLabel('Why are you leaving?'),
              for (final r in _reasons)
                GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: _reason == r ? C.limeSoft : C.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _reason == r ? C.ink : C.white, width: 1.5),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(r, style: TextStyle(fontSize: 14.5, fontWeight: _reason == r ? FontWeight.w800 : FontWeight.w600))),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _reason == r ? C.ink : C.white, border: Border.all(color: _reason == r ? C.ink : C.border, width: 2)),
                        child: _reason == r
                            ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle)))
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
                    fillColor: C.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              const SizedBox(height: 8),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                onTap: () => setState(() => _understand = !_understand),
                child: Row(children: [
                  Checkbox(value: _understand, activeColor: C.ink, checkColor: C.lime, onChanged: (v) => setState(() => _understand = v ?? false)),
                  const Expanded(
                    child: Text('I understand this can\'t be undone.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              const Text('Want only some data removed? Write to dpo@checkdin.in. We reply within 30 days.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted2, height: 1.45)),
            ],
          ),
        ),
        BottomBar(
          child: Row(children: [
            Expanded(child: PillBtn('Keep account', kind: BtnKind.outline, expand: true, onTap: () => Navigator.maybePop(context))),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _ok ? _delete : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _ok ? C.red : const Color(0xFFEFEFEA), borderRadius: BorderRadius.circular(999)),
                  child: Text(_working ? 'Deleting…' : 'Delete account',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ok ? C.white : C.muted2)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
