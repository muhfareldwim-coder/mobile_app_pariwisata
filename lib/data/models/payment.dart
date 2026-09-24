class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.status = 'pending',
  });

  final String id;
  final String bookingId;
  final int amount;
  final String status;
}