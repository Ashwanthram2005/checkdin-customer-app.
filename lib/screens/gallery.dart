import 'package:flutter/material.dart';

import '../state.dart';
import '../photos.dart';
import '../theme.dart';

/// This hotel's photos: [category, caption, photo id].
List<List<String>> get galleryPhotos => photosFor(app.hotel);

class _Photo extends StatelessWidget {
  final int i;
  final double radius;
  final bool big;
  const _Photo(this.i, {this.radius = 0, this.big = false});
  @override
  Widget build(BuildContext context) {
    final p = galleryPhotos[i];
    if (!big) return NetPhoto(p[2], radius: radius, w: 600);
    return NetPhoto(p[2], w: 1400);
  }
}

/// Grid of all photos, grouped by category. Tapping one opens the full-screen viewer.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _cat = 'All';

  @override
  Widget build(BuildContext context) {
    final cats = ['All', ...{for (final p in galleryPhotos) p[0] as String}];
    final idx = [for (var i = 0; i < galleryPhotos.length; i++) if (_cat == 'All' || galleryPhotos[i][0] == _cat) i];
    return Scaffold(
      body: Column(children: [
        SheetHeader(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TitleBar(title: app.hotel.name),
            const SizedBox(height: Sp.md),
            SizedBox(
              height: 38,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final c in cats)
                  Padding(
                    padding: const EdgeInsets.only(right: Sp.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _cat = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cat == c ? C.inkBg : C.card,
                          borderRadius: BorderRadius.circular(R.pill),
                          border: Border.all(color: _cat == c ? C.ink : C.border, width: 1.5),
                        ),
                        child: Text(
                            c == 'All' ? 'All · ${galleryPhotos.length}' : '$c · ${galleryPhotos.where((p) => p[0] == c).length}',
                            style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w700, color: _cat == c ? C.lime : C.ink)),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05),
            itemCount: idx.length,
            itemBuilder: (_, k) => GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewer(start: idx[k], only: idx))),
              child: Hero(tag: photoTag(idx[k]), child: _Photo(idx[k], radius: 18)),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Full-screen swipeable, pinch-to-zoom viewer.
/// Hero tag for a hotel photo. The first photo shares its tag with the hotel's
/// card in results, so the card photo grows into the hotel page.
String photoTag(int i) => i == 0 ? hotelHeroTag(app.hotel.id) : 'photo$i';
String hotelHeroTag(String hotelId) => 'hotel-photo-$hotelId';

class PhotoViewer extends StatefulWidget {
  final int start;
  final List<int>? only;
  const PhotoViewer({super.key, this.start = 0, this.only});
  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final List<int> _ids = widget.only ?? List.generate(galleryPhotos.length, (i) => i);
  late int _page = _ids.indexOf(widget.start).clamp(0, _ids.length - 1).toInt();
  late final PageController _pc = PageController(initialPage: _page);
  final _tc = <int, TransformationController>{};
  double _drag = 0;
  bool _dragging = false;
  TransformationController _ctl(int i) => _tc.putIfAbsent(i, () => TransformationController());

  @override
  void dispose() {
    _pc.dispose();
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final p = galleryPhotos[_ids[_page]];
    final fade = (1 - _drag.abs() / 500).clamp(0.3, 1.0);
    return Scaffold(
      backgroundColor: Color.fromRGBO(14, 14, 14, fade),
      body: Stack(children: [
        PageView.builder(
          controller: _pc,
          itemCount: _ids.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Center(
            child: InteractiveViewer(
              transformationController: _ctl(i),
              minScale: 1,
              maxScale: 4,
              // Swipe down (or up) to close when the photo isn't zoomed in.
              onInteractionUpdate: (d) {
                if (d.pointerCount == 1 && _ctl(i).value.getMaxScaleOnAxis() <= 1.01) {
                  setState(() {
                    _dragging = true;
                    _drag += d.focalPointDelta.dy;
                  });
                }
              },
              onInteractionEnd: (d) {
                if (!_dragging) return;
                if (_drag.abs() > 110 || d.velocity.pixelsPerSecond.dy.abs() > 900) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _dragging = false;
                    _drag = 0;
                  });
                }
              },
              child: AnimatedContainer(
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0, i == _page ? _drag : 0, 0),
                child: AspectRatio(aspectRatio: 4 / 3, child: Hero(tag: photoTag(_ids[i]), child: _Photo(_ids[i], big: true))),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: top + 10,
          child: Row(children: [
            CircleBtn(icon: Icons.close_rounded, bg: P.whiteA20, iconColor: C.white, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(context)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
              decoration: BoxDecoration(color: P.whiteA20, borderRadius: BorderRadius.circular(R.pill)),
              child: Text('${_page + 1} / ${_ids.length}', style: TextStyle(color: C.white, fontWeight: FontWeight.w700, fontSize: Fs.base)),
            ),
          ]),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 28 + MediaQuery.of(context).padding.bottom,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
              decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.pill)),
              child: Text(p[0] as String, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: Sp.sm),
            Text(p[1] as String, style: TextStyle(color: C.white, fontSize: Fs.lg, fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.xs),
            const Text('Pinch to zoom · swipe for more · swipe down to close', style: TextStyle(color: P.iconMuted, fontSize: Fs.sm)),
          ]),
        ),
      ]),
    );
  }
}

/// Tappable photo header for the hotel page: big photo, two small, "+N photos".
class GalleryStrip extends StatelessWidget {
  final double height;
  const GalleryStrip({super.key, this.height = 300});
  @override
  Widget build(BuildContext context) {
    void open(int i) => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewer(start: i)));
    return SizedBox(
      height: height,
      child: Row(children: [
        Expanded(
          flex: 2,
          child: GestureDetector(onTap: () => open(0), child: Hero(tag: photoTag(0), child: const _Photo(0))),
        ),
        const SizedBox(width: Sp.xs),
        Expanded(
          child: Column(children: [
            Expanded(child: GestureDetector(onTap: () => open(4), child: Hero(tag: photoTag(4), child: const _Photo(4)))),
            const SizedBox(height: Sp.xs),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/gallery'),
                child: Stack(fit: StackFit.expand, children: [
                  const _Photo(6),
                  Container(
                    color: P.inkA60,
                    alignment: Alignment.center,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.photo_library_rounded, color: C.white, size: Ic.md),
                      const SizedBox(height: Sp.xs),
                      Text('+${galleryPhotos.length - 2} photos', style: TextStyle(color: C.white, fontWeight: FontWeight.w700, fontSize: Fs.base)),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
