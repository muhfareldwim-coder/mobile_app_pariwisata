import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/models/trip_management.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/trip_management_service.dart';

void main() {
  test(
    'trip management reads booking details and submits change data',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer mobile-token');

        if (request.method == 'GET') {
          expect(request.url.path, '/api/v1/customer/pesanan/15/kelola');
          return http.Response(
            jsonEncode({
              'data': {
                'booking': {
                  'id': 15,
                  'code': 'JGO-20261016-ABCDE',
                  'visit_date': '2026-10-23',
                  'total_amount': 39000,
                  'status': 'PAID',
                  'leader': {
                    'name': 'Citra Wijaya',
                    'email': 'citra@example.com',
                    'phone': '081234567890',
                  },
                  'participants': [
                    {
                      'name': 'Citra Wijaya',
                      'ticket_type_id': 8,
                      'ticket_type_name': 'Dewasa',
                      'ticket_price': 25000,
                    },
                  ],
                  'destination': {
                    'id': 42,
                    'name': 'Pantai Papuma',
                    'location': 'Jember',
                    'latitude': -8.4,
                    'longitude': 113.5,
                  },
                },
                'ticket_types': [
                  {'id': 8, 'name': 'Dewasa', 'price': 25000},
                ],
                'remaining_slots': 9,
                'pending_change': null,
              },
            }),
            200,
          );
        }

        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/customer/pesanan/15/kelola');
        expect(jsonDecode(request.body), {
          'tanggal_kunjungan': '2026-10-24',
          'anggota': [
            {'nama': 'Sari Wijaya', 'id_jenis_tiket': 8},
          ],
        });
        return http.Response(
          jsonEncode({
            'data': {'id': 31, 'status': 'PENDING', 'amount': 25000},
          }),
          201,
        );
      });
      final service = TripManagementService(
        api: ApiService(baseUrl: 'https://example.test/api/v1', client: client),
        tokenProvider: () => 'mobile-token',
      );

      final trip = await service.getTrip('15');
      final change = await service.createChange(
        bookingId: trip.booking.id,
        visitDate: DateTime(2026, 10, 24),
        members: const [TripMemberDraft(name: 'Sari Wijaya', ticketTypeId: 8)],
      );

      expect(requests, hasLength(2));
      expect(trip.booking.code, 'JGO-20261016-ABCDE');
      expect(trip.booking.participants.single.name, 'Citra Wijaya');
      expect(trip.destination.name, 'Pantai Papuma');
      expect(trip.ticketTypes.single.price, 25000);
      expect(trip.remainingSlots, 9);
      expect(change.id, '31');
      expect(change.amount, 25000);
    },
  );
}
