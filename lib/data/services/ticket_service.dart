import '../models/ticket.dart';

class TicketService {
  static final List<Ticket> tickets = [];

  Future<Ticket> issueTicket({
    required String bookingId,
    required String destinationName,
    required DateTime visitDate,
    required int adultCount,
    required int childCount,
    required String leaderName,
    required String leaderEmail,
    required String leaderPhone,
    required List<String> memberNames,
  }) async {
    final ticket = Ticket(
      id: 'JGO-${tickets.length + 1}'.padLeft(7, '0'),
      bookingId: bookingId,
      destinationName: destinationName,
      visitDate: visitDate,
      adultCount: adultCount,
      childCount: childCount,
      leaderName: leaderName,
      leaderEmail: leaderEmail,
      leaderPhone: leaderPhone,
      memberNames: List.unmodifiable(memberNames),
    );
    tickets.add(ticket);
    return ticket;
  }
}