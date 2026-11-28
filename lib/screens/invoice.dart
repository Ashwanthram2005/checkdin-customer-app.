import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../state.dart';
import '../theme.dart';

/// GST split for the stay. Rooms under ₹7,500 a night: 12% GST (6% CGST + 6% SGST).
class _Tax {
  final int total, taxable, cgst, sgst;
  _Tax._(this.total, this.taxable, this.cgst, this.sgst);
  factory _Tax.of(int total) {
    final taxable = (total / 1.12).round();
    final tax = total - taxable;
    final c = tax ~/ 2;
    return _Tax._(total, taxable, c, tax - c);
  }
}

String get _invoiceNo => 'INV-${app.bookingId.replaceAll('CKD-', '')}';
const _hotelGstin = '33AAACG1234R1Z9';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(bytes: bytes, filename: 'Checkdin-$_invoiceNo.pdf');
    } catch (_) {
      if (mounted) toast(context, 'Couldn\'t create the invoice. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _Tax.of(app.total);
    final h = app.hotel;
    final biz = app.gstin.isNotEmpty;
    Widget kv(String k, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.xs + 2),
          child: Row(children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: Fs.base, color: bold ? C.ink : C.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
            Text(v, style: TextStyle(fontSize: bold ? Fs.lg : Fs.base, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ]),
        );
    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(top: Sp.lg, bottom: Sp.xs),
          child: Text(s, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w700, letterSpacing: 1, color: C.muted)),
        );
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(Sp.xl, MediaQuery.of(context).padding.top + Sp.md, Sp.xl, Sp.xxl),
            children: [
              const TitleBar(title: 'Tax invoice'),
              const SizedBox(height: Sp.xl),
              WhiteCard(
                padding: const EdgeInsets.all(Sp.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Image.asset('assets/logo_icon.png', width: 32, height: 32),
                    const SizedBox(width: Sp.sm),
                    const Text('Checkdin', style: TextStyle(fontSize: Fs.lg, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.sm + 2, vertical: Sp.xs),
                      decoration: BoxDecoration(color: C.limeBg, borderRadius: BorderRadius.circular(R.pill)),
                      child: const Text('PAID', style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w800, letterSpacing: 1, color: P.ink)),
                    ),
                  ]),
                  const SizedBox(height: Sp.md),
                  kv('Invoice number', _invoiceNo),
                  kv('Invoice date', dateLabel(app.today)),
                  kv('Booking ID', app.bookingId),
                  label('BILLED TO'),
                  Text(biz ? app.gstCompany : app.name.isEmpty ? 'Guest' : app.name, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  if (biz) Text('GSTIN ${app.gstin}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  if (!biz && app.email.isNotEmpty) Text(app.email, style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  label('HOTEL'),
                  Text(h.name, style: const TextStyle(fontSize: Fs.md, fontWeight: FontWeight.w700)),
                  Text(h.address, style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
                  Text('GSTIN $_hotelGstin', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  label('STAY'),
                  Text('${app.stayLabel} · ${app.inDateLabel}, ${app.inTimeLabel} – ${app.outTimeLabel}',
                      style: const TextStyle(fontSize: Fs.base, fontWeight: FontWeight.w600)),
                  Text('${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'} · ${app.guestsLabel}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                  const SizedBox(height: Sp.md),
                  Divider(color: C.line, height: 1),
                  const SizedBox(height: Sp.sm),
                  kv('Room charges (SAC 996311)', inr(t.taxable)),
                  kv('CGST @ 6%', inr(t.cgst)),
                  kv('SGST @ 6%', inr(t.sgst)),
                  const SizedBox(height: Sp.xs),
                  Divider(color: C.line, height: 1),
                  kv('Total paid', inr(t.total), bold: true),
                  Text('Paid with ${app.paidWith}', style: TextStyle(fontSize: Fs.sm, color: C.muted)),
                ]),
              ),
              if (!biz) ...[
                const SizedBox(height: Sp.lg),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: Ic.sm, color: C.muted),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text('Booking for work? Turn on "Business booking" and add your GSTIN while booking, to claim GST input credit.',
                        style: TextStyle(fontSize: Fs.sm, color: C.muted, height: 1.4)),
                  ),
                ]),
              ],
            ],
          ),
        ),
        BottomBar(
          child: PillBtn('Download PDF', kind: BtnKind.dark, expand: true, height: 54, icon: Icons.download_rounded, loading: _busy,
              onTap: _busy ? null : _download),
        ),
      ]),
    );
  }
}

Future<Uint8List> _buildPdf() async {
  pw.ThemeData? theme;
  try {
    theme = pw.ThemeData.withFont(base: await PdfGoogleFonts.robotoRegular(), bold: await PdfGoogleFonts.robotoBold());
  } catch (_) {
    theme = null;
  }
  const lime = PdfColor.fromInt(0xFFD1F148);
  const muted = PdfColor.fromInt(0xFF5C5C55);
  const line = PdfColor.fromInt(0xFFE2E2DA);
  String rs(int v) => 'Rs. ${inr(v).replaceAll('₹', '')}';
  final t = _Tax.of(app.total);
  final h = app.hotel;
  final biz = app.gstin.isNotEmpty;

  pw.Widget kv(String k, String v, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(k, style: pw.TextStyle(fontSize: 10.5, color: bold ? PdfColors.black : muted, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
          pw.Text(v, style: pw.TextStyle(fontSize: bold ? 13 : 10.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ]),
      );
  pw.Widget label(String s) =>
      pw.Padding(padding: const pw.EdgeInsets.only(top: 14, bottom: 4), child: pw.Text(s, style: const pw.TextStyle(fontSize: 9, color: muted, letterSpacing: 1.2)));

  final doc = pw.Document(theme: theme, title: 'Checkdin tax invoice $_invoiceNo', author: 'Checkdin');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(40),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Container(width: 26, height: 26, decoration: const pw.BoxDecoration(color: lime, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 8),
        pw.Text('Checkdin', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Spacer(),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(_invoiceNo, style: const pw.TextStyle(fontSize: 10, color: muted)),
          pw.Text('Date ${dateLabel(app.today)} · Booking ${app.bookingId}', style: const pw.TextStyle(fontSize: 10, color: muted)),
        ]),
      ]),
      pw.SizedBox(height: 16),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            label('BILLED TO'),
            pw.Text(biz ? app.gstCompany : (app.name.isEmpty ? 'Guest' : app.name), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            if (biz) pw.Text('GSTIN ${app.gstin}', style: const pw.TextStyle(fontSize: 10, color: muted)),
          ]),
        ),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            label('HOTEL'),
            pw.Text(h.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(h.address, style: const pw.TextStyle(fontSize: 10, color: muted)),
            pw.Text('GSTIN $_hotelGstin', style: const pw.TextStyle(fontSize: 10, color: muted)),
          ]),
        ),
      ]),
      label('STAY'),
      pw.Text('${app.stayLabel} · ${app.inDateLabel}, ${app.inTimeLabel} - ${app.outTimeLabel} · ${app.rooms} room(s) · ${app.guestsLabel}',
          style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      pw.Container(height: 1, color: line),
      kv('Room charges (SAC 996311)', rs(t.taxable)),
      kv('CGST @ 6%', rs(t.cgst)),
      kv('SGST @ 6%', rs(t.sgst)),
      pw.Container(height: 1, color: line),
      kv('Total paid', rs(t.total), bold: true),
      pw.Text('Paid with ${app.paidWith}', style: const pw.TextStyle(fontSize: 10, color: muted)),
      pw.Spacer(),
      pw.Text('This is a computer-generated invoice and needs no signature.', style: const pw.TextStyle(fontSize: 9, color: muted)),
    ]),
  ));
  return doc.save();
}
