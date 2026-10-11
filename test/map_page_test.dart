import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_pariwisata/data/destination_data.dart';
import 'package:mobile_pariwisata/data/services/open_street_map_service.dart';
import 'package:mobile_pariwisata/presentation/pages/map/map_page.dart';

void main() {
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

  testWidgets('peta menampilkan seluruh destinasi dari Explore', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.pump();

    for (final destination in destinations) {
      expect(
        find.byKey(ValueKey('map-destination-${destination.id}')),
        findsOneWidget,
        reason: '${destination.name} harus memiliki penanda di peta.',
      );
    }
    expect(
      find.text('${destinations.length} destinasi wisata di Jember'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pilihan moda memperbarui estimasi rute', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.pump();
    expect(find.text('1 jam 10 mnt'), findsOneWidget);

    await tester.tap(find.text('Motor (55m)'));
    await tester.pump();

    expect(find.textContaining('Estimasi 55 mnt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout peta tetap muat pada layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.pump();

    expect(find.byType(MapPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rute memakai lokasi perangkat sebagai titik awal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final originalPlatform = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    addTearDown(() => GeolocatorPlatform.instance = originalPlatform);

    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.pumpAndSettle();

    expect(find.text('Lokasi Anda'), findsOneWidget);
    expect(find.textContaining('dari lokasi Anda'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zoom peta tetap aktif dan tidak direset oleh lokasi terlambat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final originalPlatform = GeolocatorPlatform.instance;
    final pendingLocation = _PendingGeolocatorPlatform();
    GeolocatorPlatform.instance = pendingLocation;
    addTearDown(() => GeolocatorPlatform.instance = originalPlatform);

    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    await tester.pump();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final mapController = map.mapController!;
    final initialZoom = mapController.camera.zoom;
    final interactionFlags = map.options.interactionOptions.flags;
    expect(InteractiveFlag.hasDrag(interactionFlags), isTrue);
    expect(InteractiveFlag.hasPinchZoom(interactionFlags), isTrue);
    expect(InteractiveFlag.hasPinchMove(interactionFlags), isTrue);

    final mapCenter = tester.getCenter(find.byType(FlutterMap));
    final firstFinger = await tester.startGesture(
      mapCenter.translate(-24, 0),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      mapCenter.translate(24, 0),
      pointer: 2,
    );
    await firstFinger.moveTo(mapCenter.translate(-64, 0));
    await secondFinger.moveTo(mapCenter.translate(64, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();

    final zoomAfterPinch = mapController.camera.zoom;
    expect(zoomAfterPinch, greaterThan(initialZoom));

    pendingLocation.position.complete(_testPosition());
    await tester.pumpAndSettle();

    expect(mapController.camera.zoom, closeTo(zoomAfterPinch, 0.000001));
    expect(tester.takeException(), isNull);
  });
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    longitude: 113.70,
    latitude: -8.17,
    timestamp: DateTime(2026),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

class _PendingGeolocatorPlatform extends GeolocatorPlatform {
  final position = Completer<Position>();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      position.future;
}

Position _testPosition() => Position(
  longitude: 113.70,
  latitude: -8.17,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);
