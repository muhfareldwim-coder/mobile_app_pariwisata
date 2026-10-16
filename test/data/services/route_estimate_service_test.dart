import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_pariwisata/data/services/route_estimate_service.dart';

void main() {
  test(
    'uses OSRM driving distance, adjusted ETA and actual road geometry',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'router.project-osrm.org');
        expect(request.url.queryParameters['overview'], 'full');
        expect(request.url.queryParameters['geometries'], 'geojson');
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 12000,
                'duration': 1200,
                'geometry': {
                  'coordinates': [
                    [113.7, -8.17],
                    [113.65, -8.2],
                    [113.6, -8.3],
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final service = RouteEstimateService(client: client);

      final estimate = await service.estimate(
        origin: const LatLng(-8.17, 113.7),
        destination: const LatLng(-8.3, 113.6),
      );

      expect(estimate.distanceMeters, 12000);
      expect(estimate.durationSeconds, 1620);
      expect(estimate.routePoints, [
        const LatLng(-8.17, 113.7),
        const LatLng(-8.2, 113.65),
        const LatLng(-8.3, 113.6),
      ]);
    },
  );
}
