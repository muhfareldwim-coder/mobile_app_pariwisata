import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/models/ticket.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/data/models/user.dart';

void main() {
  tearDown(() {
    TicketService.tickets.clear();
    TicketService.revision.value++;
  });

  test(
    'ticket service loads issued QR payloads from customer orders',
    () async {
      final service = TicketService(
        api: ApiService(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/customer/pesanan');
            expect(request.url.queryParameters['per_page'], '50');
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 15,
                    'kode_booking': 'JGO-20261011-ABCDE',
                    'tanggal_kunjungan': '2026-10-18',
                    'status': 'PAID',
                    'total_harga': 125000,
                    'ketua': {
                      'nama': 'Citra Wijaya',
                      'email': 'citra@gmail.com',
                      'no_hp': '081234567890',
                    },
                    'anggota': [
                      {'nama': 'Siti Wijaya', 'id_jenis_tiket': 9},
                    ],
                    'destinasi': {
                      'id': 42,
                      'nama': 'Pantai Papuma',
                      'foto_utama': '/storage/destinations/main/papuma.jpg',
                      'alamat': 'Jember',
                    },
                    'customer': {
                      'nama': 'Citra Wijaya',
                      'email': 'citra@gmail.com',
                      'no_hp': '081234567890',
                    },
                    'detail': [
                      {
                        'jumlah': 1,
                        'jenis_tiket': {'nama': 'Dewasa'},
                      },
                      {
                        'jumlah': 1,
                        'jenis_tiket': {'nama': 'Anak-anak'},
                      },
                    ],
                    'pembayaran': {
                      'status': 'PAID',
                      'nominal': 125000,
                      'metode': 'QRIS',
                    },
                    'tiket': [
                      {
                        'id': 77,
                        'kode_qr': 'encrypted-server-qr-payload',
                        'status': 'ACTIVE',
                        'reviewed': false,
                      },
                    ],
                  },
                ],
              }),
              200,
            );
          }),
        ),
      );

      await service.refreshFromServer();

      final ticket = TicketService.tickets.single;
      expect(ticket.id, '77');
      expect(ticket.bookingId, 'JGO-20261011-ABCDE');
      expect(ticket.destinationName, 'Pantai Papuma');
      expect(
        ticket.destinationImageUrl,
        'http://localhost/storage/destinations/main/papuma.jpg',
      );
      expect(ticket.adultCount, 1);
      expect(ticket.childCount, 1);
      expect(ticket.memberNames, ['Siti Wijaya']);
      expect(ticket.amountPaid, 125000);
      expect(ticket.status, 'valid');
      expect(ticket.canOpenEticket, isTrue);
      final qrUri = Uri.parse(TicketService.qrPayload(ticket));
      expect(qrUri.path, '/tiket/scan');
      expect(qrUri.queryParameters['kode_qr'], 'encrypted-server-qr-payload');
    },
  );

  test(
    'ticket service includes unpaid bookings without issued tickets',
    () async {
      final service = TicketService(
        api: ApiService(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 16,
                    'kode_booking': 'JGO-20261011-PENDING',
                    'tanggal_kunjungan': '2026-10-20',
                    'status': 'PENDING',
                    'total_harga': 50000,
                    'ketua': {
                      'nama': 'Citra Wijaya',
                      'email': 'citra@gmail.com',
                      'no_hp': '081234567890',
                    },
                    'anggota': [],
                    'destinasi': {'id': 42, 'nama': 'Pantai Papuma'},
                    'detail': [
                      {
                        'jumlah': 2,
                        'jenis_tiket': {'nama': 'Dewasa'},
                      },
                    ],
                    'pembayaran': {'status': 'PENDING', 'metode': null},
                    'tiket': [],
                  },
                ],
              }),
              200,
            );
          }),
        ),
      );

      await service.refreshFromServer();

      final booking = TicketService.tickets.single;
      expect(booking.status, 'pending');
      expect(booking.hasIssuedTicket, isFalse);
      expect(booking.canPay, isTrue);
      expect(booking.canOpenEticket, isFalse);
      expect(booking.quantity, 2);
    },
  );

  test('ticket service follows order pagination until the last page', () async {
    final requestedPages = <String?>[];
    final service = TicketService(
      api: ApiService(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient((request) async {
          requestedPages.add(request.url.queryParameters['page']);
          return http.Response(
            jsonEncode({
              'data': [],
              'meta': {
                'last_page': 2,
                'current_page': int.parse(request.url.queryParameters['page']!),
              },
            }),
            200,
          );
        }),
      ),
    );

    await service.refreshFromServer();

    expect(requestedPages, ['1', '2']);
    expect(TicketService.tickets, isEmpty);
  });

  test('ticket service preserves active and history statuses in mixed bookings', () async {
    final service = TicketService(
      api: ApiService(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 17,
                  'kode_booking': 'JGO-MIXED',
                  'tanggal_kunjungan': '2026-10-20',
                  'status': 'PAID',
                  'total_harga': 100000,
                  'destinasi': {'id': 42, 'nama': 'Pantai Papuma'},
                  'tiket': [
                    {'id': 81, 'kode_qr': 'active-qr', 'status': 'ACTIVE'},
                    {'id': 82, 'kode_qr': 'used-qr', 'status': 'USED'},
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      ),
    );

    await service.refreshFromServer();

    final booking = TicketService.tickets.single;
    expect(booking.status, 'partial');
    expect(booking.hasActiveTicket, isTrue);
    expect(booking.hasUsedTicket, isTrue);
    expect(booking.hasExpiredTicket, isFalse);
  });

  test(
    'stale account response cannot replace the current ticket list',
    () async {
      AuthService.currentUser = User.sample;
      addTearDown(AuthService.logout);
      final existingTicket = Ticket(
        id: 'current-ticket',
        bookingId: 'CURRENT-BOOKING',
        destinationName: 'Pantai Papuma',
        visitDate: DateTime(2026, 10, 18),
        adultCount: 1,
        childCount: 0,
        leaderName: User.sample.name,
        leaderEmail: User.sample.email,
        leaderPhone: User.sample.phone,
        memberNames: const [],
      );
      TicketService.tickets.add(existingTicket);
      final service = TicketService(
        api: ApiService(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient(
            (_) async => http.Response(jsonEncode({'data': []}), 200),
          ),
        ),
      );

      await service.refreshFromServer(expectedCustomerId: 'previous-customer');
      expect(TicketService.tickets, [existingTicket]);
      expect(TicketService.tickets, [existingTicket]);
    },
  );
}
