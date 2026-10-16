import 'package:latlong2/latlong.dart';

import '../models/destination.dart';
import 'api_service.dart';
import 'device_location_service.dart';

class DestinationService {
  DestinationService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<Destination>> getDestinations({LatLng? origin}) async {
    final firstPage = await _api.get(
      '/destinasi',
      queryParameters: const {'per_page': '50'},
    );

    final destinations = _destinationsFromResponse(firstPage, origin: origin);
    final metadata = firstPage['meta'];
    if (metadata == null) {
      return destinations;
    }
    if (metadata is! Map<String, dynamic> || metadata['last_page'] is! num) {
      throw const FormatException(
        'Informasi halaman destinasi dari server tidak valid.',
      );
    }

    final lastPage = (metadata['last_page'] as num).toInt();
    if (lastPage < 1) {
      throw const FormatException(
        'Informasi halaman destinasi dari server tidak valid.',
      );
    }

    for (var page = 2; page <= lastPage; page++) {
      final response = await _api.get(
        '/destinasi',
        queryParameters: {'per_page': '50', 'page': '$page'},
      );
      destinations.addAll(_destinationsFromResponse(response, origin: origin));
    }

    return destinations;
  }

  List<Destination> _destinationsFromResponse(
    Map<String, dynamic> response, {
    LatLng? origin,
  }) {
    final data = response['data'];
    if (data is! List<dynamic>) {
      throw const FormatException('Daftar destinasi dari server tidak valid.');
    }
    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Data destinasi dari server tidak valid.');
      }
      return _destinationFromJson(item, origin: origin);
    }).toList();
  }

  Future<Destination> getDestination(String id) async {
    final response = await _api.get('/destinasi/$id');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Detail destinasi dari server tidak valid.');
    }
    return _destinationFromJson(data);
  }

  Destination _destinationFromJson(
    Map<String, dynamic> json, {
    LatLng? origin,
  }) {
    final id = json['id'];
    final name = json['nama'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (id == null ||
        name is! String ||
        latitude is! num ||
        longitude is! num) {
      throw const FormatException(
        'Informasi destinasi dari server tidak lengkap.',
      );
    }

    final facilities = json['fasilitas'];
    final facilityNames = facilities is List<dynamic>
        ? facilities
              .whereType<Map<String, dynamic>>()
              .map((facility) => facility['nama'])
              .whereType<String>()
              .toList()
        : <String>[];
    final galleryData = json['galeri'];
    final gallery = galleryData is List<dynamic>
        ? galleryData
              .whereType<Map<String, dynamic>>()
              .where((image) => image['url'] is String)
              .map(
                (image) => DestinationGallery(
                  url: _api.resolveUrl(image['url'] as String),
                  caption: image['keterangan'] is String
                      ? image['keterangan'] as String
                      : null,
                ),
              )
              .toList()
        : <DestinationGallery>[];
    final ticketData = json['jenis_tiket'];
    final ticketTypes = ticketData is List<dynamic>
        ? ticketData
              .whereType<Map<String, dynamic>>()
              .where(
                (ticket) =>
                    ticket['id'] is num &&
                    ticket['nama'] is String &&
                    ticket['harga'] is num,
              )
              .map(
                (ticket) => DestinationTicketType(
                  id: (ticket['id'] as num).toInt(),
                  name: ticket['nama'] as String,
                  price: (ticket['harga'] as num).round(),
                ),
              )
              .toList()
        : <DestinationTicketType>[];
    final reviewData = json['ulasan'];
    final reviews = reviewData is List<dynamic>
        ? reviewData
              .whereType<Map<String, dynamic>>()
              .where(
                (review) =>
                    review['ulasan'] is String && review['rating'] is num,
              )
              .map(
                (review) => DestinationReviewEntry(
                  name: review['nama_customer'] is String
                      ? review['nama_customer'] as String
                      : 'Pengunjung',
                  rating: (review['rating'] as num).toInt(),
                  review: review['ulasan'] as String,
                ),
              )
              .toList()
        : <DestinationReviewEntry>[];
    final rating = json['rating_rata_rata'];
    final imageUrl = json['foto_utama'];
    final numberOfReviews = json['ulasan_count'] is num
        ? (json['ulasan_count'] as num).toInt()
        : reviews.length;
    final destinationPoint = LatLng(latitude.toDouble(), longitude.toDouble());
    final distanceKm =
        const Distance().as(
          LengthUnit.Kilometer,
          origin ?? DeviceLocationService.jemberFallback,
          destinationPoint,
        ) *
        1.25;

    return Destination(
      id: id.toString(),
      name: name,
      location: json['alamat'] is String ? json['alamat'] as String : '',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      routeDistanceKm: 0,
      distanceKm: distanceKm,
      description: json['deskripsi'] is String
          ? json['deskripsi'] as String
          : '',
      imageUrl: imageUrl is String && imageUrl.isNotEmpty
          ? _api.resolveUrl(imageUrl)
          : null,
      ticketPrice: ticketTypes.isEmpty
          ? 0
          : ticketTypes
                .map((ticket) => ticket.price)
                .reduce((first, second) => first < second ? first : second),
      category: json['kategori'] is String
          ? (json['kategori'] as String).toUpperCase()
          : 'ALAM',
      rating: rating is num ? rating.toDouble() : 0,
      facilities: facilityNames,
      reviewCount: numberOfReviews.toString(),
      openingHours: json['jam_operasional'] is String
          ? json['jam_operasional'] as String
          : '',
      gallery: gallery,
      ticketTypes: ticketTypes,
      reviews: reviews,
    );
  }
}
