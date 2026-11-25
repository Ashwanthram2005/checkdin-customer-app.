import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'add_card.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _Saved {
  final String label, kind, mark;
  _Saved(this.label, this.kind, this.mark);
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<_Saved> _items = [];
  bool _adding = false;
  final _vpa = TextEditingController();

  @override
  void dispose() {
    _vpa.dispose();
    super.dispose();
  }

  bool get _valid => RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(_vpa.text.trim());

  Widget _addRow(IconData icon, String title, String sub, {bool rec = false, required VoidCallback onTap, bool open = false}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            IconTile(icon, bg: rec ? C.lime : C.bg, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (rec) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(6)),
                      child: const Text('RECOMMENDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.lime, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 12.5, color: C.muted)),
              ]),
            ),
            AnimatedRotation(
              turns: open ? 0.125 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.ink, width: 1.5)),
                child: const Icon(Icons.add_rounded, size: 18),
              ),
            ),
          ]),
        ),
      );

  Widget _trust(IconData icon, String t) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: WhiteCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(children: [
              Icon(icon, size: 20),
              const SizedBox(height: 6),
              Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 28), children: [
        const TitleBar(title: 'Payment methods'),
        if (_items.isEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 250,
              height: 168,
              child: Stack(children: [
                Positioned(
                  left: 34,
                  top: 4,
                  child: Transform.rotate(
                    angle: -9 * math.pi / 180,
                    child: Container(width: 200, height: 124, decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(18))),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 36,
                  child: Container(
                    width: 214,
                    height: 128,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      color: C.ink,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x40111111), blurRadius: 40, offset: Offset(0, 18))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Container(width: 34, height: 24, decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(5))),
                        const Spacer(),
                        const Icon(Icons.contactless_outlined, color: C.white, size: 22),
                      ]),
                      const Text('•••• •••• ••••', style: TextStyle(color: C.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 3)),
                      const Text('PAY IN ONE TAP', style: TextStyle(color: C.faint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 22),
          const Highlight(before: 'Book ', marked: 'faster', after: ' next time.', size: 26, align: TextAlign.center),
          const SizedBox(height: 8),
          const Text('You have no saved payment methods yet. Add one and skip the typing at checkout.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: C.muted, height: 1.5)),
        ] else ...[
          const SectionLabel('Saved'),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WhiteCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: Border.all(color: i == 0 ? C.ink : C.white, width: 1.5),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: i == 0 ? C.lime : C.bg, borderRadius: BorderRadius.circular(12)),
                    child: Text(_items[i].mark, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(_items[i].label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                        if (i == 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(6)),
                            child: const Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.lime)),
                          ),
                        ],
                      ]),
                      Text(_items[i].kind, style: const TextStyle(fontSize: 12.5, color: C.muted)),
                    ]),
                  ),
                  CircleBtn(
                    icon: Icons.delete_outline_rounded,
                    iconColor: C.red,
                    bg: C.bg,
                    shadow: false,
                    size: 40,
                    tooltip: 'Remove',
                    onTap: () => setState(() => _items.removeAt(i)),
                  ),
                ]),
              ),
            ),
        ],
        const SectionLabel('Add a payment method'),
        WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            _addRow(Icons.alternate_email_rounded, 'UPI ID', 'Works with every UPI app',
                rec: true, open: _adding, onTap: () => setState(() => _adding = !_adding)),
            if (_adding)
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 0, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _vpa,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'yourname@okbank',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PillBtn('Save',
                        kind: BtnKind.dark,
                        height: 46,
                        fontSize: 14,
                        onTap: _valid
                            ? () => setState(() {
                                  _items.add(_Saved(_vpa.text.trim(), 'UPI ID · verified', '@'));
                                  _vpa.clear();
                                  _adding = false;
                                })
                            : null),
                  ]),
                  const SizedBox(height: 6),
                  const Text("We'll check the name on this UPI ID before saving.", style: TextStyle(fontSize: 12, color: C.muted2)),
                ]),
              ),
            const Divider(color: C.line, height: 1),
            _addRow(Icons.credit_card_rounded, 'Credit or debit card', 'Visa, Mastercard, RuPay',
                onTap: () async {
                  final c = await Navigator.pushNamed(context, '/add-card');
                  if (c is NewCard && mounted) {
                    setState(() => _items.add(_Saved('${c.brand} •••• ${c.last4}', 'Card · expires ${c.expiry}', c.brand == 'Mastercard' ? 'MC' : c.brand.toUpperCase())));
                    toast(context, 'Card saved');
                  }
                }),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          _trust(Icons.bolt_rounded, '1-tap\ncheckout'),
          _trust(Icons.verified_user_outlined, 'Secure &\nencrypted'),
          _trust(Icons.highlight_off_rounded, 'Remove\nanytime'),
        ]),
        const SizedBox(height: 16),
        const Text('Card details are saved by our payment partner, never on Checkdin.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted2)),
      ]),
    );
  }
}
