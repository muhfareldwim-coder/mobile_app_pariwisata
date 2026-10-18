import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/destination_service.dart';

void main() {
  test('destination detail maps backend location and content fields', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/destinasi/42');
      return http.Response(
        jsonEncode({
          'data': {
            'id': 42,
            'nama': 'Taman Botani',
            'foto_utama': '/storage/destinations/main/botani.jpg',
            'deskripsi': 'Deskripsi yang dikelola website.',
            'kategori': 'BUATAN',
            'alamat': 'Jl. Mujahir, Sukorambi, Jember',
            'latitude': -8.126,
            'longitude': 113.676,
            'jam_operasional': '08.00 - 16.00',
            'rating_rata_rata': 4.5,
            'ulasan_count': 2,
            'fasilitas': [
              {'nama': 'Parkir'},
            ],
            'galeri': [
              {
                'url': 'https://example.com/botani-gallery.jpg',
                'keterangan': 'Taman',
              },
            ],
            'jenis_tiket': [
              {'id': 8, 'nama': 'Dewasa', 'harga': 25000},
              {'id': 9, 'nama': 'Anak', 'harga': 15000},
            ],
            'ulasan': [
              {'nama_customer': 'Siti', 'rating': 5, 'ulasan': 'Bagus.'},
            ],
          },
        }),
        200,
      );
    });
    final service = DestinationService(
      api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
    );

    final destination = await service.getDestination('42');

    expect(destination.name, 'Taman Botani');
    expect(destination.location, 'Jl. Mujahir, Sukorambi, Jember');
    expect(destination.latitude, -8.126);
    expect(destination.longitude, 113.676);
    expect(destination.distanceKm, greaterThan(0));
    expect(destination.openingHours, '08.00 - 16.00');
    expect(destination.facilities, ['Parkir']);
    expect(destination.gallery.single.caption, 'Taman');
    expect(
      destination.gallery.single.url,
      'https://example.com/botani-gallery.jpg',
    );
    expect(destination.ticketTypes.map((ticket) => ticket.price), [
      25000,
      15000,
    ]);
    expect(destination.ticketTypes.map((ticket) => ticket.id), [8, 9]);
    expect(destination.ticketPrice, 15000);
    expect(destination.rating, 4.5);
    expect(destination.reviewCount, '2');
    expect(destination.reviews.single.review, 'Bagus.');
    expect(
      destination.imageUrl,
      'http://localhost/storage/destinations/main/botani.jpg',
    );
  });

  test('destination list calculates distances from the given origin', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/destinasi');
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 42,
              'nama': 'Taman Botani',
              'latitude': -8.126,
              'longitude': 113.676,
            },
            {
              'id': 43,
              'nama': 'Pantai Papuma',
              'latitude': -8.431,
              'longitude': 113.561,
            },
          ],
        }),
        200,
      );
    });
    final service = DestinationService(
      api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
    );
    const origin = LatLng(-8.2, 113.7);

    final destinations = await service.getDestinations(origin: origin);

    expect(destinations, hasLength(2));
    expect(
      destinations[0].distanceKm,
      closeTo(
        const Distance().as(
              LengthUnit.Kilometer,
              origin,
              const LatLng(-8.126, 113.676),
            ) *
            1.25,
        0.001,
      ),
    );
    expect(destinations[0].distanceKm, greaterThan(0));
    expect(destinations[1].distanceKm, greaterThan(0));
    expect(destinations[0].distanceKm, isNot(destinations[1].distanceKm));
  });

  test('map destinations skip entries without coordinates', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/destinasi');
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 42,
              'nama': 'Taman Botani',
              'latitude': -8.126,
              'longitude': 113.676,
            },
            {
              'id': 43,
              'nama': 'Destinasi tanpa koordinat',
              'latitude': null,
              'longitude': null,
            },
          ],
        }),
        200,
      );
    });
    final service = DestinationService(
      api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
    );

    final destinations = await service.getMapDestinations();

    expect(destinations, hasLength(1));
    expect(destinations.single.name, 'Taman Botani');
  });

  test(
    'destination list loads every page for database category counts',
    () async {
      final client = MockClient((request) async {
        final page = request.url.queryParameters['page'] ?? '1';
        if (page == '1') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 42,
                  'nama': 'Taman Botani',
                  'kategori': 'BUATAN',
                  'latitude': -8.126,
                  'longitude': 113.676,
                },
              ],
              'meta': {'last_page': 2, 'total': 2},
            }),
            200,
          );
        }

        expect(page, '2');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 43,
                'nama': 'Pantai Papuma',
                'kategori': 'BAHARI',
                'latitude': -8.431,
                'longitude': 113.561,
              },
            ],
            'meta': {'last_page': 2, 'total': 2},
          }),
          200,
        );
      });
      final service = DestinationService(
        api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
      );

      final destinations = await service.getDestinations();

      expect(destinations, hasLength(2));
      expect(
        destinations.where((destination) => destination.category == 'BUATAN'),
        hasLength(1),
      );
      expect(
        destinations.where((destination) => destination.category == 'BAHARI'),
        hasLength(1),
      );
    },
  );

  test(
    'destination image paths without a leading slash resolve from server root',
    () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 42,
              'nama': 'Taman Botani',
              'foto_utama': 'storage/destinations/main/botani.jpg',
              'latitude': -8.126,
              'longitude': 113.676,
            },
          }),
          200,
        );
      });
      final service = DestinationService(
        api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
      );

      final destination = await service.getDestination('42');

      expect(
        destination.imageUrl,
        'http://localhost/storage/destinations/main/botani.jpg',
      );
    },
  );

  test('root-relative gallery paths use the configured API server', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': {
            'id': 42,
            'nama': 'Taman Botani',
            'latitude': -8.126,
            'longitude': 113.676,
            'galeri': [
              {'url': '/storage/destinations/botani-gallery.jpg'},
            ],
          },
        }),
        200,
      );
    });
    final service = DestinationService(
      api: ApiService(baseUrl: 'http://10.0.2.2:8000/api/v1', client: client),
    );

    final destination = await service.getDestination('42');

    expect(
      destination.gallery.single.url,
      'http://10.0.2.2:8000/storage/destinations/botani-gallery.jpg',
    );
  });
}
