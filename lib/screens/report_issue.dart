import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state.dart';
import '../shake.dart';
import '../photos.dart';
import '../theme.dart';
import 'system_screens.dart';
import '../loading.dart';
import '../api/api.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const _types = [
    [Icons.no_meeting_room_rounded, 'Hotel refused check-in', 'Turned away at the desk'],
    [Icons.cleaning_services_rounded, 'Room not clean', 'Bed, bathroom or floor'],
    [Icons.ac_unit_rounded, 'Something isn\'t working', 'AC, TV, Wi-Fi, hot water'],
    [Icons.image_not_supported_rounded, 'Room not as shown', 'Different from the photos'],
    [Icons.payments_rounded, 'Charged extra', 'Asked to pay more at the hotel'],
    [Icons.schedule_rounded, 'Check-in delay', 'Kept waiting past my slot'],
    [Icons.shield_rounded, 'Safety concern', 'I felt unsafe or uncomfortable'],
    [Icons.more_horiz_rounded, 'Something else', 'Tell us what happened'],
  ];

  String? _type;
  final _text = TextEditingController();
  final List<XFile> _photos = [];
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ok => _type != null && _text.text.trim().length >= 15;
  final _kType = GlobalKey<ShakeState>(), _kText = GlobalKey<ShakeState>();
  bool _tried = false;

  void _trySubmit() {
    if (_ok) {
      _submit();
      return;
    }
    setState(() => _tried = true);
    shakeAll([if (_type == null) _kType, if (_text.text.trim().length < 15) _kText]);
  }

  Future<void> _addPhoto() async {
    try {
      final fs = await ImagePicker().pickMultiImage(imageQuality: 75, maxWidth: 1600);
      if (fs.isNotEmpty) setState(() => _photos.addAll(fs.take(4 - _photos.length)));
    } catch (e) {
      if (mounted) await photoAccessProblem(context, e, camera: false);
    }
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final String id;
    try {
      id = await api.reportIssue(_type!, _text.text.trim());
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        toast(context, e.message);
      }
      return;
    }
    if (!mounted) return;
    final urgent = _type == 'Hotel refused check-in' || _type == 'Safety concern';
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _TicketDone(id: id, type: _type!, urgent: urgent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = app.hotel;
    final urgent = _type == 'Hotel refused check-in' || _type == 'Safety concern';
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Report an issue'),
              const SizedBox(height: Sp.lg),
              WhiteCard(
                padding: const EdgeInsets.all(Sp.md),
                child: Row(children: [
                  SizedBox(width: 54, height: 54, child: NetPhoto(coverOf(app.hotel), height: 54, radius: R.md, w: 200)),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.name, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                      Text('${app.whenShort} · Booking ${app.bookingId}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                ]),
              ),
              const SectionLabel('What went wrong?'),
              Shake(key: _kType, child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  for (final t in _types)
                    GestureDetector(
                      onTap: () => setState(() => _type = t[1] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(Sp.md),
                        decoration: BoxDecoration(
                          color: _type == t[1] ? C.limeSoft : C.card,
                          borderRadius: BorderRadius.circular(R.lg),
                          border: Border.all(color: _type == t[1] ? C.ink : C.white, width: 1.5),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(t[0] as IconData, size: Ic.md),
                          const Spacer(),
                          Text(t[1] as String, style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, height: 1.2)),
                          const SizedBox(height: Sp.xxs),
                          Text(t[2] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: Fs.xs, color: C.muted)),
                        ]),
                      ),
                    ),
                ],
              )),
              FieldError(_tried && _type == null ? 'Pick what went wrong' : null),
              if (urgent) ...[
                const SizedBox(height: Sp.md),
                Container(
                  padding: const EdgeInsets.all(Sp.lg),
                  decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(R.lg)),
                  child: Row(children: [
                    Icon(Icons.priority_high_rounded, color: C.red),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text('This is urgent. Call us now and we\'ll sort it out while you\'re at the hotel.',
                          style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, color: C.tx(P.redDark), height: 1.4)),
                    ),
                    const SizedBox(width: Sp.sm),
                    PillBtn('Call', kind: BtnKind.dark, height: 38, fontSize: Fs.base, onTap: () => toast(context, 'Calling Checkdin support…')),
                  ]),
                ),
              ],
              const SectionLabel('Tell us more'),
              Shake(key: _kText, child: TextField(
                controller: _text,
                maxLines: 5,
                minLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: Fs.md, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'What happened, and when? The more detail, the faster we can help.',
                  hintStyle: const TextStyle(color: P.hint),
                  filled: true,
                  fillColor: C.card,
                  helperText: _text.text.trim().length < 15 ? 'At least 15 characters' : null,
                  contentPadding: const EdgeInsets.all(Sp.lg),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide(color: C.border, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide(color: C.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide(color: C.ink, width: 1.5)),
                ),
              )),
              FieldError(_tried && _text.text.trim().length < 15 ? 'Add a little more detail (at least 15 characters)' : null),
              SectionLabel('Add photos (optional)',
                  trailing: Text('${_photos.length}/4', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.muted))),
              SizedBox(
                height: 84,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  if (_photos.length < 4)
                    GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: Sp.sm),
                        decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(R.lg), border: Border.all(color: C.lime, width: 1.5)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_rounded),
                          SizedBox(height: Sp.xs),
                          Text('Add', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  for (var i = 0; i < _photos.length; i++)
                    Container(
                      width: 84,
                      margin: const EdgeInsets.only(right: Sp.sm),
                      child: Stack(fit: StackFit.expand, children: [
                        ClipRRect(borderRadius: BorderRadius.circular(R.lg), child: Image.file(File(_photos[i].path), fit: BoxFit.cover)),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle),
                              child: Icon(Icons.close_rounded, size: Ic.sm, color: C.white),
                            ),
                          ),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: Sp.sm),
              Text('Photos help us resolve room and cleanliness issues faster.', style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
            ],
          ),
        ),
        BottomBar(
          child: PillBtn(
            _ok ? 'Submit report' : 'Pick an issue and add details',
            loading: _sending,
            kind: BtnKind.dark,
            height: 54,
            expand: true,
            onTap: _sending ? null : _trySubmit,
          ),
        ),
      ]),
    );
  }
}

class _TicketDone extends StatelessWidget {
  final String id, type;
  final bool urgent;
  const _TicketDone({required this.id, required this.type, required this.urgent});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 60, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle),
                  child: const Icon(Icons.support_agent_rounded, size: Ic.xxl),
                ),
              ),
              const SizedBox(height: Sp.xl),
              const Text('We\'re on it', textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.h1, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: Sp.sm),
              Text(
                  urgent
                      ? 'Our team will call you within 10 minutes. Stay where you are if it\'s safe to do so.'
                      : 'We\'ve sent your report to our support team. You\'ll hear from us on WhatsApp within 2 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
              const SizedBox(height: Sp.xxl),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
                child: Column(children: [
                  for (final r in [
                    ['Ticket', id],
                    ['Issue', type],
                    ['Booking', app.bookingId],
                    ['Status', 'Open'],
                  ])
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: Sp.md),
                      decoration: BoxDecoration(border: r[0] == 'Status' ? null : Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        Text(r[0], style: TextStyle(fontSize: Fs.base, color: C.muted)),
                        const Spacer(),
                        r[0] == 'Status'
                            ? Tag('● Open', bg: C.limeSoft, fg: C.ink)
                            : Text(r[1], style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: Sp.md),
              Text('If the hotel can\'t fix it, you may get a refund, credits or another room, as per our Cancellation & Refund Policy.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted2, height: 1.45)),
            ],
          ),
        ),
        BottomBar(child: PillBtn('Done', kind: BtnKind.dark, height: 54, expand: true, onTap: () => Navigator.pop(context))),
      ]),
    );
  }
}
