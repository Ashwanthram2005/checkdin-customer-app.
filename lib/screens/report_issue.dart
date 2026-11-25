import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state.dart';
import '../theme.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const _types = [
    [Icons.no_meeting_room_outlined, 'Hotel refused check-in', 'Turned away at the desk'],
    [Icons.cleaning_services_outlined, 'Room not clean', 'Bed, bathroom or floor'],
    [Icons.ac_unit_rounded, 'Something isn\'t working', 'AC, TV, Wi-Fi, hot water'],
    [Icons.image_not_supported_outlined, 'Room not as shown', 'Different from the photos'],
    [Icons.payments_outlined, 'Charged extra', 'Asked to pay more at the hotel'],
    [Icons.schedule_rounded, 'Check-in delay', 'Kept waiting past my slot'],
    [Icons.shield_outlined, 'Safety concern', 'I felt unsafe or uncomfortable'],
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

  Future<void> _addPhoto() async {
    try {
      final fs = await ImagePicker().pickMultiImage(imageQuality: 75, maxWidth: 1600);
      if (fs.isNotEmpty) setState(() => _photos.addAll(fs.take(4 - _photos.length)));
    } catch (_) {
      if (mounted) toast(context, 'Couldn\'t open photos. Check app permissions.');
    }
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final id = 'CKD-T${1000 + math.Random().nextInt(9000)}';
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
              const SizedBox(height: 16),
              WhiteCard(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const SizedBox(width: 54, height: 54, child: PhotoPlaceholder(height: 54, radius: 12, label: '')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('${app.whenShort} · Booking CKD-48213', style: const TextStyle(fontSize: 12.5, color: C.muted)),
                    ]),
                  ),
                ]),
              ),
              const SectionLabel('What went wrong?'),
              GridView.count(
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _type == t[1] ? C.limeSoft : C.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _type == t[1] ? C.ink : C.white, width: 1.5),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(t[0] as IconData, size: 22),
                          const Spacer(),
                          Text(t[1] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.2)),
                          const SizedBox(height: 2),
                          Text(t[2] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: C.muted)),
                        ]),
                      ),
                    ),
                ],
              ),
              if (urgent) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.priority_high_rounded, color: C.red),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('This is urgent. Call us now and we\'ll sort it out while you\'re at the hotel.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFA3241A), height: 1.4)),
                    ),
                    const SizedBox(width: 8),
                    PillBtn('Call', kind: BtnKind.dark, height: 38, fontSize: 13, onTap: () => toast(context, 'Calling Checkdin support…')),
                  ]),
                ),
              ],
              const SectionLabel('Tell us more'),
              TextField(
                controller: _text,
                maxLines: 5,
                minLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14.5, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'What happened, and when? The more detail, the faster we can help.',
                  hintStyle: const TextStyle(color: Color(0xFF8A8A82)),
                  filled: true,
                  fillColor: C.white,
                  helperText: _text.text.trim().length < 15 ? 'At least 15 characters' : null,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.border, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.ink, width: 1.5)),
                ),
              ),
              SectionLabel('Add photos (optional)',
                  trailing: Text('${_photos.length}/4', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.muted))),
              SizedBox(
                height: 84,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  if (_photos.length < 4)
                    GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: C.limeSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.lime, width: 1.5)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined),
                          SizedBox(height: 4),
                          Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                  for (var i = 0; i < _photos.length; i++)
                    Container(
                      width: 84,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(fit: StackFit.expand, children: [
                        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_photos[i].path), fit: BoxFit.cover)),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 15, color: C.white),
                            ),
                          ),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('Photos help us resolve room and cleanliness issues faster.', style: TextStyle(fontSize: 12, color: C.muted2)),
            ],
          ),
        ),
        BottomBar(
          child: PillBtn(
            _sending ? 'Sending…' : (_ok ? 'Submit report' : 'Pick an issue and add details'),
            kind: BtnKind.dark,
            height: 54,
            expand: true,
            onTap: _ok && !_sending ? _submit : null,
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
                  decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle),
                  child: const Icon(Icons.support_agent_rounded, size: 44),
                ),
              ),
              const SizedBox(height: 20),
              const Text('We\'re on it', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              Text(
                  urgent
                      ? 'Our team will call you within 10 minutes. Stay where you are if it\'s safe to do so.'
                      : 'We\'ve sent your report to our support team. You\'ll hear from us on WhatsApp within 2 hours.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5, color: C.muted, height: 1.5)),
              const SizedBox(height: 22),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(children: [
                  for (final r in [
                    ['Ticket', id],
                    ['Issue', type],
                    ['Booking', 'CKD-48213'],
                    ['Status', 'Open'],
                  ])
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: r[0] == 'Status' ? null : const Border(bottom: BorderSide(color: C.line))),
                      child: Row(children: [
                        Text(r[0], style: const TextStyle(fontSize: 13.5, color: C.muted)),
                        const Spacer(),
                        r[0] == 'Status'
                            ? const Tag('● Open', bg: C.limeSoft, fg: C.ink)
                            : Text(r[1], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              const Text('If the hotel can\'t fix it, you may get a refund, credits or another room, as per our Cancellation & Refund Policy.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: C.muted2, height: 1.45)),
            ],
          ),
        ),
        BottomBar(child: PillBtn('Done', kind: BtnKind.dark, height: 54, expand: true, onTap: () => Navigator.pop(context))),
      ]),
    );
  }
}
