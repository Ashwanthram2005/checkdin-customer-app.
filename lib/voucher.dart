import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext, ValueNotifier;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'state.dart';
import 'theme.dart';

String _rs(int v) => 'Rs. ${inr(v).replaceAll('₹', '')}';

/// Builds the booking voucher + payment receipt PDF and opens the share/save sheet.
/// True while the voucher PDF is being made (buttons show a spinner).
final voucherBusy = ValueNotifier<bool>(false);

Future<void> shareVoucher(BuildContext context, {String? bookingId}) async {
  bookingId ??= app.bookingId;
  if (voucherBusy.value) return;
  voucherBusy.value = true;
  try {
    final bytes = await buildVoucher(bookingId);
    await Printing.sharePdf(bytes: bytes, filename: 'Checkdin-$bookingId.pdf');
  } catch (_) {
    if (context.mounted) toast(context, 'Couldn\'t create the voucher. Try again.');
  } finally {
    voucherBusy.value = false;
  }
}

Future<pw.Document> _doc(String id) async {
  pw.ThemeData? theme;
  try {
    theme = pw.ThemeData.withFont(base: await PdfGoogleFonts.robotoRegular(), bold: await PdfGoogleFonts.robotoBold());
  } catch (_) {
    theme = null; // offline: fall back to the built-in font
  }
  const ink = PdfColor.fromInt(0xFF111111);
  const lime = PdfColor.fromInt(0xFFD1F148);
  const muted = PdfColor.fromInt(0xFF5C5C55);
  const line = PdfColor.fromInt(0xFFE2E2DA);
  final h = app.hotel;
  final room = app.gross - app.fees;

  pw.Widget row(String k, String v, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: Sp.xs),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(k, style: const pw.TextStyle(color: muted, fontSize: Fs.xs))),
          pw.Text(v, style: pw.TextStyle(fontSize: bold ? 12 : 10.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ]),
      );
  pw.Widget label(String t) =>
      pw.Padding(padding: const pw.EdgeInsets.only(top: Sp.lg, bottom: Sp.sm), child: pw.Text(t.toUpperCase(), style: const pw.TextStyle(fontSize: Fs.xs, color: muted, letterSpacing: 1.2)));

  final doc = pw.Document(theme: theme, title: 'Checkdin booking $id', author: 'Checkdin');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(Sp.x4),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Container(width: 26, height: 26, decoration: const pw.BoxDecoration(color: lime, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: Sp.sm),
        pw.Text('Checkdin', style: pw.TextStyle(fontSize: Fs.xl, fontWeight: pw.FontWeight.bold)),
        pw.Spacer(),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Booking voucher & payment receipt', style: pw.TextStyle(fontSize: Fs.xs, fontWeight: pw.FontWeight.bold)),
          pw.Text('Booking ID $id', style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
        ]),
      ]),
      pw.SizedBox(height: Sp.lg),
      pw.Container(
        padding: const pw.EdgeInsets.all(Sp.lg),
        decoration: pw.BoxDecoration(color: ink, borderRadius: pw.BorderRadius.circular(R.md)),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CONFIRMED', style: const pw.TextStyle(color: lime, fontSize: Fs.xs, letterSpacing: 1.4)),
              pw.SizedBox(height: Sp.xs),
              pw.Text(h.name, style: pw.TextStyle(color: PdfColors.white, fontSize: Fs.lg, fontWeight: pw.FontWeight.bold)),
              pw.Text(h.address, style: const pw.TextStyle(color: PdfColors.grey400, fontSize: Fs.xs)),
            ]),
          ),
          pw.Text(_rs(app.total), style: pw.TextStyle(color: lime, fontSize: Fs.h2, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      label('Your stay'),
      pw.Row(children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('CHECK-IN', style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
            pw.Text(app.inTimeLabel, style: pw.TextStyle(fontSize: Fs.md, fontWeight: pw.FontWeight.bold)),
            pw.Text(app.inDateLabel, style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
          ]),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
          decoration: pw.BoxDecoration(color: lime, borderRadius: pw.BorderRadius.circular(R.md)),
          child: pw.Text(app.stayLabel, style: pw.TextStyle(fontSize: Fs.xs, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('CHECK-OUT', style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
            pw.Text(app.outTimeLabel, style: pw.TextStyle(fontSize: Fs.md, fontWeight: pw.FontWeight.bold)),
            pw.Text(app.outDateLabel, style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
          ]),
        ),
      ]),
      pw.SizedBox(height: Sp.sm),
      row('Room', 'Deluxe Room · ${app.rooms} ${app.rooms > 1 ? 'rooms' : 'room'}'),
      row('Guests', app.guestsLabel),
      label('Guest'),
      row('Name', app.stayGuestName.isEmpty ? '—' : app.stayGuestName),
      row('Mobile', app.stayGuestPhone),
      if (app.forSomeoneElse) row('Booked by', app.name),
      if (app.email.isNotEmpty) row('Email', app.email),
      label('Payment'),
      row('Room price', _rs(room)),
      row('Taxes & fees', _rs(app.fees)),
      if (app.discount > 0) row('Coupon ${app.couponCode}', '- ${_rs(app.discount)}'),
      pw.Divider(color: line),
      row('Total paid', _rs(app.total), bold: true),
      row('Paid via', app.paidWith),
      row('Payment partner', 'Razorpay'),
      label('At check-in'),
      pw.Bullet(text: 'Every guest must show an original government photo ID (Aadhaar, passport, driving licence or voter ID).', style: const pw.TextStyle(fontSize: Fs.xs)),
      pw.Bullet(text: 'Show this voucher or your Booking ID at the front desk.', style: const pw.TextStyle(fontSize: Fs.xs)),
      pw.Bullet(text: 'Cancel 5+ hrs before check-in for a 50% refund, 5–3 hrs for 25%; no refund after that or for no-shows.', style: const pw.TextStyle(fontSize: Fs.xs)),
      pw.Spacer(),
      pw.Divider(color: line),
      pw.Text('Checkdin, Chennai, Tamil Nadu · hello@checkdin.in · checkdin.in', style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
      pw.Text('This is a computer-generated receipt and does not need a signature. The hotel issues its own GST invoice where applicable.',
          style: const pw.TextStyle(fontSize: Fs.xs, color: muted)),
    ]),
  ));
  return doc;
}

Future<Uint8List> buildVoucher(String id) async => (await _doc(id)).save();
