class Payment {
  const Payment({
    required this.orderId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.checkoutUrl,
    required this.snapToken,
    required this.qrCodeUrl,
    this.qrCodeSourceUrl,
    this.expiresAt,
  });

  final String? orderId;
  final String bookingId;
  final int? amount;
  final String status;
  final Uri? checkoutUrl;
  final String? snapToken;
  final Uri? qrCodeUrl;
  final Uri? qrCodeSourceUrl;
  final DateTime? expiresAt;

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPending => status.toUpperCase() == 'PENDING';
}
