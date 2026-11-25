import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'state.dart';
import 'theme.dart';

/// The guest's profile photo, or their initial on lime.
class Avatar extends StatelessWidget {
  final double size;
  final double border;
  const Avatar({super.key, this.size = 44, this.border = 0});
  @override
  Widget build(BuildContext context) {
    final p = app.photoPath;
    final initial = app.name.trim().isEmpty ? 'A' : app.name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.lime,
        shape: BoxShape.circle,
        border: border > 0 ? Border.all(color: C.white, width: border) : null,
      ),
      child: p != null
          ? Image.file(File(p), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(initial))
          : Text(initial, style: TextStyle(fontSize: size * 0.41, fontWeight: FontWeight.w800, color: const Color(0xFF111111))),
    );
  }
}

/// Take, choose or remove the profile photo.
Future<void> changePhoto(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(ctx).padding.bottom),
      decoration: BoxDecoration(color: C.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profile photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.ink)),
        const SizedBox(height: 10),
        for (final o in [
          [Icons.photo_camera_outlined, 'Take a photo', 'camera'],
          [Icons.photo_library_outlined, 'Choose from gallery', 'gallery'],
          if (app.photoPath != null) [Icons.delete_outline_rounded, 'Remove photo', 'remove'],
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IconTile(o[0] as IconData, bg: o[2] == 'remove' ? C.redSoft : C.bg),
            title: Text(o[1] as String, style: TextStyle(fontWeight: FontWeight.w700, color: o[2] == 'remove' ? C.red : C.ink)),
            onTap: () => Navigator.pop(ctx, o[2] as String),
          ),
      ]),
    ),
  );
  if (choice == null) return;
  if (choice == 'remove') {
    app.set(() => app.photoPath = null);
    return;
  }
  try {
    final f = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (f == null) return;
    app.set(() => app.photoPath = f.path);
    if (context.mounted) toast(context, 'Profile photo updated');
  } catch (_) {
    if (context.mounted) toast(context, 'Couldn\'t open the camera or gallery. Check app permissions.');
  }
}
