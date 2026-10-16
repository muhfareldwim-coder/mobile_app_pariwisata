import '../models/payment.dart';
import 'api_service.dart';
import 'auth_service.dart';

class PaymentService {
  PaymentService({ApiService? api, String? Function()? tokenProvider})
    : _api = api ?? ApiService(),
      _tokenProvider = tokenProvider ?? (() => AuthService.accessToken);

  final ApiService _api;
  final String? Function() _tokenProvider;

  Map<String, String> get qrCodeImageHeaders {
    final token = _tokenProvider();
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<Payment> createPayment(String bookingId) async {
    final response = await _api.post(
      '/customer/pesanan/$bookingId/pembayaran',
      token: _tokenProvider(),
    );
    return _paymentFromResponse(response, bookingId);
  }

  Future<Payment> getPaymentStatus(String bookingId) async {
    final response = await _api.get(
      '/customer/pesanan/$bookingId/pembayaran',
      token: _tokenProvider(),
    );
    return _paymentFromResponse(response, bookingId);
  }

  Future<Payment> createAdditionalPayment(
    String bookingId,
    String changeId,
  ) async {
    final response = await _api.post(
      '/customer/pesanan/$bookingId/perubahan/$changeId/pembayaran',
      token: _tokenProvider(),
    );
    return _paymentFromResponse(response, bookingId);
  }

  Future<Payment> getAdditionalPaymentStatus(
    String bookingId,
    String changeId,
  ) async {
    final response = await _api.get(
      '/customer/pesanan/$bookingId/perubahan/$changeId/pembayaran',
      token: _tokenProvider(),
    );
    return _paymentFromResponse(response, bookingId);
  }

  Payment _paymentFromResponse(
    Map<String, dynamic> response,
    String bookingId,
  ) {
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['status'] is! String) {
      throw const FormatException(
        'Respons pembayaran dari server tidak valid.',
      );
    }

    final checkoutUrlValue = data['checkout_url'];
    final checkoutUrl = checkoutUrlValue is String
        ? Uri.tryParse(checkoutUrlValue)
        : null;
    if (checkoutUrlValue is String &&
        (checkoutUrl == null || !checkoutUrl.hasScheme)) {
      throw const FormatException('Tautan pembayaran dari server tidak valid.');
    }

    final qrCodeUrlValue = data['qris_image_url'];
    final qrCodeUrl = qrCodeUrlValue is String
        ? Uri.tryParse(qrCodeUrlValue)
        : null;
    if (qrCodeUrlValue is String &&
        (qrCodeUrl == null ||
            !qrCodeUrl.hasScheme ||
            !{'http', 'https'}.contains(qrCodeUrl.scheme))) {
      throw const FormatException('Kode pembayaran dari server tidak valid.');
    }

    final qrCodeSourceUrlValue = data['qris_url'];
    final qrCodeSourceUrl = qrCodeSourceUrlValue is String
        ? Uri.tryParse(qrCodeSourceUrlValue)
        : null;
    if (qrCodeSourceUrlValue is String &&
        (qrCodeSourceUrl == null ||
            !qrCodeSourceUrl.hasScheme ||
            !{'http', 'https'}.contains(qrCodeSourceUrl.scheme))) {
      throw const FormatException(
        'Tautan kode pembayaran dari server tidak valid.',
      );
    }

    return Payment(
      orderId: data['order_id'] is String ? data['order_id'] as String : null,
      bookingId: bookingId,
      amount: data['nominal'] is num ? (data['nominal'] as num).round() : null,
      status: data['status'] as String,
      checkoutUrl: checkoutUrl,
      snapToken: data['snap_token'] is String
          ? data['snap_token'] as String
          : null,
      qrCodeUrl: qrCodeUrl,
      qrCodeSourceUrl: qrCodeSourceUrl,
      expiresAt: data['qris_expires_at'] is String
          ? DateTime.tryParse(data['qris_expires_at'] as String)
          : null,
    );
  }
}
