class BookingParticipant {
  const BookingParticipant({
    required this.name,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.ticketPrice,
  });

  final String name;
  final int ticketTypeId;
  final String ticketTypeName;
  final int ticketPrice;
}

class Booking {
  const Booking({
    required this.id,
    required this.code,
    required this.destinationId,
    required this.visitDate,
    required this.totalAmount,
    required this.leaderName,
    required this.leaderEmail,
    required this.leaderPhone,
    required this.participants,
    required this.status,
    this.paymentDeadline,
  });

  final String id;
  final String code;
  final String destinationId;
  final DateTime visitDate;
  final int totalAmount;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final List<BookingParticipant> participants;
  final String status;
  final DateTime? paymentDeadline;

  int get quantity => participants.length;
}
