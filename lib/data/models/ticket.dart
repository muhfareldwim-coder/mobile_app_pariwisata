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
    this.bookingStatus = 'PAID',
    this.paymentStatus = 'PAID',
    this.paymentDeadline,
    this.destinationLocation = '',
    this.hasIssuedTicket = true,
    this.hasActiveTicket = false,
    this.hasUsedTicket = false,
    this.hasExpiredTicket = false,
    this.isReviewed = false,
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
  final String bookingStatus;
  final String paymentStatus;
  final DateTime? paymentDeadline;
  final String destinationLocation;
  final bool hasIssuedTicket;
  final bool hasActiveTicket;
  final bool hasUsedTicket;
  final bool hasExpiredTicket;
  final bool isReviewed;

  int get quantity => adultCount + childCount;
  bool get canOpenEticket =>
      hasIssuedTicket &&
      (bookingStatus == 'PAID' || paymentMethod.toUpperCase() == 'CASH');
  bool get canPay => bookingStatus == 'PENDING' && status != 'expired';

  Ticket copyWith({
    String? status,
    bool? hasActiveTicket,
    bool? hasUsedTicket,
    bool? hasExpiredTicket,
    bool? isReviewed,
  }) => Ticket(
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
    bookingStatus: bookingStatus,
    paymentStatus: paymentStatus,
    paymentDeadline: paymentDeadline,
    destinationLocation: destinationLocation,
    hasIssuedTicket: hasIssuedTicket,
    hasActiveTicket: hasActiveTicket ?? this.hasActiveTicket,
    hasUsedTicket: hasUsedTicket ?? this.hasUsedTicket,
    hasExpiredTicket: hasExpiredTicket ?? this.hasExpiredTicket,
    isReviewed: isReviewed ?? this.isReviewed,
  );
}
