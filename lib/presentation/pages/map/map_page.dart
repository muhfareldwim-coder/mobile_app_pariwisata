import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/destination.dart';
import '../../../data/services/device_location_service.dart';
import '../../../data/services/destination_service.dart';
import '../../../data/services/route_estimate_service.dart';
import '../destination/destination_detail_page.dart';
import '../profile/profile_page.dart';

const _navy = Color(0xFF12304A);
const _raisedNavy = Color(0xFF244D70);
const _muted = Color(0xFF8190A5);
const _pageBackground = Color(0xFFF8FAFC);
const _mapCenter = LatLng(-8.17, 113.70);

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.onProfileTap,
    this.destinationService,
    this.routeEstimateService,
    this.locationProvider,
  });

  final VoidCallback? onProfileTap;
  final DestinationService? destinationService;
  final RouteEstimateService? routeEstimateService;
  final Future<LatLng?> Function()? locationProvider;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  late final DestinationService _destinationService;
  late final RouteEstimateService _routeEstimateService;
  List<Destination> _destinations = const [];
  String _query = '';
  String _selectedCategory = 'Semua';
  String _selectedSort = 'Terpopuler';
  String? _selectedDestinationId;
  RouteEstimate? _routeEstimate;
  String? _routeError;
  String? _loadError;
  bool _isLoading = true;
  bool _isEstimatingRoute = false;
  bool _hasUserMovedMap = false;
  int _routeRequestGeneration = 0;

  List<Destination> get _visibleDestinations {
    final query = _query.trim().toLowerCase();
    final destinations = _destinations.where((destination) {
      final matchesName =
          destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          _categoryKey(destination.category) == _selectedCategory;
      return matchesName && matchesCategory;
    }).toList();
    _sortDestinations(destinations);
    return destinations;
  }

  List<String> get _categories {
    final categories =
        _destinations
            .map((destination) => _categoryKey(destination.category))
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  @override
  void initState() {
    super.initState();
    _destinationService = widget.destinationService ?? DestinationService();
    _routeEstimateService =
        widget.routeEstimateService ?? RouteEstimateService();
    _loadDestinations();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final loaded = await _destinationService.getMapDestinations();
      if (!mounted) return;
      setState(() {
        _destinations = loaded;
        if (_selectedCategory != 'Semua' &&
            !_categories.contains(_selectedCategory)) {
          _selectedCategory = 'Semua';
        }
        if (_selectedDestinationId != null &&
            !_visibleDestinations.any(
              (destination) => destination.id == _selectedDestinationId,
            )) {
          _clearRouteSelection();
        }
      });
      if (!_hasUserMovedMap) _fitMapToDestinations();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Destinasi terbaru gagal dimuat: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fitMapToDestinations() {
    final destinations = _visibleDestinations;
    if (destinations.isEmpty) return;
    final points = destinations
        .map(
          (destination) => LatLng(destination.latitude, destination.longitude),
        )
        .toList();
    if (points.length == 1) {
      _mapController.move(points.single, 12);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(36),
        maxZoom: 13,
      ),
    );
  }

  void _onFilterChanged() {
    setState(() {
      _query = _searchController.text;
      if (_selectedDestinationId != null &&
          !_visibleDestinations.any(
            (destination) => destination.id == _selectedDestinationId,
          )) {
        _clearRouteSelection();
      }
    });
    _fitMapToDestinations();
  }

  void _clearRouteSelection() {
    _routeRequestGeneration++;
    _isEstimatingRoute = false;
    _selectedDestinationId = null;
    _routeEstimate = null;
    _routeError = null;
  }

  void _selectDestination(Destination destination) {
    _routeRequestGeneration++;
    setState(() {
      _isEstimatingRoute = false;
      _selectedDestinationId = destination.id;
      _routeEstimate = null;
      _routeError = null;
    });
  }

  Future<void> _showFilterDialog() async {
    var selectedCategory = _selectedCategory;
    var selectedSort = _selectedSort;
    final result = await showDialog<(String, String)>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter destinasi',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup filter',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded, color: _navy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _FilterHeading('Kategori'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      for (final category in {
                        'Semua',
                        'ALAM',
                        'BAHARI',
                        'BUATAN',
                        ..._categories,
                      })
                        _FilterChoiceChip(
                          key: ValueKey('map-filter-category-$category'),
                          label: _categoryLabel(category),
                          selected: selectedCategory == category,
                          onSelected: () =>
                              setDialogState(() => selectedCategory = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _FilterHeading('Urutkan'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      for (final sort in _sortOptions)
                        _FilterChoiceChip(
                          key: ValueKey('map-filter-sort-$sort'),
                          label: sort,
                          selected: selectedSort == sort,
                          onSelected: () =>
                              setDialogState(() => selectedSort = sort),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, (
                        selectedCategory,
                        selectedSort,
                      )),
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tampilkan destinasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedCategory = result.$1;
      _selectedSort = result.$2;
      if (_selectedDestinationId != null &&
          !_visibleDestinations.any(
            (destination) => destination.id == _selectedDestinationId,
          )) {
        _clearRouteSelection();
      }
    });
    _fitMapToDestinations();
  }

  static const _sortOptions = [
    'Terpopuler',
    'Rating Tertinggi',
    'Jarak Terdekat',
    'Harga Terendah',
  ];

  void _sortDestinations(List<Destination> destinations) {
    switch (_selectedSort) {
      case 'Rating Tertinggi':
        destinations.sort(
          (first, second) => second.rating.compareTo(first.rating),
        );
        break;
      case 'Jarak Terdekat':
        destinations.sort(
          (first, second) => first.distanceKm.compareTo(second.distanceKm),
        );
        break;
      case 'Harga Terendah':
        destinations.sort(
          (first, second) => first.ticketPrice.compareTo(second.ticketPrice),
        );
        break;
      default:
        destinations.sort(
          (first, second) =>
              _reviewValue(second.reviewCount)
                  .compareTo(_reviewValue(first.reviewCount)),
        );
        break;
    }
  }

  int _reviewValue(String value) => value.endsWith('k')
      ? ((double.tryParse(value.substring(0, value.length - 1)) ?? 0) * 1000)
            .round()
      : int.tryParse(value) ?? 0;

  Future<void> _calculateRouteEstimate() async {
    final destination = _selectedDestination;
    if (destination == null || _isEstimatingRoute) return;
    final requestGeneration = ++_routeRequestGeneration;
    setState(() {
      _isEstimatingRoute = true;
      _routeError = null;
    });
    try {
      final origin =
          await (widget.locationProvider ??
              DeviceLocationService.currentLocation)();
      if (origin == null) {
        throw const FormatException(
          'Lokasi perangkat tidak tersedia. Aktifkan GPS dan izinkan akses lokasi.',
        );
      }
      if (requestGeneration != _routeRequestGeneration) return;
      final estimate = await _routeEstimateService.estimate(
        origin: origin,
        destination: LatLng(destination.latitude, destination.longitude),
      );
      if (!mounted) return;
      if (requestGeneration == _routeRequestGeneration) {
        setState(() => _routeEstimate = estimate);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              requestGeneration != _routeRequestGeneration ||
              estimate.routePoints.length < 2) {
            return;
          }
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(estimate.routePoints),
              padding: const EdgeInsets.all(32),
              maxZoom: 15,
            ),
          );
        });
      }
    } on Exception catch (error) {
      if (!mounted) return;
      if (requestGeneration == _routeRequestGeneration) {
        setState(() {
          _routeError = error.toString();
          _routeEstimate = null;
        });
      }
    } finally {
      if (mounted && requestGeneration == _routeRequestGeneration) {
        setState(() => _isEstimatingRoute = false);
      }
    }
  }

  Destination? get _selectedDestination {
    for (final destination in _visibleDestinations) {
      if (destination.id == _selectedDestinationId) return destination;
    }
    return null;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '$hours jam'
        : '$hours jam $remainingMinutes menit';
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

  void _showDestination(Destination destination) {
    _selectDestination(destination);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryDot(category: destination.category, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    _categoryLabel(destination.category),
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                destination.name,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (destination.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  destination.location,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push<void>(
                      this.context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            DestinationDetailPage(destination: destination),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lihat detail'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.viewPaddingOf(context).top + 10,
                16,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_navy, _raisedNavy],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Peta Wisata',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Temukan dan pilih destinasi wisata Jember.',
                          style: TextStyle(
                            color: Color(0xFFCCD8E5),
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang destinasi',
                    onPressed: _isLoading ? null : _loadDestinations,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
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
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                    icon: const Icon(Icons.person_outline),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3EAF2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: _raisedNavy,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _onFilterChanged(),
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: Color(0xFF172B4D),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari destinasi yang anda inginkan',
                          hintStyle: TextStyle(color: _muted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Hapus pencarian',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 40,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onFilterChanged();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _muted,
                          size: 19,
                        ),
                      ),
                    IconButton(
                      key: const ValueKey('map-open-filter'),
                      tooltip: 'Filter destinasi',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 40,
                      ),
                      onPressed: _showFilterDialog,
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: _raisedNavy,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_visibleDestinations.length} dari ${_destinations.length} destinasi',
                      key: const ValueKey('map-result-count'),
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  if (_selectedCategory != 'Semua')
                    _ActiveFilterLabel(_categoryLabel(_selectedCategory)),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _navy,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter,
                      initialZoom: 9.4,
                      minZoom: 7,
                      maxZoom: 18,
                      backgroundColor: const Color(0xFFE4F1EA),
                      onMapEvent: _onMapEvent,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        enableMultiFingerGestureRace: true,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.mobile_pariwisata',
                        maxNativeZoom: 19,
                      ),
                      if (_routeEstimate != null &&
                          _routeEstimate!.routePoints.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routeEstimate!.routePoints,
                              color: const Color(0xFF0863C6),
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (_routeEstimate?.routePoints.isNotEmpty ?? false)
                            Marker(
                              point: _routeEstimate!.routePoints.first,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22A06B),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          for (final destination in _visibleDestinations)
                            Marker(
                              key: ValueKey(
                                'map-destination-${destination.id}',
                              ),
                              point: LatLng(
                                destination.latitude,
                                destination.longitude,
                              ),
                              width: 40,
                              height: 44,
                              alignment: Alignment.bottomCenter,
                              child: _DestinationMarker(
                                destination: destination,
                                onTap: () => _showDestination(destination),
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
                  if (_visibleDestinations.isEmpty && !_isLoading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _loadError == null
                                  ? 'Tidak ada destinasi dengan koordinat yang sesuai.'
                                  : 'Peta destinasi tidak dapat dimuat.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_loadError != null && !_isLoading)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _loadError!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadDestinations,
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
            _routePanel(),
            _CategoryLegend(categories: _categories),
          ],
        ),
      ),
    );
  }

  Widget _routePanel() {
    final destination = _selectedDestination;
    final estimate = _routeEstimate;
    final durationMinutes = estimate == null
        ? 0
        : (estimate.durationSeconds / 60 / 5).ceil() * 5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EDF3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pilih destinasi',
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: const ValueKey('map-destination-selector'),
            initialValue:
                _visibleDestinations.any(
                  (item) => item.id == _selectedDestinationId,
                )
                ? _selectedDestinationId
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Pilih destinasi wisata',
              isDense: true,
              filled: true,
              fillColor: _pageBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: [
              for (final item in _visibleDestinations)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              Destination? selected;
              for (final item in _visibleDestinations) {
                if (item.id == id) {
                  selected = item;
                  break;
                }
              }
              if (selected != null) _selectDestination(selected);
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              key: const ValueKey('map-estimate-route'),
              onPressed: destination == null || _isEstimatingRoute
                  ? null
                  : _calculateRouteEstimate,
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(color: _navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _isEstimatingRoute
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Menghitung rute...'),
                      ],
                    )
                  : Text(
                      estimate == null
                          ? 'Lihat estimasi jarak & waktu'
                          : 'Perbarui estimasi rute',
                    ),
            ),
          ),
          if (_routeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _routeError!,
              key: const ValueKey('map-route-error'),
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ],
          if (estimate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _RouteEstimateValue(
                    label: 'Jarak rute',
                    value:
                        '${(estimate.distanceMeters / 1000).toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(
                  height: 30,
                  child: VerticalDivider(width: 24, color: Color(0xFFE2E8F0)),
                ),
                Expanded(
                  child: _RouteEstimateValue(
                    label: 'Estimasi berkendara',
                    value: _formatDuration(durationMinutes),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker({required this.destination, required this.onTap});

  final Destination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(destination.category);
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: destination.name,
        child: Icon(
          Icons.location_on,
          key: ValueKey('map-marker-${destination.id}'),
          size: 36,
          color: color,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final shownCategories = categories.isEmpty
        ? const ['ALAM', 'BAHARI', 'BUATAN']
        : categories;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 8,
        children: [
          for (final category in shownCategories)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CategoryDot(category: category, size: 15),
                const SizedBox(width: 5),
                Text(
                  _categoryLabel(category),
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _navy,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    onSelected: (_) => onSelected(),
    backgroundColor: Colors.white,
    selectedColor: _navy,
    side: const BorderSide(color: _navy),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    labelStyle: TextStyle(
      color: selected ? Colors.white : _navy,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _ActiveFilterLabel extends StatelessWidget {
  const _ActiveFilterLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _navy,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _RouteEstimateValue extends StatelessWidget {
  const _RouteEstimateValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: _navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.category, required this.size});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.location_on, size: size, color: _categoryColor(category));
}

Color _categoryColor(String category) => switch (_categoryKey(category)) {
  'ALAM' => const Color(0xFF168A62),
  'BAHARI' => const Color(0xFF1685B5),
  'BUATAN' => const Color(0xFFE47B16),
  _ => const Color(0xFFD94A48),
};

String _categoryKey(String category) => category.trim().toUpperCase();

String _categoryLabel(String category) => switch (_categoryKey(category)) {
  'ALAM' => 'Alam',
  'BAHARI' => 'Bahari',
  'BUATAN' => 'Buatan',
  _ => category.trim().isEmpty ? 'Wisata' : category.trim(),
};
