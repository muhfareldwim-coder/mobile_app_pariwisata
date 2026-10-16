import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/destination_data.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/device_location_service.dart';
import '../../../data/services/destination_service.dart';
import '../../../data/services/open_street_map_service.dart';
import '../booking/booking_page.dart';
import '../destination/destination_detail_page.dart';
import '../profile/profile_page.dart';

const _navy = Color(0xFF0B294A);
const _blue = Color(0xFF0757BD);
const _lightBlue = Color(0xFF1674E8);
const _pageBackground = Color(0xFFF8F7FC);
const _mapCenter = LatLng(-8.244, 113.619);

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final _destinationService = DestinationService();
  List<Destination> _destinations = destinations;
  Destination? _selectedDestination = destinations.first;
  _TravelMode _travelMode = _TravelMode.car;
  LatLng _startLocation = DeviceLocationService.jemberFallback;
  bool _isDeviceLocation = false;
  bool _isLocating = false;
  String? _locationMessage;
  bool _isMapExpanded = false;
  bool _hasUserMovedMap = false;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceLocation();
    });
  }

  Future<void> _loadDestinations() async {
    try {
      final loaded = await _destinationService.getDestinations();
      if (!mounted || loaded.isEmpty) return;
      final selectedId = _selectedDestination?.id;
      setState(() {
        _destinations = loaded;
        _selectedDestination =
            loaded
                .where((destination) => destination.id == selectedId)
                .firstOrNull ??
            loaded.first;
      });
      if (!_hasUserMovedMap) _fitMapToDestinations();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _locationMessage = 'Destinasi terbaru gagal dimuat: $error';
      });
    }
  }

  double _routeDistanceKm(Destination destination) {
    if (!_isDeviceLocation && destination.routeDistanceKm > 0) {
      return destination.routeDistanceKm;
    }
    final directDistance = const Distance().as(
      LengthUnit.Kilometer,
      _startLocation,
      LatLng(destination.latitude, destination.longitude),
    );
    return directDistance * 1.25;
  }

  Future<void> _loadDeviceLocation({bool recenter = false}) async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      final location = await DeviceLocationService.currentLocation();
      if (!mounted) return;
      if (location == null) {
        setState(() {
          _startLocation = DeviceLocationService.jemberFallback;
          _isDeviceLocation = false;
          _isLocating = false;
          _locationMessage = 'Lokasi tidak tersedia. Rute sementara dimulai dari Alun-alun Jember.';
        });
        _updateCameraAfterLocation(recenter: recenter);
        return;
      }

      setState(() {
        _startLocation = location;
        _isDeviceLocation = true;
        _isLocating = false;
        _locationMessage = null;
      });
      _updateCameraAfterLocation(recenter: recenter);
    } on LocationServiceDisabledException {
      _useFallbackLocation(
        'Aktifkan layanan lokasi untuk memakai posisi Anda.',
        recenter: recenter,
      );
    } on PermissionDeniedException {
      _useFallbackLocation(
        'Izin lokasi ditolak. Rute dimulai dari Alun-alun Jember.',
        recenter: recenter,
      );
    } on Exception {
      _useFallbackLocation(
        'Lokasi perangkat gagal dimuat. Rute dimulai dari Alun-alun Jember.',
        recenter: recenter,
      );
    }
  }

  void _useFallbackLocation(String message, {required bool recenter}) {
    if (!mounted) return;
    setState(() {
      _startLocation = DeviceLocationService.jemberFallback;
      _isDeviceLocation = false;
      _isLocating = false;
      _locationMessage = message;
    });
    _updateCameraAfterLocation(recenter: recenter);
  }

  void _updateCameraAfterLocation({required bool recenter}) {
    if (recenter) {
      _mapController.move(_startLocation, 11);
    } else if (!_hasUserMovedMap) {
      _fitMapToDestinations();
    }
  }

  void _onMapEvent(MapEvent event) {
    switch (event.source) {
      case MapEventSource.dragStart:
      case MapEventSource.onDrag:
      case MapEventSource.multiFingerGestureStart:
      case MapEventSource.onMultiFinger:
      case MapEventSource.doubleTap:
      case MapEventSource.doubleTapHold:
      case MapEventSource.doubleTapZoomAnimationController:
      case MapEventSource.scrollWheel:
        _hasUserMovedMap = true;
      default:
        break;
    }
  }

  void _fitMapToDestinations() {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          _startLocation,
          for (final destination in _destinations)
            LatLng(destination.latitude, destination.longitude),
        ]),
        padding: const EdgeInsets.fromLTRB(32, 28, 64, 56),
        maxZoom: 10.6,
      ),
    );
  }

  String _durationFor(Destination destination, _TravelMode mode) {
    final minutes = (_routeDistanceKm(destination) * mode.minutesPerKm).ceil();
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$minutes mnt';
    if (remainingMinutes == 0) return '$hours jam';
    return '$hours jam $remainingMinutes mnt';
  }

  void _selectDestination(Destination destination) {
    setState(() => _selectedDestination = destination);
    final camera = _mapController.camera;
    _mapController.move(
      LatLng(destination.latitude, destination.longitude),
      math.max(camera.zoom, 11.5),
    );
  }

  Future<void> _openOpenStreetMap(Destination destination) async {
    final opened = await OpenStreetMapService.openDirections(
      fromLatitude: _startLocation.latitude,
      fromLongitude: _startLocation.longitude,
      toLatitude: destination.latitude,
      toLongitude: destination.longitude,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenStreetMap tidak dapat dibuka.')),
      );
    }
  }

  Future<void> _openBooking(Destination destination) async {
    if (AuthService.currentUser == null) {
      await Navigator.pushNamed(context, AppRoutes.login);
      if (!mounted || AuthService.currentUser == null) return;
    }

    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BookingPage(destination: destination),
      ),
    );
  }

  void _openDetails(Destination destination) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailPage(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDestination = _selectedDestination;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo_jembergonobackgroud.png',
                      width: 48,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JEMBERGO',
                          style: TextStyle(
                            color: Color(0xFFEF8B08),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Map',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton.filled(
                      tooltip: 'Profil',
                      onPressed:
                          widget.onProfileTap ??
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfilePage(),
                            ),
                          ),
                      style: IconButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.person_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_isMapExpanded)
            _RouteSummaryCard(
              destination: selectedDestination,
              travelMode: _travelMode,
              duration: selectedDestination == null
                  ? null
                  : _durationFor(selectedDestination, _travelMode),
              routeDistanceKm: selectedDestination == null
                  ? null
                  : _routeDistanceKm(selectedDestination),
              isDeviceLocation: _isDeviceLocation,
              onModeSelected: (mode) => setState(() => _travelMode = mode),
              onClose: selectedDestination == null
                  ? null
                  : () => setState(() => _selectedDestination = null),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 9.4,
                    minZoom: 8,
                    maxZoom: 18,
                    backgroundColor: Color(0xFFE4F1EA),
                    onMapEvent: _onMapEvent,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      enableMultiFingerGestureRace: true,
                    ),
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints([
                        _startLocation,
                        for (final destination in _destinations)
                          LatLng(destination.latitude, destination.longitude),
                      ]),
                      padding: const EdgeInsets.fromLTRB(32, 28, 64, 56),
                      maxZoom: 10.6,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_pariwisata',
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _startLocation,
                          width: 252,
                          height: 64,
                          alignment: Alignment.bottomCenter,
                          child: _StartMarker(
                            label: _isDeviceLocation
                                ? 'Lokasi Anda'
                                : 'Titik Awal: Alun-alun Jember',
                          ),
                        ),
                        for (final destination in _destinations)
                          Marker(
                            point: LatLng(
                              destination.latitude,
                              destination.longitude,
                            ),
                            width: 172,
                            height: 62,
                            alignment: Alignment.bottomCenter,
                            child: _DestinationMarker(
                              key: ValueKey(
                                'map-destination-${destination.id}',
                              ),
                              destination: destination,
                              selected: destination == selectedDestination,
                              onTap: () => _selectDestination(destination),
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                      popupBackgroundColor: Color(0xEEFFFFFF),
                      showFlutterMapAttribution: false,
                    ),
                  ],
                ),
                Positioned(
                  left: 14,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0B294A),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_destinations.length} destinasi wisata di Jember',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 16,
                  child: Column(
                    children: [
                      _MapControl(
                        icon: _isLocating
                            ? Icons.location_searching_rounded
                            : Icons.my_location_rounded,
                        tooltip: _isDeviceLocation
                            ? 'Perbarui lokasi Anda'
                            : 'Coba gunakan lokasi perangkat',
                        onPressed: _isLocating
                            ? () {}
                            : () => _loadDeviceLocation(recenter: true),
                      ),
                      const SizedBox(height: 8),
                      _MapControl(
                        icon: _isMapExpanded
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        tooltip: _isMapExpanded
                            ? 'Tampilkan detail destinasi'
                            : 'Perbesar area peta',
                        onPressed: () =>
                            setState(() => _isMapExpanded = !_isMapExpanded),
                      ),
                    ],
                  ),
                ),
                if (_locationMessage != null || _isLocating)
                  Positioned(
                    left: 14,
                    right: 70,
                    top: 12,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            if (_isLocating)
                              const Icon(
                                Icons.location_searching_rounded,
                                size: 17,
                                color: _blue,
                              )
                            else
                              const Icon(
                                Icons.location_off_outlined,
                                size: 17,
                                color: Color(0xFFB66A00),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isLocating
                                    ? 'Mencari lokasi perangkat...'
                                    : _locationMessage!,
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 11,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (!_isLocating)
                              TextButton(
                                onPressed: _loadDeviceLocation,
                                child: const Text('Coba lagi'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!_isMapExpanded)
            _SelectedDestinationPanel(
              destination: selectedDestination,
              travelMode: _travelMode,
              duration: selectedDestination == null
                  ? null
                  : _durationFor(selectedDestination, _travelMode),
              routeDistanceKm: selectedDestination == null
                  ? null
                  : _routeDistanceKm(selectedDestination),
              isDeviceLocation: _isDeviceLocation,
              onOpenOpenStreetMap: selectedDestination == null
                  ? null
                  : () => _openOpenStreetMap(selectedDestination),
              onBook: selectedDestination == null
                  ? null
                  : () => _openBooking(selectedDestination),
              onDetails: selectedDestination == null
                  ? null
                  : () => _openDetails(selectedDestination),
            ),
        ],
      ),
    );
  }
}

enum _TravelMode {
  car('Mobil', '1j 10m', 70 / 38),
  motorcycle('Motor', '55m', 55 / 38),
  bus('Bus', '1j 30m', 90 / 38);

  const _TravelMode(this.label, this.referenceDuration, this.minutesPerKm);

  final String label;
  final String referenceDuration;
  final double minutesPerKm;
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.destination,
    required this.travelMode,
    required this.duration,
    required this.routeDistanceKm,
    required this.isDeviceLocation,
    required this.onModeSelected,
    required this.onClose,
  });

  final Destination? destination;
  final _TravelMode travelMode;
  final String? duration;
  final double? routeDistanceKm;
  final bool isDeviceLocation;
  final ValueChanged<_TravelMode> onModeSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110B294A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.turn_right_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: destination == null
                    ? const Text(
                        'Pilih destinasi di peta',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                duration!,
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EDFF),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  '${routeDistanceKm!.round()} km',
                                  style: const TextStyle(
                                    color: _blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${isDeviceLocation ? 'Dari lokasi Anda' : 'Dari Alun-alun Jember'} • menuju ${destination!.location.split(',').first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF606B7A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
              IconButton(
                tooltip: 'Tutup rute',
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Color(0xFF727A88)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1, color: Color(0xFFDDE4F3)),
          ),
          Row(
            children: [
              for (final mode in _TravelMode.values) ...[
                if (mode != _TravelMode.car) const SizedBox(width: 7),
                Expanded(
                  child: _TravelModeButton(
                    mode: mode,
                    selected: mode == travelMode,
                    duration: destination == null
                        ? mode.referenceDuration
                        : _durationForDistance(routeDistanceKm!, mode),
                    onTap: () => onModeSelected(mode),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _durationForDistance(double distanceKm, _TravelMode mode) {
    final minutes = (distanceKm * mode.minutesPerKm).ceil();
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${minutes}m';
    if (remainingMinutes == 0) return '${hours}j';
    return '${hours}j ${remainingMinutes}m';
  }
}

class _TravelModeButton extends StatelessWidget {
  const _TravelModeButton({
    required this.mode,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final _TravelMode mode;
  final bool selected;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      _TravelMode.car => Icons.directions_car_filled_rounded,
      _TravelMode.motorcycle => Icons.two_wheeler_rounded,
      _TravelMode.bus => Icons.directions_bus_filled_rounded,
    };

    return Material(
      color: selected ? _lightBlue : const Color(0xFFF1F2FD),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF777E88),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${mode.label} ($duration)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : _navy,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartMarker extends StatelessWidget {
  const _StartMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330B294A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 10, color: _lightBlue),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: _blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0x330B294A), blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerIcon = switch (destination.category) {
      'BAHARI' => Icons.waves_rounded,
      'ALAM' => Icons.waterfall_chart_rounded,
      _ => Icons.attractions_rounded,
    };

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFA51D)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330B294A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 14,
                    color: Color(0xFFFFA51D),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      destination.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Tooltip(
              message: destination.name,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF159B85), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x330B294A), blurRadius: 6),
                  ],
                ),
                child: Icon(
                  markerIcon,
                  size: 15,
                  color: const Color(0xFF159B85),
                ),
              ),
            ),
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: selected ? _blue : const Color(0xFF159B85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(13),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 46, height: 46),
        icon: Icon(icon, color: _blue, size: 21),
      ),
    );
  }
}

class _SelectedDestinationPanel extends StatelessWidget {
  const _SelectedDestinationPanel({
    required this.destination,
    required this.travelMode,
    required this.duration,
    required this.routeDistanceKm,
    required this.isDeviceLocation,
    required this.onOpenOpenStreetMap,
    required this.onBook,
    required this.onDetails,
  });

  final Destination? destination;
  final _TravelMode travelMode;
  final String? duration;
  final double? routeDistanceKm;
  final bool isDeviceLocation;
  final VoidCallback? onOpenOpenStreetMap;
  final VoidCallback? onBook;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .44,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(
          color: _pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Color(0x140D2744),
              blurRadius: 15,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: destination == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'Pilih salah satu penanda untuk melihat rute dan detail wisata.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF727A88), fontSize: 12),
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DestinationHeading(
                      destination: destination!,
                      duration: duration!,
                      routeDistanceKm: routeDistanceKm!,
                      isDeviceLocation: isDeviceLocation,
                    ),
                    const SizedBox(height: 12),
                    _RouteInstructions(
                      destination: destination!,
                      isDeviceLocation: isDeviceLocation,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: onOpenOpenStreetMap,
                        icon: const Icon(Icons.navigation_rounded, size: 21),
                        label: const Text(
                          'Buka Rute di OpenStreetMap',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: onBook,
                              icon: const Icon(
                                Icons.confirmation_number_outlined,
                                size: 18,
                              ),
                              label: const Text('Pesan Tiket'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: onDetails,
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Detail Wisata'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE9ECFF),
                                foregroundColor: _navy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DestinationHeading extends StatelessWidget {
  const _DestinationHeading({
    required this.destination,
    required this.duration,
    required this.routeDistanceKm,
    required this.isDeviceLocation,
  });

  final Destination destination;
  final String duration;
  final double routeDistanceKm;
  final bool isDeviceLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _categoryIcon(destination.category),
                    size: 18,
                    color: _blue,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Wisata ${_categoryLabel(destination.category)} Populer Jember',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                destination.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${routeDistanceKm.round()} km • Estimasi $duration ${isDeviceLocation ? 'dari lokasi Anda' : 'dari Alun-alun Jember'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF555D69),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Tiket Masuk',
              style: TextStyle(
                color: Color(0xFF727A88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatPrice(destination.ticketPrice),
              style: const TextStyle(
                color: Color(0xFFD97900),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              '/ orang',
              style: TextStyle(color: Color(0xFF727A88), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteInstructions extends StatelessWidget {
  const _RouteInstructions({
    required this.destination,
    required this.isDeviceLocation,
  });

  final Destination destination;
  final bool isDeviceLocation;

  @override
  Widget build(BuildContext context) {
    final isPapuma = destination.id == 'papuma';
    final firstStep = isDeviceLocation
        ? 'Mulai dari lokasi Anda, lalu ikuti rute menuju ${destination.location.split(',').first}.'
        : isPapuma
        ? 'Dari Alun-alun Jember, ambil arah selatan menuju Ambulu lewat Mangli / Rambipuji.'
        : 'Dari Alun-alun Jember, ikuti jalan utama menuju ${destination.location.split(',').first}.';
    final secondStep = isDeviceLocation
        ? 'Ikuti petunjuk rute OpenStreetMap hingga tiba di ${destination.name}.'
        : isPapuma
        ? 'Ikuti plang hijau "Pantai Pasir Putih Malikan (Papuma)" melewati kawasan Hutan Malabar.'
        : 'Ikuti petunjuk rute di OpenStreetMap sampai tiba di ${destination.name}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1FF),
        border: Border.all(color: const Color(0xFFE0E4FF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, size: 19, color: _blue),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Panduan Rute Mudah (Pemula)',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InstructionStep(number: 1, text: firstStep),
          const SizedBox(height: 6),
          _InstructionStep(number: 2, text: secondStep),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF313B4A),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

String _categoryLabel(String category) => switch (category) {
  'BAHARI' => 'Bahari',
  'ALAM' => 'Alam',
  _ => 'Buatan',
};

IconData _categoryIcon(String category) => switch (category) {
  'BAHARI' => Icons.waves_rounded,
  'ALAM' => Icons.waterfall_chart_rounded,
  _ => Icons.attractions_rounded,
};

String _formatPrice(int price) {
  final formatted = price.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return 'Rp $formatted';
}
