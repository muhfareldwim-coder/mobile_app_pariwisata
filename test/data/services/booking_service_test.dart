import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/booking_service.dart';

void main() {
  test(
    'booking service cancels a pending booking through the website API',
    () async {
      final service = BookingService(
        api: ApiService(
          baseUrl: 'https://example.test/api/v1',
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/api/v1/customer/pesanan/15/batal');
            expect(request.headers['Authorization'], 'Bearer mobile-token');
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

      await service.cancelBooking('15');
    },
  );
}
