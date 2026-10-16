import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteEstimate {
  const RouteEstimate({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.routePoints,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> routePoints;
}

class RouteEstimateService {
  RouteEstimateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RouteEstimate> estimate({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}',
      const {'overview': 'full', 'geometries': 'geojson'},
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } on Exception {
      rethrow;
    }
    if (response.statusCode != 200) {
      throw const FormatException('Layanan rute sedang tidak tersedia.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['code'] != 'Ok' ||
        decoded['routes'] is! List<dynamic> ||
        (decoded['routes'] as List<dynamic>).isEmpty) {
      throw const FormatException(
        'Rute berkendara tidak ditemukan untuk lokasi ini.',
      );
    }
    final route = (decoded['routes'] as List<dynamic>).first;
    if (route is! Map<String, dynamic> ||
        route['distance'] is! num ||
        route['duration'] is! num ||
        route['geometry'] is! Map<String, dynamic>) {
      throw const FormatException('Data rute dari layanan peta tidak valid.');
    }
    final coordinates =
        (route['geometry'] as Map<String, dynamic>)['coordinates'];
    if (coordinates is! List<dynamic>) {
      throw const FormatException('Garis rute dari layanan peta tidak valid.');
    }

    return RouteEstimate(
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble() * 1.35,
      routePoints: coordinates.map((coordinate) {
        if (coordinate is! List<dynamic> ||
            coordinate.length < 2 ||
            coordinate[0] is! num ||
            coordinate[1] is! num) {
          throw const FormatException(
            'Koordinat garis rute dari layanan peta tidak valid.',
          );
        }
        return LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        );
      }).toList(),
    );
  }
}
