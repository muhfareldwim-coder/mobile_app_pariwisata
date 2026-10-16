import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/models/booking.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/payment_service.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/payment_page.dart';

void main() {
  testWidgets('payment page follows website summary without naming a method', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final paymentService = PaymentService(
      api: ApiService(
        baseUrl: 'https://example.test/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/customer/pesanan/15/pembayaran');
          return http.Response(
            jsonEncode({
              'data': {
                'status': 'PENDING',
                'order_id': 'JGO-ORDER-15',
                'qris_url': 'https://api.sandbox.midtrans.com/v2/qris/qr-code',
                'qris_image_url': 'https://example.test/api/v1/customer/pesanan/15/pembayaran/qr-image',
                'qris_expires_at': '2026-10-16T16:00:00+07:00',
                'nominal': 39000,
              },
            }),
            201,
          );
        }),
      ),
      tokenProvider: () => 'mobile-token',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(
          paymentService: paymentService,
          destination: const Destination(
            id: '42',
            name: 'Pantai Papuma',
            location: 'Jember',
            latitude: -8.4,
            longitude: 113.5,
            routeDistanceKm: 0,
          ),
          booking: Booking(
            id: '15',
            code: 'JGO-20261016-ABCDE',
            destinationId: '42',
            visitDate: DateTime(2026, 10, 23),
            totalAmount: 39000,
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
            status: 'PENDING',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ringkasan pesanan'), findsOneWidget);
    expect(find.text('Tanggal kunjungan'), findsOneWidget);
    expect(find.text('Jumat, 23 Oktober 2026'), findsOneWidget);
    expect(find.text('Citra Wijaya (Ketua)'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Pindai kode pembayaran yang tampil di atas.'),
      find.byType(ListView),
      const Offset(0, -350),
    );
    await tester.pump();
    expect(find.text('Selesaikan pembayaran'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/logo-qris-transparent.png')),
      findsOneWidget,
    );
    expect(
      find.text('Pindai kode pembayaran yang tampil di atas.'),
      findsOneWidget,
    );
    final qrImage = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
    );
    final networkImage = qrImage.image as NetworkImage;
    expect(
      networkImage.url,
      'https://example.test/api/v1/customer/pesanan/15/pembayaran/qr-image',
    );
    expect(networkImage.headers?['Authorization'], 'Bearer mobile-token');
    await tester.dragUntilVisible(
      find.text('Salin tautan Midtrans'),
      find.byType(ListView),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.text('Salin tautan Midtrans'), findsOneWidget);

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    await tester.tap(find.text('Salin tautan Midtrans'));
    await tester.pumpAndSettle();
    expect(copiedText, 'https://api.sandbox.midtrans.com/v2/qris/qr-code');
    expect(find.text('Tautan Midtrans berhasil disalin.'), findsOneWidget);
    expect(find.textContaining('QRIS'), findsNothing);
    expect(find.text('Salin tautan Midtrans'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
