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
    String location = 'Jember',
    String? imageUrl,
    int unitPrice = 0,
  }) async {
    final ticketCode =
        'JMB-${DateTime.now().year}-${(tickets.length + 1).toString().padLeft(5, '0')}';
    final ticket = Ticket(
      id: ticketCode,
      bookingId: bookingId,
      destinationName: destinationName,
      visitDate: visitDate,
      adultCount: adultCount,
      childCount: childCount,
      leaderName: leaderName,
      leaderEmail: leaderEmail,
      leaderPhone: leaderPhone,
      memberNames: List.unmodifiable(memberNames),
      location: location,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
    );
    tickets.add(ticket);
    return ticket;
  }
}
