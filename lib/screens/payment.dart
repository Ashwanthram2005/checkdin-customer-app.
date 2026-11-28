import 'dart:async';

import 'package:flutter/material.dart';

import '../state.dart';
import '../shake.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import 'package:flutter/services.dart';

import '../banks.dart';
import 'add_card.dart' show CardNumberFormatter, ExpiryFormatter, cardBrand, luhnOk, expiryError;
import 'hotel_detail.dart' show billRow, totalBox;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _sel = 'anyupi';
  int _left = 600;
  Timer? _t;
  final _vpa = TextEditingController();
  final _kMore = GlobalKey<ShakeState>(), _kVpa = GlobalKey<ShakeState>(), _kNote = GlobalKey<ShakeState>();
  String? _vpaErr;
  bool _vpaOk = false;

  bool _vpaBusy = false;

  Future<void> _verifyVpa() async {
    final v = _vpa.text.trim();
    if (_vpaBusy) return;
    var ok = RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$').hasMatch(v);
    if (ok) {
      setState(() => _vpaBusy = true);
      try {
        ok = await api.verifyUpiId(v);
      } on ApiError catch (e) {
        if (mounted) {
          setState(() => _vpaBusy = false);
          toast(context, e.message);
        }
        return;
      }
      if (!mounted) return;
      _vpaBusy = false;
    }
    setState(() {
      _vpaOk = ok;
      _vpaErr = v.isEmpty ? 'Enter your UPI ID' : (ok ? null : 'That doesn\'t look like a UPI ID. It should be like name@okhdfc');
    });
    if (ok) {
      toast(context, 'UPI ID verified');
    } else {
      _kVpa.currentState?.shake();
    }
  }

  Future<void> _tryPay() async {
    if (_sel == 'upiid' && !_vpaOk) {
      await _verifyVpa();
      if (!_vpaOk) return;
    }
    if (!_canPay) {
      setState(() {});
      shakeAll([_kMore, _kNote]);
      return;
    }
    _pay();
  }

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _left > 0) setState(() => _left--);
    });
  }

  static const _labels = {
    'anyupi': 'Any UPI app',
    'upiid': 'UPI ID',
    'card': 'Credit / Debit card',
    'netbank': 'Net banking',
  };

  /// Demo rule: a UPI ID containing "fail" (e.g. test.fail@upi) simulates a failed payment.
  bool get _willFail => _sel == 'upiid' && _vpa.text.toLowerCase().contains('fail');

  Future<void> _pay() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: P.inkA60,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xxl, Sp.xl, Sp.xxl),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.xl)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3.5, color: C.ink, backgroundColor: C.limeSoft)),
              const SizedBox(height: Sp.lg),
              const Text('Confirming payment…', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
              const SizedBox(height: Sp.xs),
              Text('Don\'t press back or close the app', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: Fs.sm, color: C.muted, fontWeight: FontWeight.w500)),
            ]),
          ),
          ),
        ),
      ),
    );
    var ok = true;
    var soldOut = false;
    String? id;
    try {
      id = await api.pay(method: _sel, amount: app.total, idempotencyKey: newIdempotencyKey(), simulateFailure: _willFail);
    } on ApiError catch (e) {
      ok = false;
      soldOut = e.code == 'slot_taken';
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    if (soldOut) {
      Navigator.pushNamed(context, '/sold-out');
      return;
    }
    if (ok) {
      app.set(() {
        app.bookingCancelled = false;
        app.checkedIn = false;
        app.bookingId = id ?? newBookingId(DateTime.now());
        app.stayStart = null;
        app.extraHours = 0;
        app.extraPaid = 0;
        app.paidWith = _sel == 'card'
            ? (_useNewCard ? '${cardBrand(_cDigits).isEmpty ? 'Card' : cardBrand(_cDigits)} •••• ${_cDigits.length >= 4 ? _cDigits.substring(_cDigits.length - 4) : ''}' : app.cards[_cardSel].label)
            : _sel == 'netbank'
                ? bankName(_bank!)
                : 'UPI';
        if (_sel == 'card' && _useNewCard && _cSave) {
          final b = cardBrand(_cDigits);
          app.cards.add(SavedCard(b.isEmpty ? 'Card' : b, _cDigits.substring(_cDigits.length - 4), _cExp.text, _cName.text.trim()));
        }
      });
    Navigator.pushNamedAndRemoveUntil(context, '/success', ModalRoute.withName('/home'));
      return;
    }
    final r = await Navigator.pushNamed(context, '/payment-failed', arguments: {'method': _labels[_sel] ?? 'UPI', 'left': _left});
    if (r == 'retry' && mounted) {
      if (_sel == 'netbank') setState(() => _sel = 'anyupi');
      toast(context, _sel == 'anyupi' ? 'Try again with UPI, it\'s usually fastest' : 'Try again');
    }
  }

  // card
  int _cardSel = 0; // index in app.cards, or -1 = new card
  final _cvv = TextEditingController();
  final _cNum = TextEditingController();
  final _cExp = TextEditingController();
  final _cCvv = TextEditingController();
  final _cName = TextEditingController();
  bool _cSave = true;
  // net banking
  String? _bank;

  String get _cDigits => _cNum.text.replaceAll(' ', '');
  bool get _newCardOk =>
      luhnOk(_cDigits) && expiryError(_cExp.text) == null && RegExp(r'^\d{3}$').hasMatch(_cCvv.text) && _cName.text.trim().length >= 3;
  bool get _useNewCard => app.cards.isEmpty || _cardSel < 0;
  bool get _canPay {
    if (_sel == 'card') return _useNewCard ? _newCardOk : RegExp(r'^\d{3}$').hasMatch(_cvv.text);
    if (_sel == 'netbank') return _bank != null;
    return true;
  }

  String get _payNote {
    if (_sel == 'card') return _useNewCard ? 'Enter your card details to pay' : 'Enter the CVV to pay';
    if (_sel == 'netbank') return 'Choose your bank to pay';
    return '';
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: C.card,
        suffixIcon: suffix,
        hintStyle: const TextStyle(color: P.hint, fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.lg),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide(color: C.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide(color: C.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide(color: C.ink, width: 1.5)),
      );

  Widget _radio(bool on) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(shape: BoxShape.circle, color: on ? C.inkBg : C.card, border: Border.all(color: on ? C.ink : C.border, width: 2)),
        child: on ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: C.limeBg, shape: BoxShape.circle))) : null,
      );

  Widget _newCardForm() {
    final brand = cardBrand(_cDigits);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _cNum,
        keyboardType: TextInputType.number,
        inputFormatters: [CardNumberFormatter()],
        autofillHints: const [AutofillHints.creditCardNumber],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        decoration: _dec('Card number',
            suffix: Padding(
              padding: const EdgeInsets.only(right: Sp.md),
              child: luhnOk(_cDigits)
                  ? Icon(Icons.check_circle_rounded, color: C.green, size: Ic.md)
                  : Text(brand, style: const TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: Fs.sm)),
            )),
      ),
      if (_cDigits.length == 16 && !luhnOk(_cDigits))
        Padding(
            padding: EdgeInsets.only(top: Sp.xs, left: Sp.xs), child: Text('Check the card number', style: TextStyle(fontSize: Fs.sm, color: C.red))),
      const SizedBox(height: Sp.sm),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextField(
            controller: _cExp,
            keyboardType: TextInputType.number,
            inputFormatters: [ExpiryFormatter()],
            autofillHints: const [AutofillHints.creditCardExpirationDate],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700),
            decoration: _dec('Expiry MM/YY'),
          ),
        ),
        const SizedBox(width: Sp.sm),
        Expanded(
          child: TextField(
            controller: _cCvv,
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            autofillHints: const [AutofillHints.creditCardSecurityCode],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, letterSpacing: 3),
            decoration: _dec('CVV'),
          ),
        ),
      ]),
      if (_cExp.text.length == 5 && expiryError(_cExp.text) != null)
        Padding(
            padding: const EdgeInsets.only(top: Sp.xs, left: Sp.xs),
            child: Text(expiryError(_cExp.text)!, style: TextStyle(fontSize: Fs.sm, color: C.red))),
      const SizedBox(height: Sp.sm),
      TextField(
        controller: _cName,
        textCapitalization: TextCapitalization.characters,
        autofillHints: const [AutofillHints.creditCardName],
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .']"))],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700),
        decoration: _dec('Name on card'),
      ),
      const SizedBox(height: Sp.xs),
      Row(children: [
        Checkbox(
          value: _cSave,
          activeColor: C.ink,
          checkColor: C.lime,
          visualDensity: VisualDensity.compact,
          onChanged: (v) => setState(() => _cSave = v ?? false),
        ),
        Expanded(child: Text('Save this card for faster checkout. CVV is never saved.', style: TextStyle(fontSize: Fs.sm, color: C.muted))),
      ]),
    ]);
  }

  Widget _cardPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (app.cards.isNotEmpty) ...[
            for (var i = 0; i < app.cards.length; i++)
              GestureDetector(
                onTap: () => setState(() => _cardSel = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: Sp.sm),
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(
                    color: _cardSel == i ? C.limeSoft : C.card,
                    borderRadius: BorderRadius.circular(R.lg),
                    border: Border.all(color: _cardSel == i ? C.ink : C.border, width: 1.5),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 44,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.sm)),
                        child: Text(app.cards[i].brand == 'Mastercard' ? 'MC' : app.cards[i].brand.toUpperCase(),
                            style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: C.lime, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.cards[i].label, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                          Text('Expires ${app.cards[i].expiry}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                        ]),
                      ),
                      _radio(_cardSel == i),
                    ]),
                    if (_cardSel == i) ...[
                      const SizedBox(height: Sp.md),
                      Row(children: [
                        Expanded(child: Text('Enter CVV to confirm', style: TextStyle(fontSize: Fs.sm, color: C.muted))),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: _cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, letterSpacing: 3),
                            decoration: _dec('CVV'),
                          ),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),
            GestureDetector(
              onTap: () => setState(() => _cardSel = -1),
              child: Container(
                margin: const EdgeInsets.only(bottom: Sp.sm),
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: _cardSel < 0 ? C.limeSoft : C.card,
                  borderRadius: BorderRadius.circular(R.lg),
                  border: Border.all(color: _cardSel < 0 ? C.ink : C.border, width: 1.5),
                ),
                child: Row(children: [
                  const Icon(Icons.add_card_rounded, size: Ic.md),
                  const SizedBox(width: Sp.md),
                  const Expanded(child: Text('Use a new card', style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                  _radio(_cardSel < 0),
                ]),
              ),
            ),
          ],
          if (_useNewCard) _newCardForm(),
        ]),
      );

  Future<void> _pickBank() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankSheet(selected: _bank),
    );
    if (r != null) setState(() => _bank = r);
  }

  Widget _bankPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Popular banks', style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.muted)),
          const SizedBox(height: Sp.sm),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              for (final b in popularBanks)
                GestureDetector(
                  onTap: () => setState(() => _bank = b[0]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _bank == b[0] ? C.limeBg : C.card,
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(color: _bank == b[0] ? C.lime : C.border, width: 1.5),
                    ),
                    child: Text(b[1], style: TextStyle(fontSize: Fs.base, fontWeight: _bank == b[0] ? FontWeight.w700 : FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          InkWell(
            borderRadius: BorderRadius.circular(R.md),
            onTap: _pickBank,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 13),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.border, width: 1.5)),
              child: Row(children: [
                const Icon(Icons.search_rounded, size: Ic.md),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Text(
                      _bank != null && !popularBanks.any((b) => b[0] == _bank) ? bankName(_bank!) : 'All ${allBanks.length} banks',
                      style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
          const SizedBox(height: Sp.sm),
          Text('You\'ll log in on your bank\'s secure page to approve the payment.', style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
        ]),
      );

  @override
  void dispose() {
    _t?.cancel();
    for (final c in [_cvv, _cNum, _cExp, _cCvv, _cName]) {
      c.dispose();
    }
    _vpa.dispose();
    super.dispose();
  }

  Widget _row(String id, IconData icon, String title, String sub, {String? badge, bool last = false}) {
    final on = _sel == id;
    return Material(
      color: on ? C.bg : Colors.transparent,
      borderRadius: BorderRadius.circular(R.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.lg),
        onTap: () => setState(() => _sel = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.md),
          child: Row(children: [
            IconTile(icon, bg: on ? C.limeBg : C.bg, size: 40),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  if (badge != null) ...[
                    const SizedBox(width: Sp.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xxs),
                      decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.sm)),
                      child: Text(badge, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: C.lime, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: Sp.xxs),
                Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: C.card,
                shape: BoxShape.circle,
                border: Border.all(color: on ? C.ink : P.iconMuted, width: on ? 7 : 2),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 20), children: [
            Row(children: [
              const BackBtn(),
              const SizedBox(width: Sp.md),
              const Expanded(child: Text('Payment', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.pill)),
                child: Row(children: [
                  const Icon(Icons.timer_rounded, size: Ic.sm),
                  const SizedBox(width: Sp.sm),
                  Text('Room held · $mm:$ss', style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: Sp.lg),
            Container(
              decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.xl)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.lg),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('YOU PAY', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: C.faint)),
                        const SizedBox(height: Sp.sm),
                        Text(inr(app.total), style: TextStyle(fontSize: Fs.display, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: -1.5, height: 1)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.stayLabel}',
                          style: TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700, color: C.white)),
                      const SizedBox(height: Sp.xs),
                      Text(app.whenShort,
                          style: TextStyle(fontSize: Fs.base, color: C.faint)),
                    ]),
                  ]),
                ),
                Row(children: [
                  Container(width: 10, height: 20, decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.horizontal(right: Radius.circular(R.md)))),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate((c.maxWidth / 10).floor(), (_) => Container(width: 5, height: 2, color: P.grey23)),
                      ),
                    ),
                  ),
                  Container(width: 10, height: 20, decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.horizontal(left: Radius.circular(R.md)))),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.lg),
                  child: Row(children: [
                    Expanded(child: Text('Inclusive of all taxes', style: TextStyle(fontSize: Fs.base, color: C.faint))),
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: C.card,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xl, Sp.xl, Sp.x3),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Align(alignment: Alignment.centerLeft, child: Text('Price details', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800))),
                            const SizedBox(height: Sp.lg),
                            billRow('Room price', inr(app.gross - app.fees)),
                            const SizedBox(height: Sp.md),
                            billRow('Taxes & fees', inr(app.fees)),
                            if (app.discount > 0) ...[const SizedBox(height: Sp.md), billRow('Coupon ${app.couponCode}', '−${inr(app.discount)}', vColor: C.green)],
                            const SizedBox(height: Sp.lg),
                            totalBox(inr(app.total)),
                          ]),
                        ),
                      ),
                      child: Row(children: [
                        Text('Price details', style: TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600, color: C.white)),
                        Icon(Icons.chevron_right_rounded, size: Ic.sm, color: C.white),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SectionLabel('Pay with UPI'),
            WhiteCard(
              radius: R.xl,
              padding: const EdgeInsets.all(Sp.xs),
              child: Column(children: [
                _row('anyupi', Icons.phone_android_rounded, 'Any UPI app', 'GPay, PhonePe, Paytm & more', badge: 'FASTEST'),
                _row('upiid', Icons.alternate_email_rounded, 'Enter UPI ID', 'Pay using your UPI address'),
                if (_sel == 'upiid')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, Sp.xs, Sp.md, Sp.md),
                    child: Column(children: [
                      Shake(
                        key: _kVpa,
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _vpa,
                              onChanged: (_) => setState(() {
                                _vpaErr = null;
                                _vpaOk = false;
                              }),
                              onSubmitted: (_) => _verifyVpa(),
                              decoration: InputDecoration(
                                hintText: 'yourname@okbank',
                                isDense: true,
                                suffixIcon: _vpaOk ? Icon(Icons.check_circle_rounded, color: C.green) : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide(color: _vpaErr != null ? C.red : C.border, width: 1.5)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide(color: _vpaErr != null ? C.red : C.ink, width: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: Sp.sm),
                          PillBtn('Verify', kind: BtnKind.dark, height: 46, fontSize: Fs.md, loading: _vpaBusy, onTap: _verifyVpa),
                        ]),
                      ),
                      FieldError(_vpaErr),
                    ]),
                  ),
              ]),
            ),
            const SectionLabel('More ways to pay'),
            Shake(key: _kMore, child: WhiteCard(
              radius: R.xl,
              padding: const EdgeInsets.all(Sp.xs),
              child: Column(children: [
                _row('card', Icons.credit_card_rounded, 'Credit / Debit card',
                    app.cards.isEmpty ? 'Visa, Mastercard, RuPay' : '${app.cards.length} saved · or add a new card'),
                if (_sel == 'card') _cardPanel(),
                _row('netbank', Icons.account_balance_rounded, 'Net banking',
                    _bank == null ? '${allBanks.length} Indian banks' : bankName(_bank!)),
                if (_sel == 'netbank') _bankPanel(),
              ]),
            )),
          ]),
        ),
        BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded, size: Ic.sm, color: C.muted),
              SizedBox(width: Sp.sm),
              Text('Secure, encrypted payments', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
            ]),
            if (!_canPay) ...[
              const SizedBox(height: Sp.sm),
              Shake(key: _kNote, child: Text(_payNote, style: TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, color: C.red))),
            ],
            const SizedBox(height: Sp.md),
            PillBtn('Pay ${inr(app.total)}',
                kind: BtnKind.dark,
                height: 56,
                expand: true,
                icon: Icons.arrow_forward_rounded,
                onTap: _left == 0 ? null : _tryPay),
          ]),
        ),
      ]),
    );
  }
}

class _BankSheet extends StatefulWidget {
  final String? selected;
  const _BankSheet({this.selected});
  @override
  State<_BankSheet> createState() => _BankSheetState();
}

class _BankSheetState extends State<_BankSheet> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = allBanks.where((b) => b[1].toLowerCase().contains(_q.toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
        child: Column(children: [
          const SizedBox(height: Sp.md),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(R.xs))),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.md, Sp.sm),
            child: Row(children: [
              const Expanded(child: Text('Choose your bank', style: TextStyle(fontSize: Fs.xl, fontWeight: FontWeight.w800))),
              CircleBtn(icon: Icons.close_rounded, size: 38, bg: C.bg, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.sm),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search ${allBanks.length} banks',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                filled: true,
                fillColor: C.bg,
                contentPadding: const EdgeInsets.symmetric(vertical: Sp.lg),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.lg), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('No bank matches', style: TextStyle(color: C.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xs, Sp.xl, Sp.xxl),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(color: C.line, height: 1),
                    itemBuilder: (_, i) {
                      final on = list[i][0] == widget.selected;
                      return InkWell(
                        onTap: () => Navigator.pop(context, list[i][0]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: Sp.lg),
                          child: Row(children: [
                            const IconTile(Icons.account_balance_rounded, size: 36),
                            const SizedBox(width: Sp.md),
                            Expanded(
                                child: Text(list[i][1],
                                    style: TextStyle(fontSize: Fs.md, fontWeight: on ? FontWeight.w700 : FontWeight.w600))),
                            if (on) Icon(Icons.check_circle_rounded, color: C.ink),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
