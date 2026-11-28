import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../loading.dart';
import '../api/api.dart';
import 'add_card.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _Saved {
  final String label, kind, mark;
  final SavedCard? card;
  _Saved(this.label, this.kind, this.mark, {this.card});
}

_Saved _fromCard(SavedCard c) =>
    _Saved(c.label, 'Card · expires ${c.expiry}', c.brand == 'Mastercard' ? 'MC' : c.brand.toUpperCase(), card: c);

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<_Saved> _items = [];
  bool _adding = false;
  final _vpa = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items.addAll(app.cards.map(_fromCard));
  }

  @override
  void dispose() {
    _vpa.dispose();
    super.dispose();
  }

  bool get _valid => RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(_vpa.text.trim());

  Widget _addRow(IconData icon, String title, String sub, {bool rec = false, required VoidCallback onTap, bool open = false}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.lg),
          child: Row(children: [
            IconTile(icon, bg: rec ? C.limeBg : C.bg, size: 44),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(title, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  if (rec) ...[
                    const SizedBox(width: Sp.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xxs),
                      decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.sm)),
                      child: Text('RECOMMENDED', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: C.lime, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: Sp.xxs),
                Text(sub, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
              ]),
            ),
            AnimatedRotation(
              turns: open ? 0.125 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.ink, width: 1.5)),
                child: const Icon(Icons.add_rounded, size: Ic.md),
              ),
            ),
          ]),
        ),
      );

  Widget _trust(IconData icon, String t) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
          child: WhiteCard(
            radius: R.lg,
            padding: const EdgeInsets.symmetric(vertical: Sp.md, horizontal: Sp.sm),
            child: Column(children: [
              Icon(icon, size: Ic.md),
              const SizedBox(height: Sp.sm),
              Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700, height: 1.3)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loader<void>(
        load: api.paymentMethods,
        cacheKey: 'payment-methods',
        skeleton: const SkPage(title: 'Payments', child: SkRows(count: 4, height: 70)),
        builder: (context, _) => ListView(padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 28), children: [
        const TitleBar(title: 'Payment methods'),
        if (_items.isEmpty) ...[
          const SizedBox(height: Sp.xxl),
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
                    child: Container(width: 200, height: 124, decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.lg))),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 36,
                  child: Container(
                    width: 214,
                    height: 128,
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.lg),
                    decoration: BoxDecoration(
                      color: C.inkBg,
                      borderRadius: BorderRadius.circular(R.lg),
                      boxShadow: const [BoxShadow(color: P.inkA25, blurRadius: 40, offset: Offset(0, 18))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Container(width: 34, height: 24, decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.sm))),
                        const Spacer(),
                        Icon(Icons.contactless_rounded, color: C.white, size: Ic.md),
                      ]),
                      Text('•••• •••• ••••', style: TextStyle(color: C.white, fontSize: Fs.lg, fontWeight: FontWeight.w700, letterSpacing: 3)),
                      Text('PAY IN ONE TAP', style: TextStyle(color: C.faint, fontSize: Fs.xs, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: Sp.xxl),
          const Highlight(before: 'Book ', marked: 'faster', after: ' next time.', size: 26, align: TextAlign.center),
          const SizedBox(height: Sp.sm),
          Text('You have no saved payment methods yet. Add one and skip the typing at checkout.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.md, color: C.muted, height: 1.5)),
        ] else ...[
          const SectionLabel('Saved'),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.md),
              child: WhiteCard(
                radius: R.xl,
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
                border: Border.all(color: i == 0 ? C.ink : C.white, width: 1.5),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: i == 0 ? C.limeBg : C.bg, borderRadius: BorderRadius.circular(R.md)),
                    child: Text(_items[i].mark, style: const TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(_items[i].label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700))),
                        if (i == 0) ...[
                          const SizedBox(width: Sp.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xxs),
                            decoration: BoxDecoration(color: C.inkBg, borderRadius: BorderRadius.circular(R.sm)),
                            child: Text('DEFAULT', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, color: C.lime)),
                          ),
                        ],
                      ]),
                      Text(_items[i].kind, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                    ]),
                  ),
                  CircleBtn(
                    icon: Icons.delete_outline_rounded,
                    iconColor: C.red,
                    bg: C.bg,
                    shadow: false,
                    size: 40,
                    tooltip: 'Remove',
                    onTap: () {
                      final item = _items[i];
                      final c = item.card;
                      final at = i;
                      final cardAt = c == null ? -1 : app.cards.indexOf(c);
                      setState(() {
                        if (c != null) app.cards.remove(c);
                        _items.removeAt(at);
                      });
                      void restore() {
                        if (!mounted) return;
                        setState(() {
                          if (c != null && !app.cards.contains(c)) app.cards.insert(cardAt.clamp(0, app.cards.length), c);
                          if (!_items.contains(item)) _items.insert(at.clamp(0, _items.length), item);
                        });
                      }
                      // Removed on screen now; the server is only told once Undo has expired.
                      var undone = false;
                      undoToast(context, 'Removed ${item.kind}', () {
                        undone = true;
                        restore();
                      });
                      Future<void>.delayed(const Duration(seconds: 5), () async {
                        if (undone || c == null) return;
                        try {
                          await api.removeCard(c.last4);
                        } on ApiError catch (e) {
                          restore();
                          if (mounted) toast(context, e.message);
                        }
                      });
                    },
                  ),
                ]),
              ),
            ),
        ],
        const SectionLabel('Add a payment method'),
        WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
          child: Column(children: [
            _addRow(Icons.alternate_email_rounded, 'UPI ID', 'Works with every UPI app',
                rec: true, open: _adding, onTap: () => setState(() => _adding = !_adding)),
            if (_adding)
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 0, Sp.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _vpa,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'yourname@okbank',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md)),
                        ),
                      ),
                    ),
                    const SizedBox(width: Sp.sm),
                    PillBtn('Save',
                        kind: BtnKind.dark,
                        height: 46,
                        fontSize: Fs.md,
                        onTap: _valid
                            ? () => setState(() {
                                  _items.add(_Saved(_vpa.text.trim(), 'UPI ID · verified', '@'));
                                  _vpa.clear();
                                  _adding = false;
                                })
                            : null),
                  ]),
                  const SizedBox(height: Sp.sm),
                  Text("We'll check the name on this UPI ID before saving.", style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
                ]),
              ),
            Divider(color: C.line, height: 1),
            _addRow(Icons.credit_card_rounded, 'Credit or debit card', 'Visa, Mastercard, RuPay',
                onTap: () async {
                  final c = await Navigator.pushNamed(context, '/add-card');
                  if (c is NewCard && mounted) {
                    final sc = SavedCard(c.brand, c.last4, c.expiry, c.name);
                    app.cards.add(sc);
                    setState(() => _items.add(_fromCard(sc)));
                    toast(context, 'Card saved');
                  }
                }),
          ]),
        ),
        const SizedBox(height: Sp.lg),
        Row(children: [
          _trust(Icons.bolt_rounded, '1-tap\ncheckout'),
          _trust(Icons.verified_user_rounded, 'Secure &\nencrypted'),
          _trust(Icons.highlight_off_rounded, 'Remove\nanytime'),
        ]),
        const SizedBox(height: Sp.lg),
        Text('Card details are saved by our payment partner, never on Checkdin.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: Fs.sm, color: C.muted2)),
      ]),
      ),
    );
  }
}
