import 'dart:async';

import 'package:flutter/material.dart';

import '../state.dart';
import '../shake.dart';
import '../theme.dart';
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

  void _verifyVpa() {
    final v = _vpa.text.trim();
    final ok = RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$').hasMatch(v);
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

  void _tryPay() {
    if (_sel == 'upiid' && !_vpaOk) {
      _verifyVpa();
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
      barrierColor: const Color(0x99111111),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3.5, color: C.ink, backgroundColor: C.limeSoft)),
              const SizedBox(height: 16),
              const Text('Confirming payment…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Don\'t press back or close the app', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w500)),
            ]),
          ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!_willFail) {
      app.set(() {
        app.bookingCancelled = false;
        app.checkedIn = false;
        app.bookingId = newBookingId(DateTime.now());
      app.bookingId = newBookingId(DateTime.now());
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
        hintStyle: const TextStyle(color: Color(0xFF8A8A82), fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: C.ink, width: 1.5)),
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
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        decoration: _dec('Card number',
            suffix: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: luhnOk(_cDigits)
                  ? Icon(Icons.check_circle_rounded, color: C.green, size: 20)
                  : Text(brand, style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontSize: 12)),
            )),
      ),
      if (_cDigits.length == 16 && !luhnOk(_cDigits))
        Padding(
            padding: EdgeInsets.only(top: 4, left: 4), child: Text('Check the card number', style: TextStyle(fontSize: 12, color: C.red))),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextField(
            controller: _cExp,
            keyboardType: TextInputType.number,
            inputFormatters: [ExpiryFormatter()],
            autofillHints: const [AutofillHints.creditCardExpirationDate],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: _dec('Expiry MM/YY'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _cCvv,
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            autofillHints: const [AutofillHints.creditCardSecurityCode],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 3),
            decoration: _dec('CVV'),
          ),
        ),
      ]),
      if (_cExp.text.length == 5 && expiryError(_cExp.text) != null)
        Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(expiryError(_cExp.text)!, style: TextStyle(fontSize: 12, color: C.red))),
      const SizedBox(height: 8),
      TextField(
        controller: _cName,
        textCapitalization: TextCapitalization.characters,
        autofillHints: const [AutofillHints.creditCardName],
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .']"))],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        decoration: _dec('Name on card'),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Checkbox(
          value: _cSave,
          activeColor: C.ink,
          checkColor: C.lime,
          visualDensity: VisualDensity.compact,
          onChanged: (v) => setState(() => _cSave = v ?? false),
        ),
        Expanded(child: Text('Save this card for faster checkout. CVV is never saved.', style: TextStyle(fontSize: 12.5, color: C.muted))),
      ]),
    ]);
  }

  Widget _cardPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (app.cards.isNotEmpty) ...[
            for (var i = 0; i < app.cards.length; i++)
              GestureDetector(
                onTap: () => setState(() => _cardSel = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardSel == i ? C.limeSoft : C.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cardSel == i ? C.ink : C.border, width: 1.5),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 44,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(app.cards[i].brand == 'Mastercard' ? 'MC' : app.cards[i].brand.toUpperCase(),
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: C.lime, fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.cards[i].label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                          Text('Expires ${app.cards[i].expiry}', style: TextStyle(fontSize: 12, color: C.muted)),
                        ]),
                      ),
                      _radio(_cardSel == i),
                    ]),
                    if (_cardSel == i) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: Text('Enter CVV to confirm', style: TextStyle(fontSize: 12.5, color: C.muted))),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: _cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 3),
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
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardSel < 0 ? C.limeSoft : C.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardSel < 0 ? C.ink : C.border, width: 1.5),
                ),
                child: Row(children: [
                  const Icon(Icons.add_card_rounded, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Use a new card', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
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
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Popular banks', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.muted)),
          const SizedBox(height: 8),
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
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _bank == b[0] ? C.lime : C.border, width: 1.5),
                    ),
                    child: Text(b[1], style: TextStyle(fontSize: 13.5, fontWeight: _bank == b[0] ? FontWeight.w800 : FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickBank,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border, width: 1.5)),
              child: Row(children: [
                const Icon(Icons.search_rounded, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      _bank != null && !popularBanks.any((b) => b[0] == _bank) ? bankName(_bank!) : 'All ${allBanks.length} banks',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text('You\'ll log in on your bank\'s secure page to approve the payment.', style: TextStyle(fontSize: 12, color: C.muted2)),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _sel = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            IconTile(icon, bg: on ? C.limeBg : C.bg, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.lime, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12.5, color: C.muted)),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: C.card,
                shape: BoxShape.circle,
                border: Border.all(color: on ? C.ink : const Color(0xFF9A9A92), width: on ? 7 : 2),
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
              const SizedBox(width: 12),
              const Expanded(child: Text('Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text('Room held · $mm:$ss', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(22)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('YOU PAY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: C.faint)),
                        const SizedBox(height: 6),
                        Text(inr(app.total), style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: C.lime, letterSpacing: -1.5, height: 1)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.stayLabel}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.white)),
                      const SizedBox(height: 3),
                      Text(app.whenShort,
                          style: TextStyle(fontSize: 13, color: C.faint)),
                    ]),
                  ]),
                ),
                Row(children: [
                  Container(width: 10, height: 20, decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.horizontal(right: Radius.circular(10)))),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate((c.maxWidth / 10).floor(), (_) => Container(width: 5, height: 2, color: const Color(0xFF3A3A3A))),
                      ),
                    ),
                  ),
                  Container(width: 10, height: 20, decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.horizontal(left: Radius.circular(10)))),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(children: [
                    Expanded(child: Text('Inclusive of all taxes', style: TextStyle(fontSize: 13, color: C.faint))),
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: C.card,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Align(alignment: Alignment.centerLeft, child: Text('Price details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            const SizedBox(height: 16),
                            billRow('Room price', inr(app.gross - app.fees)),
                            const SizedBox(height: 12),
                            billRow('Taxes & fees', inr(app.fees)),
                            if (app.discount > 0) ...[const SizedBox(height: 12), billRow('Coupon ${app.couponCode}', '−${inr(app.discount)}', vColor: C.green)],
                            const SizedBox(height: 14),
                            totalBox(inr(app.total)),
                          ]),
                        ),
                      ),
                      child: Row(children: [
                        Text('Price details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.white)),
                        Icon(Icons.chevron_right_rounded, size: 16, color: C.white),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SectionLabel('Pay with UPI'),
            WhiteCard(
              radius: 20,
              padding: const EdgeInsets.all(5),
              child: Column(children: [
                _row('anyupi', Icons.phone_android_rounded, 'Any UPI app', 'GPay, PhonePe, Paytm & more', badge: 'FASTEST'),
                _row('upiid', Icons.alternate_email_rounded, 'Enter UPI ID', 'Pay using your UPI address'),
                if (_sel == 'upiid')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 4, 12, 12),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _vpaErr != null ? C.red : C.border, width: 1.5)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _vpaErr != null ? C.red : C.ink, width: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PillBtn('Verify', kind: BtnKind.dark, height: 46, fontSize: 14, onTap: _verifyVpa),
                        ]),
                      ),
                      FieldError(_vpaErr),
                    ]),
                  ),
              ]),
            ),
            const SectionLabel('More ways to pay'),
            Shake(key: _kMore, child: WhiteCard(
              radius: 20,
              padding: const EdgeInsets.all(5),
              child: Column(children: [
                _row('card', Icons.credit_card_rounded, 'Credit / Debit card',
                    app.cards.isEmpty ? 'Visa, Mastercard, RuPay' : '${app.cards.length} saved · or add a new card'),
                if (_sel == 'card') _cardPanel(),
                _row('netbank', Icons.account_balance_outlined, 'Net banking',
                    _bank == null ? '${allBanks.length} Indian banks' : bankName(_bank!)),
                if (_sel == 'netbank') _bankPanel(),
              ]),
            )),
          ]),
        ),
        BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: C.muted),
              SizedBox(width: 6),
              Text('Secure, encrypted payments', style: TextStyle(fontSize: 12, color: C.muted)),
            ]),
            if (!_canPay) ...[
              const SizedBox(height: 6),
              Shake(key: _kNote, child: Text(_payNote, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.red))),
            ],
            const SizedBox(height: 10),
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
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.faint, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(children: [
              const Expanded(child: Text('Choose your bank', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              CircleBtn(icon: Icons.close_rounded, size: 38, bg: C.bg, shadow: false, tooltip: 'Close', onTap: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search ${allBanks.length} banks',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                filled: true,
                fillColor: C.bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('No bank matches', style: TextStyle(color: C.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(color: C.line, height: 1),
                    itemBuilder: (_, i) {
                      final on = list[i][0] == widget.selected;
                      return InkWell(
                        onTap: () => Navigator.pop(context, list[i][0]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            const IconTile(Icons.account_balance_outlined, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(list[i][1],
                                    style: TextStyle(fontSize: 14.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600))),
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
