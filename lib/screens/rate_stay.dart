import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

/// Arguments: {'hotel': String, 'when': String, 'rating': int}. Pops with the overall rating (int) when posted.
class RateStayScreen extends StatefulWidget {
  const RateStayScreen({super.key});
  @override
  State<RateStayScreen> createState() => _RateStayScreenState();
}

class _RateStayScreenState extends State<RateStayScreen> {
  String _hotel = 'Your stay';
  String _when = '';
  int _overall = 0;
  bool _argsRead = false;
  final Map<String, int> _cat = {'Cleanliness': 0, 'Comfort': 0, 'Staff & service': 0, 'Value for money': 0, 'Location': 0};
  final Set<String> _tags = {};
  final _text = TextEditingController();
  final List<XFile> _photos = [];
  bool _anon = false;
  final _picker = ImagePicker();

  static const _good = [
    'Clean room', 'Comfy bed', 'Cool AC', 'Clean bathroom', 'Friendly staff',
    'Quick check-in', 'Privacy', 'Good location', 'Value for money', 'Fast Wi-Fi',
  ];
  static const _bad = [
    'Room not clean', 'Check-in delay', 'AC not cooling', 'Noisy', 'Unhelpful staff',
    'Bathroom issues', 'Not like the photos', 'Wi-Fi didn\'t work',
  ];
  static const _words = ['', 'Terrible', 'Poor', 'Okay', 'Good', 'Loved it!'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final a = ModalRoute.of(context)?.settings.arguments;
    if (a is Map) {
      _hotel = (a['hotel'] as String?) ?? _hotel;
      _when = (a['when'] as String?) ?? '';
      _overall = (a['rating'] as int?) ?? 0;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _happy => _overall == 0 || _overall >= 4;

  Future<void> _addPhotos() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(ctx).padding.bottom),
        decoration: const BoxDecoration(color: C.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconTile(Icons.photo_camera_outlined, bg: C.lime),
            title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconTile(Icons.photo_library_outlined),
            title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (src == null) return;
    try {
      final left = 6 - _photos.length;
      if (src == ImageSource.camera) {
        final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
        if (f != null) setState(() => _photos.add(f));
      } else {
        final fs = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
        if (fs.isNotEmpty) setState(() => _photos.addAll(fs.take(left)));
        if (fs.length > left && mounted) toast(context, 'You can add up to 6 photos');
      }
    } catch (_) {
      if (mounted) toast(context, 'Couldn\'t open photos. Check app permissions.');
    }
  }

  Widget _stars(int value, double size, ValueChanged<int> onTap) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => GestureDetector(
            onTap: () => onTap(i + 1),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.06),
              child: AnimatedScale(
                scale: i < value ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 150),
                child: Icon(i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: size, color: i < value ? C.gold : C.faint),
              ),
            ),
          ),
        ),
      );

  Widget _chip(String t) {
    final on = _tags.contains(t);
    return GestureDetector(
      onTap: () => setState(() => on ? _tags.remove(t) : _tags.add(t)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: on ? (_happy ? C.lime : C.redSoft) : C.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? (_happy ? C.lime : C.red) : C.border, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (on) ...[Icon(_happy ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded, size: 14), const SizedBox(width: 6)],
          Text(t, style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textLen = _text.text.trim().length;
    final textOk = textLen == 0 || textLen >= 20;
    final canPost = _overall > 0 && textOk;
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Rate your stay'),
              const SizedBox(height: 18),
              WhiteCard(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const SizedBox(width: 64, height: 64, child: PhotoPlaceholder(height: 64, radius: 14, label: '')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_hotel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      if (_when.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(_when, style: const TextStyle(fontSize: 12.5, color: C.muted)),
                      ],
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Center(
                child: Column(children: [
                  const Text('How was your stay?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  _stars(_overall, 46, (v) => setState(() {
                        if (_happy != (v >= 4)) _tags.clear();
                        _overall = v;
                      })),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      key: ValueKey(_overall),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: _overall == 0 ? Colors.transparent : (_overall >= 4 ? C.lime : C.limeSoft),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(_overall == 0 ? 'Tap a star to rate' : _words[_overall],
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800, color: _overall == 0 ? C.muted : C.ink)),
                    ),
                  ),
                ]),
              ),
              const SectionLabel('Rate the details'),
              WhiteCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(children: [
                  for (final e in _cat.entries.toList().asMap().entries)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: e.key == _cat.length - 1 ? null : const Border(bottom: BorderSide(color: C.line)),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(e.value.key, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                        _stars(e.value.value, 24, (v) => setState(() => _cat[e.value.key] = v)),
                      ]),
                    ),
                ]),
              ),
              SectionLabel(_happy ? 'What was good?' : 'What could be better?'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in (_happy ? _good : _bad)) _chip(t)]),
              const SectionLabel('Write a review'),
              TextField(
                controller: _text,
                maxLines: 5,
                minLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14.5, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Tell other guests about the room, check-in and staff…',
                  hintStyle: const TextStyle(color: Color(0xFF8A8A82)),
                  filled: true,
                  fillColor: C.white,
                  errorText: textOk ? null : 'Write at least 20 characters (${20 - textLen} more)',
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.border, width: 1.5)),
                  enabledBorder:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.border, width: 1.5)),
                  focusedBorder:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.ink, width: 1.5)),
                ),
              ),
              SectionLabel('Add photos from your stay',
                  trailing: Text('${_photos.length}/6', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.muted))),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  if (_photos.length < 6)
                    GestureDetector(
                      onTap: _addPhotos,
                      child: Container(
                        decoration: BoxDecoration(
                          color: C.limeSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: C.lime, width: 1.5),
                        ),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined, size: 26),
                          SizedBox(height: 6),
                          Text('Add photos', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                  for (var i = 0; i < _photos.length; i++)
                    Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_photos[i].path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 16, color: C.white),
                          ),
                        ),
                      ),
                    ]),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Show the room, bathroom or view. Please avoid faces and ID cards.',
                  style: TextStyle(fontSize: 12, color: C.muted2)),
              const SizedBox(height: 16),
              WhiteCard(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Post anonymously', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Your name won\'t be shown with this review.', style: TextStyle(fontSize: 12.5, color: C.muted)),
                    ]),
                  ),
                  BrandSwitch(value: _anon, onChanged: (v) => setState(() => _anon = v)),
                ]),
              ),
            ],
          ),
        ),
        BottomBar(
          child: PillBtn(
            _overall == 0 ? 'Rate your stay to post' : 'Post review',
            kind: BtnKind.dark,
            expand: true,
            onTap: canPost
                ? () {
                    FocusScope.of(context).unfocus();
                    toast(context, 'Review posted. Thanks for helping other guests!');
                    Navigator.pop(context, _overall);
                  }
                : null,
          ),
        ),
      ]),
    );
  }
}
