import '../models/ticket.dart';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'auth_service.dart';

class TicketService {
  TicketService({ApiService? api}) : _api = api ?? ApiService();

  static final List<Ticket> tickets = [];
  static final ValueNotifier<int> revision = ValueNotifier(0);
  final ApiService _api;

  Future<void> refreshFromServer() async {
    final response = await _api.get(
      '/customer/pesanan',
      token: AuthService.accessToken,
      queryParameters: const {'per_page': '50'},
    );
    final data = response['data'];
    if (data is! List<dynamic>) {
      throw const FormatException('Daftar tiket dari server tidak valid.');
    }

    final refreshedTickets = <Ticket>[];
    for (final booking in data.whereType<Map<String, dynamic>>()) {
      refreshedTickets.addAll(_ticketsFromBooking(booking));
    }
    tickets
      ..clear()
      ..addAll(refreshedTickets);
    revision.value++;
  }

  List<Ticket> _ticketsFromBooking(Map<String, dynamic> booking) {
    final destination = booking['destinasi'];
    final customer = booking['customer'];
    final leader = booking['ketua'];
    final details = booking['detail'];
    final payment = booking['pembayaran'];
    final issuedTickets = booking['tiket'];
    final visitDateValue = booking['tanggal_kunjungan'];
    if (booking['id'] == null ||
        booking['kode_booking'] is! String ||
        destination is! Map<String, dynamic> ||
        destination['nama'] is! String ||
        visitDateValue is! String ||
        booking['total_harga'] is! num ||
        issuedTickets is! List<dynamic>) {
      throw const FormatException('Data tiket dari server tidak lengkap.');
    }

    final visitDate = DateTime.parse(visitDateValue);
    final detailItems = details is List<dynamic>
        ? details.whereType<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final memberData = booking['anggota'];
    final memberNames = memberData is List<dynamic>
        ? memberData
              .map(
                (member) =>
                    member is Map<String, dynamic> ? member['nama'] : member,
              )
              .whereType<String>()
              .toList()
        : <String>[];
    var childCount = 0;
    var adultCount = 0;
    for (final detail in detailItems) {
      final ticketType = detail['jenis_tiket'];
      final quantity = detail['jumlah'];
      if (ticketType is! Map<String, dynamic> ||
          ticketType['nama'] is! String ||
          quantity is! num) {
        continue;
      }
      final isChild = RegExp(
        r'anak|child',
        caseSensitive: false,
      ).hasMatch(ticketType['nama'] as String);
      if (isChild) {
        childCount += quantity.toInt();
      } else {
        adultCount += quantity.toInt();
      }
    }

    return issuedTickets.whereType<Map<String, dynamic>>().map((ticket) {
      final status = ticket['status'] is String
          ? (ticket['status'] as String).toLowerCase()
          : 'unknown';
      final customerData = customer is Map<String, dynamic> ? customer : null;
      final leaderData = leader is Map<String, dynamic> ? leader : null;
      return Ticket(
        id: ticket['id']?.toString() ?? '',
        bookingId: booking['kode_booking'] as String,
        bookingRecordId: booking['id']?.toString() ?? '',
        destinationId: destination['id']?.toString() ?? '',
        destinationName: destination['nama'] as String,
        destinationImageUrl: destination['foto_utama'] is String
            ? _api.resolveUrl(destination['foto_utama'] as String)
            : null,
        visitDate: visitDate,
        adultCount: adultCount,
        childCount: childCount,
        leaderName: leaderData?['nama'] is String
            ? leaderData!['nama'] as String
            : (customerData?['nama'] as String? ?? ''),
        leaderEmail: leaderData?['email'] is String
            ? leaderData!['email'] as String
            : (customerData?['email'] as String? ?? ''),
        leaderPhone: leaderData?['no_hp'] is String
            ? leaderData!['no_hp'] as String
            : (customerData?['no_hp'] as String? ?? ''),
        memberNames: memberNames,
        amountPaid: (booking['total_harga'] as num).round(),
        paymentMethod:
            payment is Map<String, dynamic> && payment['metode'] is String
            ? payment['metode'] as String
            : '',
        status: status == 'active'
            ? 'valid'
            : status == 'used'
            ? 'used'
            : status,
        qrCodePayload: ticket['kode_qr'] is String
            ? ticket['kode_qr'] as String
            : null,
      );
    }).toList();
  }

  Future<Ticket> issueTicket({
    required String bookingId,
    String destinationId = '',
    required String destinationName,
    String? destinationImageUrl,
    required DateTime visitDate,
    required int adultCount,
    required int childCount,
    required String leaderName,
    required String leaderEmail,
    required String leaderPhone,
    required List<String> memberNames,
    int amountPaid = 0,
    String paymentMethod = 'QRIS',
  }) async {
    final ticket = Ticket(
      id: 'JGO-${tickets.length + 1}'.padLeft(7, '0'),
      bookingId: bookingId,
      destinationId: destinationId,
      destinationName: destinationName,
      destinationImageUrl: destinationImageUrl,
      visitDate: visitDate,
      adultCount: adultCount,
      childCount: childCount,
      leaderName: leaderName,
      leaderEmail: leaderEmail,
      leaderPhone: leaderPhone,
      memberNames: List.unmodifiable(memberNames),
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
    );
    tickets.add(ticket);
    revision.value++;
    return ticket;
  }

  static Ticket? findById(String ticketId) {
    for (final ticket in tickets) {
      if (ticket.id == ticketId) return ticket;
    }
    return null;
  }

  static String qrPayload(Ticket ticket) =>
      ticket.qrCodePayload ??
      'JEMBERGO|${ticket.id}|${ticket.bookingId}|${ticket.destinationName}|${ticket.visitDate.toIso8601String()}';

  static bool markAsUsed(String ticketId, String userEmail) {
    final ticketIndex = tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = tickets[ticketIndex];
    final today = DateTime.now();
    final visitDay = DateTime(
      ticket.visitDate.year,
      ticket.visitDate.month,
      ticket.visitDate.day,
    );
    final currentDay = DateTime(today.year, today.month, today.day);
    if (ticket.status != 'valid' ||
        ticket.leaderEmail.trim().toLowerCase() !=
            userEmail.trim().toLowerCase() ||
        visitDay.isAfter(currentDay)) {
      return false;
    }

    tickets[ticketIndex] = ticket.copyWith(status: 'used');
    revision.value++;
    return true;
  }
}
