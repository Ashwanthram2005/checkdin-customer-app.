import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state.dart';
import '../photos.dart';
import '../theme.dart';

Widget _tiles() => kQaMode
    ? Container(color: P.grey90)
    : TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.checkdin.checkdin',
      );

/// Opens Google Maps (app or web) with directions to the hotel.
Future<void> openDirections(BuildContext context, Hotel h) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${h.lat},${h.lng}&travelmode=driving');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'Couldn\'t open Maps');
}

/// Calls the hotel's front desk.
Future<void> callHotel(BuildContext context, [String phone = '+914400000000']) async {
  final ok = await launchUrl(Uri.parse('tel:$phone'));
  if (!ok && context.mounted) toast(context, 'Couldn\'t start the call');
}

class _Pin extends StatelessWidget {
  final String? price;
  final bool on;
  const _Pin({this.price, this.on = false});
  @override
  Widget build(BuildContext context) {
    if (price == null) {
      return Container(
        decoration: BoxDecoration(color: C.inkBg, shape: BoxShape.circle, border: Border.all(color: C.white, width: 3)),
        child: Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle))),
      );
    }
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
        decoration: BoxDecoration(
          color: on ? C.inkBg : C.card,
          borderRadius: BorderRadius.circular(R.pill),
          border: Border.all(color: C.ink, width: 1.5),
          boxShadow: const [BoxShadow(color: P.inkA20, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Text(price!, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: on ? C.lime : C.ink)),
      ),
    );
  }
}

/// Small, non-interactive map for the hotel page.
class HotelMiniMap extends StatelessWidget {
  final Hotel h;
  final double height;
  const HotelMiniMap(this.h, {super.key, this.height = 160});
  @override
  Widget build(BuildContext context) {
    final p = LatLng(h.lat, h.lng);
    return SizedBox(
      height: height,
      child: Stack(children: [
        FlutterMap(
          options: MapOptions(initialCenter: p, initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
          children: [
            _tiles(),
            MarkerLayer(markers: [Marker(point: p, width: 34, height: 34, child: const _Pin())]),
          ],
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaysMapScreen(focus: h)))),
          ),
        ),
        const Positioned(
          right: 6,
          bottom: 4,
          child: Text('© OpenStreetMap', style: TextStyle(fontSize: Fs.xs, color: P.muted)),
        ),
      ]),
    );
  }
}

/// Full-screen map of stays with price pins.
class StaysMapScreen extends StatefulWidget {
  final Hotel? focus;
  final List<Hotel>? list;
  final bool nightly;
  const StaysMapScreen({super.key, this.focus, this.list, this.nightly = false});
  @override
  State<StaysMapScreen> createState() => _StaysMapScreenState();
}

class _StaysMapScreenState extends State<StaysMapScreen> {
  late Hotel _sel = widget.focus ?? (widget.list ?? hotels).first;
  final _map = MapController();

  String _price(Hotel h) {
    if (widget.nightly || app.fullDay) return inr(h.night);
    final p = h.priceFor(app.slot) ?? h.prices.whereType<int>().first;
    return inr(p);
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list ?? (app.fullDay ? [...hotels, ...fullDayOnly] : hotels);
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: LatLng(_sel.lat, _sel.lng),
            initialZoom: widget.focus != null ? 15 : 12.5,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            _tiles(),
            MarkerLayer(markers: [
              for (final h in list)
                Marker(
                  point: LatLng(h.lat, h.lng),
                  width: 96,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _sel = h);
                      _map.move(LatLng(h.lat, h.lng), _map.camera.zoom);
                    },
                    child: _Pin(price: _price(h), on: h.id == _sel.id),
                  ),
                ),
            ]),
            const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          top: top + 10,
          child: Row(children: [
            const BackBtn(),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.pill), boxShadow: kShadow),
                child: Text('${list.length} stays in ${app.place ?? 'Chennai'}',
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
          child: Material(
            color: C.card,
            borderRadius: BorderRadius.circular(R.xl),
            elevation: 6,
            shadowColor: P.inkA20,
            child: InkWell(
              borderRadius: BorderRadius.circular(R.xl),
              onTap: () {
                app.set(() => app.hotel = _sel);
                Navigator.pushNamed(context, '/hotel');
              },
              child: Padding(
                padding: const EdgeInsets.all(Sp.md),
                child: Row(children: [
                  SizedBox(width: 78, height: 78, child: NetPhoto(coverOf(_sel), height: 78, radius: R.lg, w: 300)),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      RatingBadge(_sel.rating, reviews: _sel.reviews),
                      const SizedBox(height: Sp.xs),
                      Text(_sel.name, style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                      Text('${_sel.area} · ${kmLabel(_sel)}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                      const SizedBox(height: Sp.xs),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: _price(_sel), style: const TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                        TextSpan(text: widget.nightly || app.fullDay ? ' / night' : ' / ${app.slot} hrs', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                      ])),
                    ]),
                  ),
                  Column(children: [
                    CircleBtn(icon: Icons.directions_rounded, size: 40, bg: C.limeBg, shadow: false, tooltip: 'Directions', onTap: () => openDirections(context, _sel)),
                    const SizedBox(height: Sp.sm),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
