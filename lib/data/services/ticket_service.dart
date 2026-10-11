import '../models/ticket.dart';

import 'package:flutter/foundation.dart';

class TicketService {
  static final List<Ticket> tickets = [];
  static final ValueNotifier<int> revision = ValueNotifier(0);

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
      'JEMBERGO|${ticket.id}|${ticket.bookingId}|${ticket.destinationName}|${ticket.visitDate.toIso8601String()}';

  static bool markAsUsed(String ticketId, String userEmail) {
    final ticketIndex = tickets.indexWhere(
      (ticket) => ticket.id == ticketId,
    );
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
