import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Result returned to Payment methods when a card is saved.
class NewCard {
  final String brand, last4, expiry, name;
  const NewCard(this.brand, this.last4, this.expiry, this.name);
}

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

/// Groups digits as 4-4-4-4.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cut = d.length > 16 ? d.substring(0, 16) : d;
    final b = StringBuffer();
    for (var i = 0; i < cut.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(cut[i]);
    }
    final s = b.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

/// Writes MM/YY.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    if (d.length == 1 && int.parse(d) > 1) d = '0$d';
    final deleting = newValue.text.length < oldValue.text.length;
    String s;
    if (d.length > 2) {
      s = '${d.substring(0, 2)}/${d.substring(2)}';
    } else if (d.length == 2 && !deleting) {
      s = '$d/';
    } else {
      s = d;
    }
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _num = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  final _name = TextEditingController();
  final _cvvFocus = FocusNode();
  bool _save = true;
  bool _touchedNum = false, _touchedExp = false, _touchedCvv = false;

  @override
  void initState() {
    super.initState();
    _cvvFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_num, _exp, _cvv, _name]) {
      c.dispose();
    }
    _cvvFocus.dispose();
    super.dispose();
  }

  String get _digits => _num.text.replaceAll(' ', '');

  String get _brand {
    final d = _digits;
    if (d.isEmpty) return '';
    if (d.startsWith('4')) return 'VISA';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^(60|65|81|82|508|353|356)').hasMatch(d)) return 'RuPay';
    return '';
  }

  bool get _luhn {
    final d = _digits;
    if (d.length < 15) return false;
    var sum = 0;
    var alt = false;
    for (var i = d.length - 1; i >= 0; i--) {
      var n = int.parse(d[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  String? get _expError {
    final t = _exp.text;
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(t)) return 'Enter as MM/YY';
    final m = int.parse(t.substring(0, 2));
    final y = 2000 + int.parse(t.substring(3));
    if (m < 1 || m > 12) return 'Month should be 01–12';
    final now = DateTime.now();
    if (y < now.year || (y == now.year && m < now.month)) return 'This card has expired';
    if (y > now.year + 20) return 'Check the year';
    return null;
  }

  bool get _cvvOk => RegExp(r'^\d{3}$').hasMatch(_cvv.text);
  bool get _nameOk => _name.text.trim().length >= 3;
  bool get _valid => _luhn && _expError == null && _cvvOk && _nameOk;

  InputDecoration _dec(String hint, {String? error, Widget? suffix}) {
    final b = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border, width: 1.5));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A8A82), fontWeight: FontWeight.w400),
      errorText: error,
      isDense: true,
      filled: true,
      fillColor: C.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: b,
      enabledBorder: b,
      focusedBorder: b.copyWith(borderSide: const BorderSide(color: C.ink, width: 1.5)),
      errorBorder: b.copyWith(borderSide: const BorderSide(color: C.red, width: 1.5)),
      focusedErrorBorder: b.copyWith(borderSide: const BorderSide(color: C.red, width: 1.5)),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.muted)),
      );

  Widget _preview() {
    final flipped = _cvvFocus.hasFocus;
    final shownNum = () {
      final d = _digits.padRight(16, '•');
      return '${d.substring(0, 4)} ${d.substring(4, 8)} ${d.substring(8, 12)} ${d.substring(12, 16)}';
    }();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(flipped),
        height: 196,
        width: double.infinity,
        decoration: BoxDecoration(
          color: C.ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x33111111), blurRadius: 24, offset: Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(width: 170, height: 170, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle)),
          ),
          Positioned(
            right: 40,
            top: 40,
            child: Container(
                width: 120, height: 120, decoration: BoxDecoration(color: const Color(0x2ED1F148), shape: BoxShape.circle)),
          ),
          if (flipped)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 28),
              Container(height: 40, color: const Color(0xFF2B2B2B)),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: Container(height: 34, color: const Color(0xFFEDEDE6))),
                  Container(
                    height: 34,
                    width: 64,
                    alignment: Alignment.center,
                    color: C.white,
                    child: Text(_cvv.text.isEmpty ? '•••' : _cvv.text,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text('The 3 digits on the back of your card', style: TextStyle(color: C.faint, fontSize: 11.5)),
              ),
            ])
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 30,
                    decoration: BoxDecoration(color: const Color(0xFFD9C27A), borderRadius: BorderRadius.circular(6)),
                  ),
                  const Spacer(),
                  Text(_brand.isEmpty ? 'CARD' : _brand.toUpperCase(),
                      style: const TextStyle(color: C.ink, fontSize: 15, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
                ]),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(shownNum,
                      style: const TextStyle(color: C.white, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('CARD HOLDER', style: TextStyle(color: C.faint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 3),
                      Text(_name.text.trim().isEmpty ? 'YOUR NAME' : _name.text.trim().toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: C.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('EXPIRES', style: TextStyle(color: C.faint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Text(_exp.text.isEmpty ? 'MM/YY' : _exp.text,
                        style: const TextStyle(color: C.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numErr = _touchedNum && _digits.isNotEmpty && !_luhn ? 'Check the card number' : null;
    final expErr = _touchedExp && _exp.text.isNotEmpty ? _expError : null;
    final cvvErr = _touchedCvv && _cvv.text.isNotEmpty && !_cvvOk ? '3 digits' : null;
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 24),
            children: [
              const TitleBar(title: 'Add card'),
              const SizedBox(height: 20),
              _preview(),
              const SizedBox(height: 22),
              _label('Card number'),
              TextField(
                controller: _num,
                keyboardType: TextInputType.number,
                inputFormatters: [_CardNumberFormatter()],
                autofillHints: const [AutofillHints.creditCardNumber],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                onChanged: (_) => setState(() {
                  if (_digits.length == 16) _touchedNum = true;
                }),
                onEditingComplete: () => setState(() => _touchedNum = true),
                decoration: _dec('1234 5678 9012 3456',
                    error: numErr,
                    suffix: _luhn ? const Icon(Icons.check_circle_rounded, color: C.green) : const Icon(Icons.credit_card_rounded, color: C.faint)),
              ),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Expiry date'),
                    TextField(
                      controller: _exp,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ExpiryFormatter()],
                      autofillHints: const [AutofillHints.creditCardExpirationDate],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      onChanged: (_) => setState(() {
                        if (_exp.text.length == 5) _touchedExp = true;
                      }),
                      decoration: _dec('MM/YY', error: expErr),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('CVV'),
                    TextField(
                      controller: _cvv,
                      focusNode: _cvvFocus,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      autofillHints: const [AutofillHints.creditCardSecurityCode],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 3),
                      onChanged: (_) => setState(() {
                        if (_cvv.text.length == 3) _touchedCvv = true;
                      }),
                      decoration: _dec('•••', error: cvvErr, suffix: const Icon(Icons.help_outline_rounded, color: C.faint, size: 20)),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              _label('Name on card'),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.characters,
                autofillHints: const [AutofillHints.creditCardName],
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .']"))],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                onChanged: (_) => setState(() {}),
                decoration: _dec('As printed on the card'),
              ),
              const SizedBox(height: 16),
              WhiteCard(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Save this card', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Pay faster next time. CVV is never saved.', style: TextStyle(fontSize: 12.5, color: C.muted)),
                    ]),
                  ),
                  BrandSwitch(value: _save, onChanged: (v) => setState(() => _save = v)),
                ]),
              ),
              const SizedBox(height: 16),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: C.muted2),
                SizedBox(width: 6),
                Flexible(
                  child: Text('Secured by our payment partner · PCI-DSS compliant',
                      style: TextStyle(fontSize: 12, color: C.muted2)),
                ),
              ]),
            ],
          ),
        ),
        BottomBar(
          child: PillBtn(
            _valid ? 'Save card' : 'Enter card details',
            kind: BtnKind.dark,
            expand: true,
            onTap: _valid
                ? () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(
                        context, NewCard(_brand.isEmpty ? 'Card' : _brand, _digits.substring(_digits.length - 4), _exp.text, _name.text.trim()));
                  }
                : null,
          ),
        ),
      ]),
    );
  }
}
