import '../models/ticket.dart';

import 'package:flutter/foundation.dart';

class TicketService {
  static final List<Ticket> tickets = [];
  static final ValueNotifier<int> revision = ValueNotifier(0);

  Future<Ticket> issueTicket({
    required String bookingId,
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
}
