import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/models/booking.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/booking_service.dart';
import 'package:mobile_pariwisata/data/services/payment_service.dart';

void main() {
  test(
    'booking and payment services use Laravel and Midtrans responses',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer mobile-token');

        if (request.url.path == '/api/v1/customer/destinasi/42/pemesanan') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['tanggal_kunjungan'], '2026-10-18');
          expect(body['ketua_nama'], 'Citra Wijaya');
          expect(body['peserta'], [
            {'nama': 'Citra Wijaya', 'id_jenis_tiket': 8},
            {'nama': 'Siti Wijaya', 'id_jenis_tiket': 9},
          ]);
          return http.Response(
            jsonEncode({
              'data': {
                'id': 15,
                'kode_booking': 'JGO-20261011-ABCDE',
                'tanggal_kunjungan': '2026-10-18',
                'status': 'PENDING',
                'total_harga': 39000,
                'batas_waktu_pembayaran': '2026-10-11T18:20:00+07:00',
              },
            }),
            201,
          );
        }

        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'data': {
                'status': 'PENDING',
                'order_id': 'JGO-JGO-20261011-ABCDE',
                'qris_url': 'https://api.sandbox.midtrans.com/v2/qris/qr-code',
                'qris_image_url': 'http://localhost/api/v1/customer/pesanan/15/pembayaran/qr-image',
                'nominal': 39000,
              },
            }),
            201,
          );
        }

        return http.Response(
          jsonEncode({
            'data': {
              'status': 'PAID',
              'order_id': 'JGO-JGO-20261011-ABCDE',
              'qris_url': 'https://api.sandbox.midtrans.com/v2/qris/qr-code',
              'qris_image_url': 'http://localhost/api/v1/customer/pesanan/15/pembayaran/qr-image',
              'nominal': 39000,
            },
          }),
          200,
        );
      });
      final api = ApiService(
        baseUrl: 'http://localhost/api/v1',
        client: client,
      );

      final booking =
          await BookingService(
            api: api,
            tokenProvider: () => 'mobile-token',
          ).createBooking(
            destinationId: '42',
            visitDate: DateTime(2026, 10, 18),
            leaderName: 'Citra Wijaya',
            leaderEmail: 'citra@gmail.com',
            leaderPhone: '081234567890',
            participants: const [
              BookingParticipant(
                name: 'Citra Wijaya',
                ticketTypeId: 8,
                ticketTypeName: 'Dewasa',
                ticketPrice: 25000,
              ),
              BookingParticipant(
                name: 'Siti Wijaya',
                ticketTypeId: 9,
                ticketTypeName: 'Anak',
                ticketPrice: 14000,
              ),
            ],
          );

      final paymentService = PaymentService(
        api: api,
        tokenProvider: () => 'mobile-token',
      );
      final payment = await paymentService.createPayment(booking.id);
      final settledPayment = await paymentService.getPaymentStatus(booking.id);

      expect(requests, hasLength(3));
      expect(booking.id, '15');
      expect(booking.code, 'JGO-20261011-ABCDE');
      expect(booking.totalAmount, 39000);
      expect(booking.participants.length, 2);
      expect(payment.bookingId, booking.id);
      expect(payment.orderId, 'JGO-JGO-20261011-ABCDE');
      expect(payment.amount, 39000);
      expect(payment.qrCodeUrl?.host, 'localhost');
      expect(
        payment.qrCodeSourceUrl?.toString(),
        'https://api.sandbox.midtrans.com/v2/qris/qr-code',
      );
      expect(
        payment.qrCodeUrl?.path,
        '/api/v1/customer/pesanan/15/pembayaran/qr-image',
      );
      expect(payment.checkoutUrl, isNull);
      expect(payment.snapToken, isNull);
      expect(settledPayment.isPaid, isTrue);
    },
  );

  test('additional payments use the booking change QR endpoints', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Bearer mobile-token');
      expect(
        request.url.path,
        '/api/v1/customer/pesanan/15/perubahan/31/pembayaran',
      );
      return http.Response(
        jsonEncode({
          'data': {
            'status': request.method == 'POST' ? 'PENDING' : 'PAID',
            'order_id': 'JGO-CHANGE-31',
            'qris_url': 'https://api.sandbox.midtrans.com/v2/qris/qr-code',
            'qris_image_url': 'https://example.test/api/v1/customer/pesanan/15/perubahan/31/pembayaran/qr-image',
            'qris_expires_at': '2026-10-16T16:00:00+07:00',
            'nominal': 25000,
          },
        }),
        request.method == 'POST' ? 201 : 200,
      );
    });
    final service = PaymentService(
      api: ApiService(baseUrl: 'https://example.test/api/v1', client: client),
      tokenProvider: () => 'mobile-token',
    );

    final payment = await service.createAdditionalPayment('15', '31');
    final paidPayment = await service.getAdditionalPaymentStatus('15', '31');

    expect(requests, hasLength(2));
    expect(payment.amount, 25000);
    expect(
      payment.qrCodeUrl?.path,
      contains('/perubahan/31/pembayaran/qr-image'),
    );
    expect(
      payment.qrCodeSourceUrl?.toString(),
      'https://api.sandbox.midtrans.com/v2/qris/qr-code',
    );
    expect(payment.expiresAt, DateTime.parse('2026-10-16T16:00:00+07:00'));
    expect(paidPayment.isPaid, isTrue);
  });

  test(
    'booking service rejects nonnumeric destination IDs before sending',
    () async {
      final service = BookingService(
        api: ApiService(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );

      await expectLater(
        service.createBooking(
          destinationId: 'sample-destination',
          visitDate: DateTime(2026, 10, 18),
          leaderName: 'Citra Wijaya',
          leaderEmail: 'citra@gmail.com',
          leaderPhone: '081234567890',
          participants: const [],
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'booking quota uses the website quota endpoint and selected date',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/customer/destinasi/42/kuota');
        expect(request.url.queryParameters['date'], '2026-10-18');
        expect(request.headers['Authorization'], isNotEmpty);
        return http.Response(
          jsonEncode({'enabled': true, 'remaining': 12}),
          200,
        );
      });
      final service = BookingService(
        api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
        tokenProvider: () => 'mobile-token',
      );

      final availability = await service.getQuotaAvailability(
        destinationId: '42',
        visitDate: DateTime(2026, 10, 18),
      );

      expect(availability.enabled, isTrue);
      expect(availability.remaining, 12);
    },
  );
}
