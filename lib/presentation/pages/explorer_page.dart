import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'home_page.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key, this.initialDestination});

  final _Destination? initialDestination;

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _searchController.text = widget.initialDestination!.name;
      _showMap = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Destination> get _filteredDestinations {
    final query = _searchController.text.toLowerCase().trim();
    return _destinations.where((destination) {
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          destination.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openDestination(_Destination destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DestinationDetailPage(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _filteredDestinations;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Eksplor Destinasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Kembali ke beranda',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _ExplorerControls(
            controller: _searchController,
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) =>
                setState(() => _selectedCategory = category),
            onSearchChanged: (_) => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Text(
                  '${destinations.length} destinasi ditemukan',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.view_list)),
                    ButtonSegment(value: true, icon: Icon(Icons.map_outlined)),
                  ],
                  selected: {_showMap},
                  onSelectionChanged: (selection) =>
                      setState(() => _showMap = selection.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showMap
                ? _ExplorerMap(
                    destinations: destinations,
                    onDestinationTap: _openDestination,
                  )
                : destinations.isEmpty
                ? const _EmptyExplorerState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: destinations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final destination = destinations[index];
                      return _ExplorerDestinationCard(
                        destination: destination,
                        onTap: () => _openDestination(destination),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _ExplorerNavigation(
        onHome: () => Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage())),
      ),
    );
  }
}

class _ExplorerControls extends StatelessWidget {
  const _ExplorerControls({
    required this.controller,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  final TextEditingController controller;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            style: const TextStyle(color: AppColors.dark, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari destinasi, lokasi, atau aktivitas',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final category = _categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) => onCategoryChanged(category),
                  selectedColor: AppColors.yellow,
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  labelStyle: TextStyle(
                    color: selectedCategory == category
                        ? AppColors.dark
                        : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerDestinationCard extends StatelessWidget {
  const _ExplorerDestinationCard({
    required this.destination,
    required this.onTap,
  });

  final _Destination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 174,
          child: Row(
            children: [
              SizedBox(
                width: 142,
                height: double.infinity,
                child: _DestinationImage(destination: destination),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(text: destination.category),
                      const SizedBox(height: 7),
                      Text(
                        destination.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${destination.rating} (${destination.reviews})',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            destination.price,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 14,
                            color: AppColors.blueDeep,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Lihat detail dan peta',
                            style: TextStyle(
                              color: AppColors.blueDeep,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _EmptyExplorerState extends StatelessWidget {
  const _EmptyExplorerState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 52,
            color: AppColors.text.withValues(alpha: .6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Destinasi tidak ditemukan',
            style: TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba kata kunci atau kategori lain.',
            style: TextStyle(color: AppColors.text, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ExplorerMap extends StatelessWidget {
  const _ExplorerMap({
    required this.destinations,
    required this.onDestinationTap,
  });

  final List<_Destination> destinations;
  final ValueChanged<_Destination> onDestinationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                  for (final destination in destinations)
                    Positioned(
                      left: destination.mapX,
                      top: destination.mapY,
                      child: GestureDetector(
                        onTap: () => onDestinationTap(destination),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Text(
                                destination.name,
                                style: const TextStyle(
                                  color: AppColors.dark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: AppColors.orange,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      heroTag: 'my-location',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.blueDeep,
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lokasi kamu berada di sekitar Jember.',
                              ),
                            ),
                          ),
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ketuk pin untuk melihat detail destinasi',
            style: TextStyle(color: AppColors.text, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE4F0E5);
    canvas.drawRect(Offset.zero & size, background);

    final water = Paint()..color = const Color(0xFFB9DDE2);
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * .35,
        size.height * .12,
        size.width * .8,
        size.height * .9,
      ),
      water,
    );

    final road = Paint()
      ..color = Colors.white.withValues(alpha: .95)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(-20, size.height * .76)
      ..cubicTo(
        size.width * .2,
        size.height * .48,
        size.width * .46,
        size.height * .62,
        size.width + 20,
        size.height * .2,
      );
    canvas.drawPath(route, road);

    final mainRoad = Paint()
      ..color = const Color(0xFFF3B35B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(route, mainRoad);

    final grid = Paint()
      ..color = const Color(0xFFC9DEC9)
      ..strokeWidth = 1;
    for (var y = 28.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), grid);
    }
    for (var x = 24.0; x < size.width; x += 58) {
      canvas.drawLine(Offset(x, 0), Offset(x - 16, size.height), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DestinationDetailPage extends StatelessWidget {
  const DestinationDetailPage({super.key, required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                destination.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: _DestinationImage(destination: destination),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryBadge(text: destination.category),
                  const SizedBox(height: 10),
                  Text(
                    destination.name,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    destination.location,
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.orange, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        '${destination.rating} dari ${destination.reviews} ulasan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    destination.description,
                    style: const TextStyle(color: AppColors.text, height: 1.55),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExplorerPage(initialDestination: destination),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Lihat lokasi di peta'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Destinasi ditambahkan ke favorit.'),
                      ),
                    ),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Simpan ke favorit'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationImage extends StatelessWidget {
  const _DestinationImage({required this.destination});
  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      destination.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [destination.color, AppColors.dark]),
        ),
        child: Center(
          child: Icon(destination.icon, color: Colors.white70, size: 54),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.sky,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.blueDeep,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _ExplorerNavigation extends StatelessWidget {
  const _ExplorerNavigation({required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: 1,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: AppColors.orange,
    unselectedItemColor: const Color(0xFF94A3B8),
    onTap: (index) {
      if (index == 0) onHome();
      if (index > 1) {
        const labels = ['Tiket', 'Favorit', 'Profil'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${labels[index - 2]} segera hadir.')),
        );
      }
    },
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Beranda',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Eksplor'),
      BottomNavigationBarItem(
        icon: Icon(Icons.confirmation_num_outlined),
        label: 'Tiket',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite_border),
        label: 'Favorit',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profil',
      ),
    ],
  );
}

class _Destination {
  const _Destination({
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.color,
    required this.icon,
    required this.mapX,
    required this.mapY,
  });

  final String name;
  final String category;
  final String location;
  final String rating;
  final String reviews;
  final String price;
  final String imageUrl;
  final String description;
  final Color color;
  final IconData icon;
  final double mapX;
  final double mapY;
}

const _categories = ['Semua', 'Alam', 'Bahari', 'Buatan', 'Kuliner'];

const _destinations = [
  _Destination(
    name: 'Pantai Tanjung Papuma',
    category: 'Bahari',
    location: 'Wuluhan, Jember',
    rating: '4.9',
    reviews: '3.1k',
    price: 'Rp 25.000',
    imageUrl: 'https://images.unsplash.com/photo-1507523416380-7b7f7f6c2e8b?auto=format&fit=crop&w=900&q=80',
    description: 'Pantai dengan pasir putih, batu karang ikonik, dan panorama laut selatan yang luas. Cocok untuk menikmati matahari terbit dan berburu foto.',
    color: Color(0xFF2C7A9E),
    icon: Icons.waves,
    mapX: 34,
    mapY: 65,
  ),
  _Destination(
    name: 'Puncak Rembangan',
    category: 'Alam',
    location: 'Arjasa, Jember',
    rating: '4.8',
    reviews: '1.9k',
    price: 'Rp 10.000',
    imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
    description: 'Kawasan sejuk di lereng Argopuro dengan pemandangan kota Jember dari ketinggian dan udara pegunungan yang segar.',
    color: Color(0xFF4C7A63),
    icon: Icons.terrain,
    mapX: 180,
    mapY: 125,
  ),
  _Destination(
    name: 'Teluk Love Payangan',
    category: 'Bahari',
    location: 'Ambulu, Jember',
    rating: '4.8',
    reviews: '2.4k',
    price: 'Rp 20.000',
    imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
    description: 'Bukit dan teluk berbentuk hati dengan lanskap pesisir yang dramatis. Waktu terbaik berkunjung adalah sore hari.',
    color: Color(0xFF477A76),
    icon: Icons.landscape,
    mapX: 100,
    mapY: 245,
  ),
  _Destination(
    name: 'Taman Botani Sukorambi',
    category: 'Buatan',
    location: 'Sukorambi, Jember',
    rating: '4.7',
    reviews: '1.1k',
    price: 'Rp 20.000',
    imageUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=80',
    description: 'Ruang hijau keluarga dengan kebun, kolam, dan berbagai aktivitas santai untuk semua usia.',
    color: Color(0xFF5D8E4E),
    icon: Icons.local_florist,
    mapX: 215,
    mapY: 315,
  ),
  _Destination(
    name: 'Air Terjun Tancak',
    category: 'Alam',
    location: 'Panti, Jember',
    rating: '4.7',
    reviews: '980',
    price: 'Rp 10.000',
    imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=900&q=80',
    description: 'Air terjun alami di tengah hutan dengan suasana teduh dan jalur trekking yang menantang.',
    color: Color(0xFF3D856C),
    icon: Icons.waterfall_chart,
    mapX: 80,
    mapY: 390,
  ),
];
