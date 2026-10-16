import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/ticket.dart';
import 'api_service.dart';
import 'auth_service.dart';

class TicketPdfService {
  static Future<Uint8List> download(
    Ticket ticket, {
    ApiService? api,
    String? token,
  }) {
    if (ticket.bookingRecordId.isEmpty) {
      throw const FormatException(
        'ID pemesanan tidak tersedia untuk mengunduh e-ticket.',
      );
    }

    return (api ?? ApiService()).getBytes(
      '/customer/pesanan/${ticket.bookingRecordId}/e-ticket/pdf',
      token: token ?? AuthService.accessToken,
      accept: 'application/json, application/pdf',
      expectedContentType: 'application/pdf',
    );
  }

  static Future<bool> save(Ticket ticket) async {
    final bytes = await download(ticket);
    final savedUri = await FilePicker.saveFile(
      fileName: 'e-ticket-${ticket.bookingId}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    return savedUri != null;
  }
}
