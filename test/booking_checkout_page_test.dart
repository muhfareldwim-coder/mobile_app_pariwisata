import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/models/booking.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/booking_service.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/checkout_page.dart';

void main() {
  testWidgets('checkout confirms and submits pending booking cancellation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    String? requestedPath;
    final bookingService = BookingService(
      api: ApiService(
        baseUrl: 'https://example.test/api/v1',
        client: MockClient((request) async {
          requestedPath = request.url.path;
          return http.Response(
            jsonEncode({
              'message': 'Pesanan berhasil dibatalkan.',
              'data': {'id': 15, 'status': 'CANCELLED'},
            }),
            200,
          );
        }),
      ),
      tokenProvider: () => 'mobile-token',
    );
    var cancellationResult = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              cancellationResult =
                  await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => CheckoutPage(
                        booking: Booking(
                          id: '15',
                          code: 'JGO-BOOKING-15',
                          destinationId: '42',
                          visitDate: DateTime(2026, 11, 12),
                          totalAmount: 25000,
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
                          ],
                          status: 'PENDING',
                        ),
                        destination: const Destination(
                          id: '42',
                          name: 'Pantai Papuma',
                          location: 'Jember',
                          latitude: -8.4,
                          longitude: 113.5,
                          routeDistanceKm: 0,
                        ),
                        canCancelBooking: true,
                        bookingService: bookingService,
                      ),
                    ),
                  ) ??
                  false;
            },
            child: const Text('Buka checkout'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi dan pembayaran'), findsOneWidget);
    expect(find.text('Batalkan pesanan'), findsOneWidget);

    await tester.tap(find.text('Batalkan pesanan'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Pesanan ini akan dibatalkan dan tidak dapat dilanjutkan kembali.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Ya, batalkan pesanan'));
    await tester.pumpAndSettle();

    expect(requestedPath, '/api/v1/customer/pesanan/15/batal');
    expect(cancellationResult, isTrue);
    expect(tester.takeException(), isNull);
  });
}
