import '../../core/constants/app_constants.dart';
import '../models/ticket.dart';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'auth_service.dart';

class TicketService {
  TicketService({ApiService? api}) : _api = api ?? ApiService();

  static final List<Ticket> tickets = [];
  static final ValueNotifier<int> revision = ValueNotifier(0);
  final ApiService _api;

  Future<void> refreshFromServer({String? expectedCustomerId}) async {
    const pageSize = 50;
    var page = 1;
    var lastPage = 1;
    final bookings = <Map<String, dynamic>>[];
    do {
      final response = await _api.get(
        '/customer/pesanan',
        token: AuthService.accessToken,
        queryParameters: {'per_page': '$pageSize', 'page': '$page'},
      );
      final data = response['data'];
      if (data is! List<dynamic>) {
        throw const FormatException('Daftar tiket dari server tidak valid.');
      }
      bookings.addAll(data.whereType<Map<String, dynamic>>());
      final metadata = response['meta'];
      if (metadata == null) {
        break;
      }
      if (metadata is! Map<String, dynamic> ||
          metadata['last_page'] is! num ||
          (metadata['last_page'] as num).toInt() < page) {
        throw const FormatException(
          'Informasi halaman tiket dari server tidak valid.',
        );
      }
      lastPage = (metadata['last_page'] as num).toInt();
      page++;
    } while (page <= lastPage);

    final refreshedTickets = <Ticket>[];
    for (final booking in bookings) {
      refreshedTickets.add(_ticketFromBooking(booking));
    }
    if (expectedCustomerId != null &&
        AuthService.currentUser?.id != expectedCustomerId) {
      return;
    }
    tickets
      ..clear()
      ..addAll(refreshedTickets);
    revision.value++;
  }

  Ticket _ticketFromBooking(Map<String, dynamic> booking) {
    final destination = booking['destinasi'];
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
        issuedTickets is! List<dynamic> ||
        booking['status'] is! String) {
      throw const FormatException('Data tiket dari server tidak lengkap.');
    }

    final visitDate = DateTime.parse(visitDateValue);
    final bookingStatus = (booking['status'] as String).toUpperCase();
    final ticketItems = issuedTickets.whereType<Map<String, dynamic>>().toList();
    if (ticketItems.length != issuedTickets.length ||
        ticketItems.any(
          (ticket) =>
              ticket['id'] == null ||
              ticket['status'] is! String ||
              ticket['kode_qr'] is! String,
        )) {
      throw const FormatException('Data tiket dari server tidak lengkap.');
    }
    final rawTicketStatuses = ticketItems
        .map((ticket) => ticket['status'])
        .whereType<String>()
        .map((status) => status.toUpperCase())
        .toList();
    final hasActiveTicket = rawTicketStatuses.contains('ACTIVE');
    final hasUsedTicket = rawTicketStatuses.contains('USED');
    final hasExpiredTicket = rawTicketStatuses.contains('EXPIRED');
    final status = rawTicketStatuses.isEmpty
        ? _ticketStatusFromBooking(bookingStatus)
        : rawTicketStatuses.every((status) => status == 'USED')
        ? 'used'
        : rawTicketStatuses.contains('USED')
        ? 'partial'
        : _ticketStatusFromBooking(rawTicketStatuses.first);
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

    final ticket = ticketItems.isEmpty ? null : ticketItems.first;
    final leaderData = leader is Map<String, dynamic> ? leader : null;
    final paymentData = payment is Map<String, dynamic> ? payment : null;
    final paymentMethod = paymentData?['metode'] is String
        ? paymentData!['metode'] as String
        : '';
    final paymentStatus = paymentData?['status'] is String
        ? (paymentData!['status'] as String).toUpperCase()
        : bookingStatus;
    final deadline = booking['batas_waktu_pembayaran'];

    return Ticket(
      id: ticket?['id']?.toString() ?? 'booking-${booking['id']}',
      bookingId: booking['kode_booking'] as String,
      bookingRecordId: booking['id']?.toString() ?? '',
      destinationId: destination['id']?.toString() ?? '',
      destinationName: destination['nama'] as String,
      destinationImageUrl: destination['foto_utama'] is String
          ? _api.resolveUrl(destination['foto_utama'] as String)
          : null,
      destinationLocation: destination['alamat'] is String
          ? destination['alamat'] as String
          : '',
      visitDate: visitDate,
      adultCount: adultCount,
      childCount: childCount,
      leaderName: leaderData?['nama'] is String
          ? leaderData!['nama'] as String
          : '',
      leaderEmail: leaderData?['email'] is String
          ? leaderData!['email'] as String
          : '',
      leaderPhone: leaderData?['no_hp'] is String
          ? leaderData!['no_hp'] as String
          : '',
      memberNames: memberNames,
      amountPaid: (booking['total_harga'] as num).round(),
      paymentMethod: paymentMethod,
      status: status,
      qrCodePayload: ticket?['kode_qr'] is String
          ? ticket!['kode_qr'] as String
          : null,
      bookingStatus: bookingStatus,
      paymentStatus: paymentStatus,
      paymentDeadline: deadline is String ? DateTime.tryParse(deadline) : null,
      hasIssuedTicket: ticketItems.isNotEmpty,
      hasActiveTicket: hasActiveTicket,
      hasUsedTicket: hasUsedTicket,
      hasExpiredTicket: hasExpiredTicket,
      isReviewed: ticket?['reviewed'] == true,
    );
  }

  String _ticketStatusFromBooking(String status) => switch (status) {
    'ACTIVE' || 'PAID' => 'valid',
    'USED' => 'used',
    'PARTIAL' => 'partial',
    'EXPIRED' => 'expired',
    'PENDING' => 'pending',
    'FAILED' => 'failed',
    _ => 'unknown',
  };

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
      ticket.qrCodePayload == null
      ? 'JEMBERGO|${ticket.id}|${ticket.bookingId}|${ticket.destinationName}|${ticket.visitDate.toIso8601String()}'
      : _ticketScanUrl(ticket.qrCodePayload!);

  static String _ticketScanUrl(String qrCode) {
    final apiUri = Uri.parse(AppConstants.apiBaseUrl);
    final basePath = apiUri.path.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
    final routePath = '${basePath == '/' ? '' : basePath}/tiket/scan';
    return apiUri
            .replace(
              path: routePath,
              queryParameters: {'kode_qr': qrCode},
            )
            .toString();
  }

  Future<void> submitReview({
    required String ticketId,
    required int rating,
    required String review,
  }) async {
    await _api.post(
      '/customer/tiket/$ticketId/ulasan',
      token: AuthService.accessToken,
      body: {'rating': rating, 'ulasan': review},
    );
    final index = tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index != -1) {
      tickets[index] = tickets[index].copyWith(isReviewed: true);
      revision.value++;
    }
  }

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
