class Ticket {
  const Ticket({
    required this.id,
    required this.bookingId,
    this.bookingRecordId = '',
    this.destinationId = '',
    required this.destinationName,
    this.destinationImageUrl,
    required this.visitDate,
    required this.adultCount,
    required this.childCount,
    required this.leaderName,
    required this.leaderEmail,
    required this.leaderPhone,
    required this.memberNames,
    this.amountPaid = 0,
    this.paymentMethod = 'QRIS',
    this.status = 'valid',
    this.qrCodePayload,
  });

  final String id;
  final String bookingId;
  final String bookingRecordId;
  final String destinationId;
  final String destinationName;
  final String? destinationImageUrl;
  final DateTime visitDate;
  final int adultCount;
  final int childCount;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final List<String> memberNames;
  final int amountPaid;
  final String paymentMethod;
  final String status;
  final String? qrCodePayload;

  int get quantity => adultCount + childCount;

  Ticket copyWith({String? status}) => Ticket(
    id: id,
    bookingId: bookingId,
    bookingRecordId: bookingRecordId,
    destinationId: destinationId,
    destinationName: destinationName,
    destinationImageUrl: destinationImageUrl,
    visitDate: visitDate,
    adultCount: adultCount,
    childCount: childCount,
    leaderName: leaderName,
    leaderEmail: leaderEmail,
    leaderPhone: leaderPhone,
    memberNames: memberNames,
    amountPaid: amountPaid,
    paymentMethod: paymentMethod,
    status: status ?? this.status,
    qrCodePayload: qrCodePayload,
  );
}
