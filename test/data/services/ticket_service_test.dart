import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';

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
                    'pembayaran': {'nominal': 25000, 'metode': 'QRIS'},
                    'tiket': [
                      {
                        'id': 77,
                        'kode_qr': 'encrypted-server-qr-payload',
                        'status': 'ACTIVE',
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
      expect(TicketService.qrPayload(ticket), 'encrypted-server-qr-payload');
    },
  );
}
