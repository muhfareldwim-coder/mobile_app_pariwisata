import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/destination.dart';
import '../destination/destination_detail_page.dart';
import '../profile/profile_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _jemberCenter = LatLng(-8.172, 113.700);
  static const _filters = ['Semua', 'Bahari', 'Alam & Air', 'Buatan'];
  static const _locations = [
    _MapLocation(
      name: 'Pantai Tanjung Papuma',
      category: 'Bahari',
      area: 'Ambulu',
      description: 'Pantai berpasir putih dengan gugusan batu karang.',
      position: LatLng(-8.431, 113.561),
      price: 25000,
      distance: '42 km',
      icon: Icons.waves_rounded,
    ),
    _MapLocation(
      name: 'Pantai Watu Ulo',
      category: 'Bahari',
      area: 'Ambulu',
      description: 'Garis pantai ikonik di pesisir selatan Jember.',
      position: LatLng(-8.422, 113.568),
      price: 15000,
      distance: '41 km',
      icon: Icons.beach_access_rounded,
    ),
    _MapLocation(
      name: 'Air Terjun Tancak',
      category: 'Alam & Air',
      area: 'Panti',
      description: 'Air terjun di kaki Gunung Argopuro.',
      position: LatLng(-8.055, 113.646),
      price: 10000,
      distance: '18 km',
      icon: Icons.waterfall_chart_rounded,
    ),
    _MapLocation(
      name: 'Pemandian Rembangan',
      category: 'Alam & Air',
      area: 'Arjasa',
      description: 'Kawasan perbukitan dengan udara sejuk.',
      position: LatLng(-8.063, 113.734),
      price: 20000,
      distance: '17 km',
      icon: Icons.pool_rounded,
    ),
    _MapLocation(
      name: 'Taman Botani Sukorambi',
      category: 'Buatan',
      area: 'Sukorambi',
      description: 'Taman rekreasi keluarga dengan beragam wahana.',
      position: LatLng(-8.126, 113.676),
      price: 20000,
      distance: '8 km',
      icon: Icons.park_rounded,
    ),
    _MapLocation(
      name: 'Alun-Alun Jember',
      category: 'Buatan',
      area: 'Kaliwates',
      description: 'Ruang terbuka publik di pusat Kabupaten Jember.',
      position: _jemberCenter,
      price: 0,
      distance: '1 km',
      icon: Icons.location_city_rounded,
    ),
  ];

  final _mapController = MapController();
  final _searchController = TextEditingController();
  String _activeFilter = 'Semua';
  String _searchQuery = '';
  _MapLocation? _selectedLocation = _locations.first;

  List<_MapLocation> get _visibleLocations => _locations.where((location) {
    final matchesFilter =
        _activeFilter == 'Semua' || location.category == _activeFilter;
    final matchesSearch = location.name.toLowerCase().contains(
      _searchQuery.trim().toLowerCase(),
    );
    return matchesFilter && matchesSearch;
  }).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      final visible = _visibleLocations;
      if (!visible.contains(_selectedLocation)) {
        _selectedLocation = visible.isEmpty ? null : visible.first;
      }
    });
  }

  void _search(String value) {
    setState(() {
      _searchQuery = value;
      final visible = _visibleLocations;
      if (visible.isNotEmpty && !visible.contains(_selectedLocation)) {
        _selectedLocation = visible.first;
      } else if (visible.isEmpty) {
        _selectedLocation = null;
      }
    });
  }

  void _focusLocation(_MapLocation location) {
    setState(() => _selectedLocation = location);
    _mapController.move(location.position, 14.5);
  }

  void _openDetails(_MapLocation location) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailPage(
          destination: Destination(
            id: location.name.toLowerCase().replaceAll(' ', '-'),
            name: location.name,
            location: '${location.area}, Jember',
            description: location.description,
            ticketPrice: location.price,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102F50);
    const blue = Color(0xFF1265B8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
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
                      width: 54,
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
                            color: navy,
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
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.person_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari lokasi wisata di peta...',
                      prefixIcon: const Icon(Icons.search, color: blue),
                      suffixIcon: _searchQuery.isEmpty
                          ? const Icon(Icons.tune_rounded, color: blue)
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E7F1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E7F1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = _activeFilter == filter;
                      final icon = switch (filter) {
                        'Bahari' => Icons.waves_rounded,
                        'Alam & Air' => Icons.landscape_outlined,
                        'Buatan' => Icons.account_balance_outlined,
                        _ => Icons.explore_outlined,
                      };
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(
                          icon,
                          size: 15,
                          color: selected ? Colors.white : navy,
                        ),
                        label: Text(filter),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: navy,
                        side: BorderSide(
                          color: selected ? navy : const Color(0xFFE0E5F0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        onSelected: (_) => _setFilter(filter),
                      );
                    },
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
                  options: const MapOptions(
                    initialCenter: _jemberCenter,
                    initialZoom: 11.2,
                    minZoom: 8,
                    maxZoom: 18,
                    backgroundColor: Color(0xFFE4F1EA),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_pariwisata',
                      maxNativeZoom: 19,
                      errorTileCallback: (tile, error, stackTrace) {},
                    ),
                    MarkerLayer(
                      markers: [
                        for (final location in _visibleLocations)
                          Marker(
                            point: location.position,
                            width: 142,
                            height: 44,
                            alignment: Alignment.bottomCenter,
                            child: _MapMarker(
                              location: location,
                              selected: location == _selectedLocation,
                              onTap: () =>
                                  setState(() => _selectedLocation = location),
                            ),
                          ),
                      ],
                    ),
                    const SimpleAttributionWidget(
                      source: Text('OpenStreetMap contributors'),
                      backgroundColor: Color(0xEEFFFFFF),
                    ),
                  ],
                ),
                if (_visibleLocations.isEmpty)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Destinasi tidak ditemukan'),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 24,
                  child: Column(
                    children: [
                      _MapControl(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Kembali ke Jember',
                        onPressed: () =>
                            _mapController.move(_jemberCenter, 11.2),
                      ),
                      const SizedBox(height: 8),
                      _MapControl(
                        icon: Icons.add,
                        tooltip: 'Perbesar peta',
                        onPressed: () {
                          final camera = _mapController.camera;
                          _mapController.move(camera.center, camera.zoom + 1);
                        },
                      ),
                      const SizedBox(height: 1),
                      _MapControl(
                        icon: Icons.remove,
                        tooltip: 'Perkecil peta',
                        onPressed: () {
                          final camera = _mapController.camera;
                          _mapController.move(camera.center, camera.zoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SelectedDestinationPanel(
            totalCount: _visibleLocations.length,
            location: _selectedLocation,
            onFocus: _selectedLocation == null
                ? null
                : () => _focusLocation(_selectedLocation!),
            onDetails: _selectedLocation == null
                ? null
                : () => _openDetails(_selectedLocation!),
          ),
        ],
      ),
    );
  }
}

class _MapLocation {
  const _MapLocation({
    required this.name,
    required this.category,
    required this.area,
    required this.description,
    required this.position,
    required this.price,
    required this.distance,
    required this.icon,
  });

  final String name;
  final String category;
  final String area;
  final String description;
  final LatLng position;
  final int price;
  final String distance;
  final IconData icon;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.location,
    required this.selected,
    required this.onTap,
  });

  final _MapLocation location;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFF102F50)
        : Colors.white.withValues(alpha: 0.96);
    final foreground = selected ? Colors.white : const Color(0xFF18324E);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 138),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? const Color(0xFF102F50)
                    : const Color(0xFFD6E0EB),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220A2745),
                  blurRadius: 7,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(location.icon, size: 13, color: const Color(0xFFF4A11A)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  location.price == 0
                      ? 'Gratis'
                      : '${(location.price / 1000).round()}k',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF1265B8)
                  : const Color(0xFF119A86),
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
      borderRadius: BorderRadius.circular(11),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 42, height: 42),
        icon: Icon(icon, color: const Color(0xFF102F50), size: 20),
      ),
    );
  }
}

class _SelectedDestinationPanel extends StatelessWidget {
  const _SelectedDestinationPanel({
    required this.totalCount,
    required this.location,
    required this.onFocus,
    required this.onDetails,
  });

  final int totalCount;
  final _MapLocation? location;
  final VoidCallback? onFocus;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102F50);
    const blue = Color(0xFF1265B8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140D2744),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation_rounded, color: Color(0xFFEF8B08)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Destinasi Terpilih',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${location == null ? 0 : 1} dari $totalCount lokasi',
                style: const TextStyle(color: Color(0xFF727A88), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (location == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Pilih destinasi untuk melihat informasinya.'),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E6F2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEFE7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      location!.icon,
                      color: const Color(0xFF178A80),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'WISATA ${location!.category.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          location!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          location!.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6E7683),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                location!.price == 0
                                    ? 'Gratis'
                                    : 'Rp ${location!.price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}',
                                style: const TextStyle(
                                  color: Color(0xFFEF8B08),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '△ ${location!.distance}',
                              style: const TextStyle(color: blue, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: onFocus,
                      icon: const Icon(Icons.near_me_outlined, size: 18),
                      label: const Text('Buka Rute'),
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Lihat Detail'),
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
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
