import 'package:flutter/material.dart';

import '../state.dart';
import '../coupons.dart';
import '../shake.dart';
import '../theme.dart';
import '../api/api.dart';
import '../optimistic.dart';
import 'coupon_sheet.dart';
import 'hotel_detail.dart' show billRow, totalBox;

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});
  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  late final _name = TextEditingController(text: app.name);
  late final _phone = TextEditingController(text: app.phone.isEmpty ? '+91 98765 43210' : '+91 ${app.phone}');
  late final _email = TextEditingController(text: app.email);
  late final _gName = TextEditingController(text: app.guestName);
  late final _gPhone = TextEditingController(text: app.guestPhone);
  bool _biz = false;
  bool _tried = false;
  final _kMe = GlobalKey<ShakeState>(), _kGName = GlobalKey<ShakeState>(), _kGPhone = GlobalKey<ShakeState>();

  String? get _meErr => _name.text.trim().length < 2 ? 'Enter your full name' : null;
  String? get _gNameErr {
    final n = _gName.text.trim();
    if (n.length < 2) return 'Enter the guest\'s full name, as on their ID';
    if (!RegExp(r"^[A-Za-z .']+$").hasMatch(n)) return 'Use letters only, as on their ID';
    return null;
  }

  String? get _gPhoneErr {
    final p = _gPhone.text.replaceAll(RegExp(r'\D'), '');
    if (p.length != 10) return 'Enter the guest\'s 10-digit mobile number';
    if (!RegExp(r'^[6-9]').hasMatch(p)) return 'Indian mobile numbers start with 6, 7, 8 or 9';
    return null;
  }

  void _proceed() {
    final other = app.forSomeoneElse;
    final bad = [
      if (_meErr != null) _kMe,
      if (other && _gNameErr != null) _kGName,
      if (other && _gPhoneErr != null) _kGPhone,
    ];
    if (bad.isNotEmpty) {
      setState(() => _tried = true);
      shakeAll(bad);
      return;
    }
    app.set(() {
      app.name = _name.text.trim();
      app.email = _email.text.trim();
      app.guestName = other ? _gName.text.trim() : '';
      app.guestPhone = other ? _gPhone.text.replaceAll(RegExp(r'\D'), '') : '';
    });
    Navigator.pushNamed(context, '/payment');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _gName.dispose();
    _gPhone.dispose();
    super.dispose();
  }

  Widget _counter(String label, String hint, int v, int min, int max, ValueChanged<int> set, {bool last = false}) {
    Widget btn(String t, bool enabled, VoidCallback onTap, bool plus) => GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: plus ? (enabled ? C.lime : C.line) : C.card,
              shape: BoxShape.circle,
              border: plus ? null : Border.all(color: enabled ? const Color(0xFFDADAD2) : C.line, width: 1.5),
            ),
            child: Text(t, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: enabled || plus ? C.ink : const Color(0xFFC9C9C1))),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(hint, style: TextStyle(fontSize: 12, color: C.muted2)),
          ]),
        ),
        btn('−', v > min, () => set(v - 1), false),
        SizedBox(width: 30, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        btn('+', v < max, () => set(v + 1), true),
      ]),
    );
  }

  Widget _switchRow(IconData icon, String title, String sub, bool v, ValueChanged<bool> on, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(fontSize: 12, color: C.muted2)),
            ]),
          ),
          BrandSwitch(value: v, onChanged: on),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final h = app.hotel;
        return Scaffold(
          body: Column(children: [
            SheetHeader(
              child: Row(children: [
                BackBtn(bg: C.bg, shadow: false),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Review & reserve', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('One last check before you pay', style: TextStyle(fontSize: 12.5, color: C.muted)),
                ]),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
                WhiteCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const SizedBox(width: 84, child: PhotoPlaceholder(height: 84, radius: 16, label: '')),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        RatingBadge(h.rating),
                        const SizedBox(height: 6),
                        Text(h.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('Deluxe Room · ${h.area}', style: TextStyle(fontSize: 12.5, color: C.muted)),
                      ]),
                    ),
                  ]),
                ),
                const SectionLabel('Your stay'),
                WhiteCard(
                  child: Column(children: [
                    StayTimeline(
                      inTime: app.inTimeLabel,
                      outTime: app.outTimeLabel,
                      inDate: app.inDateLabel,
                      outDate: app.outDateLabel,
                      slot: app.stayLabel,
                    ),
                    const SizedBox(height: 14),
                    if (!app.fullDay)
                    Row(
                      children: [3, 6, 9, 12].map((hrs) {
                        final p = h.priceFor(hrs);
                        final on = hrs == app.slot;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: hrs == 12 ? 0 : 6),
                            child: GestureDetector(
                              onTap: p == null ? null : () => app.set(() => app.slot = hrs),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: on ? C.limeBg : (p == null ? C.bg : C.white),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: on ? C.lime : C.border, width: 1.5),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('$hrs hrs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? C.limeInk : C.muted2)),
                                  Text(p == null ? 'Full' : inr(p), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                ]),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    PillBtn('Change date or time',
                        kind: BtnKind.soft,
                        height: 40,
                        fontSize: 13,
                        expand: true,
                        icon: Icons.edit_outlined,
                        trailingIcon: false,
                        onTap: () => popTo(context, app.fullDay ? '/fullday' : '/date')),
                  ]),
                ),
                const SectionLabel('Rooms & guests'),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(children: [
                    _counter('Rooms', 'Up to 3 guests per room', app.rooms, 1, 4,
                        (v) => app.set(() {
                              app.rooms = v;
                              if (app.adults > v * 3) app.adults = v * 3;
                            })),
                    _counter('Guests', '18 years and above', app.adults, 1, app.rooms * 3, (v) => app.set(() => app.adults = v)),
                    _counter('Children', 'Below 5 years, stay free', app.kids, 0, 2, (v) => app.set(() => app.kids = v), last: true),
                  ]),
                ),
                const SectionLabel('I\'m booking for'),
                SegmentPill(
                  options: const ['Myself', 'Someone else'],
                  selected: app.forSomeoneElse ? 1 : 0,
                  onChanged: (i) => app.set(() => app.forSomeoneElse = i == 1),
                ),
                const SizedBox(height: 12),
                if (app.forSomeoneElse) ...[
                  WhiteCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Guest who will check in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Shake(
                        key: _kGName,
                        child: BrandField(
                          label: 'Guest\'s full name (as on ID)',
                          hint: 'e.g. Priya Raman',
                          controller: _gName,
                          errorText: _tried ? _gNameErr : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Shake(
                        key: _kGPhone,
                        child: BrandField(
                          label: 'Guest\'s mobile number',
                          hint: '10-digit number',
                          controller: _gPhone,
                          keyboard: TextInputType.phone,
                          errorText: _tried ? _gPhoneErr : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _switchRow(Icons.chat_bubble_outline_rounded, 'Send details to the guest', 'Booking, directions and check-in OTP on WhatsApp',
                          app.notifyGuest, (v) => app.set(() => app.notifyGuest = v),
                          last: true),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: C.tint(const Color(0xFFFFF6DA)), borderRadius: BorderRadius.circular(12)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.badge_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('The guest must show their own original photo ID, and the name must match it. You can\'t check in for them.',
                                style: TextStyle(fontSize: 12.5, height: 1.4, color: C.tx(const Color(0xFF4A4030)))),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                WhiteCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (app.forSomeoneElse) ...[
                      const Text('Your details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('For payment, receipt and updates', style: TextStyle(fontSize: 12.5, color: C.muted)),
                      const SizedBox(height: 12),
                    ],
                    Shake(
                      key: _kMe,
                      child: BrandField(label: 'Full name', controller: _name, errorText: _tried ? _meErr : null, onChanged: (_) => setState(() {})),
                    ),
                    const SizedBox(height: 12),
                    BrandField(label: 'Mobile number', controller: _phone, keyboard: TextInputType.phone),
                    const SizedBox(height: 12),
                    BrandField(label: 'Email (for your receipt)', hint: 'you@email.com', controller: _email, keyboard: TextInputType.emailAddress),
                    if (!app.forSomeoneElse) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.badge_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Every guest needs an original photo ID at check-in.', style: TextStyle(fontSize: 12.5, color: C.tx(const Color(0xFF3F3F38))))),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
                WhiteCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Column(children: [
                    _switchRow(Icons.work_outline_rounded, 'Business booking', 'Add GST details to your invoice', _biz, (v) => setState(() => _biz = v)),
                    if (_biz)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(children: [
                          BrandField(label: 'Company name'),
                          SizedBox(height: 10),
                          BrandField(label: 'GSTIN'),
                        ]),
                      ),
                    _switchRow(Icons.chat_bubble_outline_rounded, 'Booking details on WhatsApp', 'Confirmation, directions & reminders', app.whatsappUpdates,
                        (v) => optimistic(context,
                            apply: () => app.set(() => app.whatsappUpdates = v),
                            revert: () => app.set(() => app.whatsappUpdates = !v),
                            call: () => api.setPreference('whatsapp', v)),
                        last: true),
                  ]),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    if (!app.coupon) {
                      showCouponSheet(context);
                      return;
                    }
                    final code = app.couponCode;
                    app.set(() => app.couponCode = null);
                    undoToast(context, '$code removed', () => app.set(() => app.couponCode = code));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: app.coupon ? C.tint(Color(0xFFF6FBE6)) : C.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: app.coupon ? C.green : C.ink, width: 1.5),
                    ),
                    child: Row(children: [
                      IconTile(Icons.percent_rounded, bg: C.limeBg, size: 36, radius: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.coupon ? '${app.couponCode} applied' : 'Apply coupon', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                          Text(app.coupon ? (couponProblem(app.couponCode!) ?? couponSaving(app.couponCode!)) : 'See offers for this stay', style: TextStyle(fontSize: 12, color: C.muted)),
                        ]),
                      ),
                      Text(app.coupon ? 'Remove' : 'View', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
                const SectionLabel('Bill summary'),
                WhiteCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Column(children: [
                    billRow('Room price · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} × ${app.stayLabel}', inr(app.gross - app.fees)),
                    const SizedBox(height: 12),
                    billRow('Taxes & fees', inr(app.fees)),
                    if (app.discount > 0) ...[const SizedBox(height: 12), billRow('Coupon ${app.couponCode}', '−${inr(app.discount)}', vColor: C.green)],
                    const SizedBox(height: 14),
                    totalBox(inr(app.total)),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final l in ['Privacy', 'T&Cs', 'Help'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: GestureDetector(
                        onTap: () => l == 'Help'
                            ? Navigator.pushNamed(context, '/help')
                            : Navigator.pushNamed(context, '/legal', arguments: l == 'Privacy' ? 'privacy' : 'terms'),
                        child: Text(l, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.muted, decoration: TextDecoration.underline)),
                      ),
                    ),
                ]),
              ]),
            ),
            BottomBar(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(inr(app.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('${app.stayLabel} · ${app.guestsLabel}${app.forSomeoneElse && _gName.text.trim().isNotEmpty ? ' · for ${_gName.text.trim().split(' ').first}' : ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: C.muted)),
                  ]),
                ),
                PillBtn('Proceed to pay',
                    height: 54,
                    icon: Icons.arrow_forward_rounded,
                    onTap: _proceed),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
