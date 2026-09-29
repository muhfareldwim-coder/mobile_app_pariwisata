class Ticket {
  const Ticket({
    required this.id,
    required this.bookingId,
    required this.destinationName,
    required this.visitDate,
    required this.adultCount,
    required this.childCount,
    required this.leaderName,
    required this.leaderEmail,
    required this.leaderPhone,
    required this.memberNames,
    this.location = 'Jember',
    this.imageUrl,
    this.unitPrice = 0,
    this.status = 'valid',
  });

  final String id;
  final String bookingId;
  final String destinationName;
  final DateTime visitDate;
  final int adultCount;
  final int childCount;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final List<String> memberNames;
  final String location;
  final String? imageUrl;
  final int unitPrice;
  final String status;

  int get quantity => adultCount + childCount;
  int get totalPrice => unitPrice * quantity;
}