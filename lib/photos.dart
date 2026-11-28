import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'state.dart';
import 'theme.dart';

/// Sample hotel photos for the prototype (free Unsplash photos, loaded over
/// the internet and cached on the phone). The real backend will send each
/// hotel's own photo URLs; only this file changes then.
String photoUrl(String id, {int w = 900}) => 'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=$w&q=70';

const _rooms = [
  '1618773928121-c32242e63f39',
  '1611892440504-42a792e24d32',
  '1631049307264-da0ec9d70304',
  '1629140727571-9b5c6f6267b4',
  '1578683010236-d716f9a3f461',
  '1631049552057-403cdb8f0658',
  '1583847268964-b28dc8f51f92',
  '1711059985570-4c32ed12a12c',
];
const _baths = [
  '1584622650111-993a426fbf0a',
  '1507652313519-d4e9174996dd',
  '1587527901949-ab0341697c1e',
  '1576698483491-8c43f0862543',
  '1564540583246-934409427776',
];
const _lobby = ['1621293954908-907159247fc8', '1583847268964-b28dc8f51f92'];
const _outside = [
  '1566073771259-6a8506099945',
  '1551882547-ff40c63fe5fa',
  '1535827841776-24afc1e255ac',
  '1551016043-06ec2173531b',
  '1571896349842-33c89424de2d',
];

int _seed(Hotel h) => hotels.indexWhere((x) => x.id == h.id).clamp(0, 99);

/// 8 photos per hotel: 4 room, 2 bathroom, 1 lobby, 1 outside.
/// Each entry: [category, caption, photo id].
List<List<String>> photosFor(Hotel h) {
  final k = _seed(h);
  String r(int i) => _rooms[(k * 2 + i) % _rooms.length];
  String b(int i) => _baths[(k + i) % _baths.length];
  return [
    ['Room', 'Room · king bed', r(0)],
    ['Room', 'Bed and pillows', r(1)],
    ['Room', 'Window side', r(2)],
    ['Room', 'Seating corner', r(3)],
    ['Bathroom', 'Attached bathroom', b(0)],
    ['Bathroom', 'Hot water and toiletries', b(1)],
    ['Lobby', 'Reception · 24×7 desk', _lobby[k % _lobby.length]],
    ['Outside', 'Hotel entrance', _outside[k % _outside.length]],
  ];
}

/// Main photo for a hotel (its first room photo).
String coverOf(Hotel h) => photosFor(h)[0][2];

/// A hotel photo. Grey while loading; falls back to the placeholder offline.
class NetPhoto extends StatelessWidget {
  final String id;
  final double? height, width;
  final double radius;
  final int w;
  const NetPhoto(this.id, {super.key, this.height, this.width, this.radius = 0, this.w = 900});

  @override
  Widget build(BuildContext context) {
    final fallback = PhotoPlaceholder(height: height ?? 120, radius: radius, label: '');
    if (kQaMode) return SizedBox(height: height, width: width, child: fallback);
    final img = CachedNetworkImage(
      imageUrl: photoUrl(id, w: w),
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: w,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (_, __) => Container(color: C.tint(P.grey87)),
      errorWidget: (_, __, ___) => fallback,
    );
    if (radius == 0) return img;
    return ClipPath(clipper: ShapeBorderClipper(shape: smooth(radius)), child: img);
  }
}
