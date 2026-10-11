import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';

import '../models/ticket.dart';
import 'ticket_service.dart';

class TicketPdfService {
  static Future<Uint8List> generate(Ticket ticket) async {
    final qrImageData = await QrPainter(
      data: TicketService.qrPayload(ticket),
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(720);
    if (qrImageData == null) {
      throw StateError('QR tiket gagal dibuat.');
    }

    final pdf = pw.Document(
      title: 'E-Tiket ${ticket.destinationName}',
      author: 'JemberGo',
    );
    final qrImage = pw.MemoryImage(qrImageData.buffer.asUint8List());
    final ink = PdfColor.fromHex('#0B294A');
    final blue = PdfColor.fromHex('#0874E8');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#DCE5F4')),
            borderRadius: pw.BorderRadius.circular(18),
          ),
          padding: const pw.EdgeInsets.all(22),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'JEMBERGO',
                style: pw.TextStyle(
                  color: blue,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'E-TIKET WISATA',
                style: pw.TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                ticket.destinationName,
                style: pw.TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Center(child: pw.Image(qrImage, width: 210, height: 210)),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  ticket.bookingId,
                  style: pw.TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 18),
              _detailRow('Kode tiket', ticket.id, ink),
              _detailRow('Nama pemesan', ticket.leaderName, ink),
              _detailRow('Email', ticket.leaderEmail, ink),
              _detailRow(
                'Tanggal kunjungan',
                _formatDate(ticket.visitDate),
                ink,
              ),
              _detailRow('Jumlah tiket', '${ticket.quantity} orang', ink),
              _detailRow(
                'Status',
                ticket.status == 'used' ? 'Terpakai' : 'Aktif',
                ink,
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EEF4FF'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'Tunjukkan QR ini kepada petugas saat berkunjung. Simpan tiket untuk keperluan check-in.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(color: ink, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static Future<bool> save(Ticket ticket) async {
    final bytes = await generate(ticket);
    final safeDestinationName = ticket.destinationName
        .replaceAll(RegExp(r'[^\w-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final savedUri = await FilePicker.saveFile(
      fileName: 'JemberGo_${safeDestinationName}_${ticket.id}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    return savedUri != null;
  }

  static pw.Widget _detailRow(String label, String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 112,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#697586'),
                  fontSize: 9,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
