import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/services/destination_service.dart';
import 'package:mobile_pariwisata/data/services/open_street_map_service.dart';
import 'package:mobile_pariwisata/data/services/route_estimate_service.dart';
import 'package:mobile_pariwisata/presentation/pages/map/map_page.dart';

void main() {
  final destinations = [
    _destination(
      id: '1',
      name: 'Pantai Papuma',
      category: 'BAHARI',
      latitude: -8.431,
      longitude: 113.561,
    ),
    _destination(
      id: '2',
      name: 'Taman Botani',
      category: 'BUATAN',
      latitude: -8.126,
      longitude: 113.676,
    ),
    _destination(
      id: '3',
      name: 'Rembangan',
      category: 'ALAM',
      latitude: -8.056,
      longitude: 113.717,
    ),
  ];

  test('navigation directions use the OpenStreetMap website', () {
    final uri = OpenStreetMapService.directionsUri(
      fromLatitude: -8.167,
      fromLongitude: 113.702,
      toLatitude: -8.431,
      toLongitude: 113.561,
    );

    expect(uri.host, 'www.openstreetmap.org');
    expect(uri.path, '/directions');
    expect(uri.queryParameters['engine'], 'fossgis_osrm_car');
    expect(uri.queryParameters['route'], '-8.167,113.702;-8.431,113.561');
  });

  testWidgets('peta menampilkan destinasi dinamis dan legenda kategori', (
    tester,
  ) async {
    await _setTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pump();

    for (final destination in destinations) {
      expect(
        find.byKey(ValueKey('map-destination-${destination.id}')),
        findsOneWidget,
      );
    }
    expect(find.text('3 dari 3 destinasi'), findsOneWidget);
    expect(find.text('Alam'), findsWidgets);
    expect(find.text('Bahari'), findsWidgets);
    expect(find.text('Buatan'), findsWidgets);
    expect(find.text('Peta Wisata'), findsOneWidget);
    expect(find.text('Pilih destinasi'), findsOneWidget);
    expect(find.text('Lokasi Anda'), findsNothing);
    expect(find.text('Jarak rute'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pencarian dan kategori memfilter marker dan hitungan', (
    tester,
  ) async {
    await _setTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'papuma');
    await tester.pump();
    expect(find.byKey(const ValueKey('map-destination-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-destination-2')), findsNothing);
    expect(find.text('1 dari 3 destinasi'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-open-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Urutkan'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-filter-category-BUATAN')));
    await tester.tap(find.text('Tampilkan destinasi'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-destination-1')), findsNothing);
    expect(find.byKey(const ValueKey('map-destination-2')), findsOneWidget);
    expect(find.text('1 dari 3 destinasi'), findsOneWidget);
    expect(find.text('Buatan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estimasi menampilkan jarak dan waktu dari rute terpilih', (
    tester,
  ) async {
    await _setTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          destinationService: _TestDestinationService(destinations),
          routeEstimateService: _TestRouteEstimateService(),
          locationProvider: () async => const LatLng(-8.167, 113.702),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('map-destination-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pantai Papuma').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-estimate-route')));
    await tester.pumpAndSettle();

    expect(find.text('Jarak rute'), findsOneWidget);
    expect(find.text('12.3 km'), findsOneWidget);
    expect(find.text('Estimasi berkendara'), findsOneWidget);
    expect(find.text('35 menit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marker membuka ringkasan destinasi', (tester) async {
    await _setTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('map-marker-1')));
    await tester.pumpAndSettle();

    expect(find.text('Pantai Papuma'), findsWidgets);
    expect(find.text('Lihat detail'), findsOneWidget);
    expect(find.text('Rute'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout peta tetap muat pada layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MapPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setTestViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
}

Destination _destination({
  required String id,
  required String name,
  required String category,
  required double latitude,
  required double longitude,
}) => Destination(
  id: id,
  name: name,
  location: 'Jember',
  latitude: latitude,
  longitude: longitude,
  routeDistanceKm: 0,
  category: category,
);

class _TestDestinationService extends DestinationService {
  _TestDestinationService(this.destinations);

  final List<Destination> destinations;

  @override
  Future<List<Destination>> getMapDestinations({LatLng? origin}) async =>
      destinations;
}

class _TestRouteEstimateService extends RouteEstimateService {
  @override
  Future<RouteEstimate> estimate({
    required LatLng origin,
    required LatLng destination,
  }) async => RouteEstimate(
    distanceMeters: 12345,
    durationSeconds: 1860,
    routePoints: [origin, destination],
  );
}
