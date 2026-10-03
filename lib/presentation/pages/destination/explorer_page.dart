import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/destination_data.dart';
import '../../../data/models/destination.dart';
import '../../widgets/destination/category_chip.dart';
import '../../widgets/destination/destination_card.dart';
import 'destination_detail_page.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key, this.initialCategory = 'Semua'});

  final String initialCategory;

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final searchController = TextEditingController();
  final favorites = <String>{};
  late String selectedCategory;
  String selectedSort = 'Terpopuler';

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: _exploreBody(),
    );
  }

  Widget _exploreBody() {
    final filtered = destinations.where((destination) {
      final categoryMatches =
          selectedCategory == 'Semua' ||
          destination.category == selectedCategory.toUpperCase();
      final query = searchController.text.trim().toLowerCase();
      final searchMatches =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query);
      return categoryMatches && searchMatches;
    }).toList();
    _sortDestinations(filtered);

    return ListView(
      key: const ValueKey('exploreList'),
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Daftar Wisata',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${filtered.length} Ditemukan',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Berdasarkan lokasi & rekomendasi terbaik',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Urutkan destinasi',
                onSelected: (sort) => setState(() => selectedSort = sort),
                itemBuilder: (_) => [
                  for (final sort in _sortOptions)
                    PopupMenuItem(
                      value: sort,
                      child: Row(
                        children: [
                          if (sort == selectedSort)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.orange,
                            ),
                          if (sort == selectedSort) const SizedBox(width: 7),
                          Text(sort, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_vert,
                        size: 15,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        selectedSort == 'Terpopuler'
                            ? 'Terpopuler'
                            : selectedSort,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 15,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Destinasi tidak ditemukan',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
          )
        else
          for (final destination in filtered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DestinationCard(
                destination: destination,
                isFavorite: favorites.contains(destination.id),
                onFavoriteChanged: (favorite) => setState(() {
                  favorite
                      ? favorites.add(destination.id)
                      : favorites.remove(destination.id);
                }),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DestinationDetailPage(destination: destination),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      key: const ValueKey('exploreHeader'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        19,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'JELAJAH JEMBER',
                          style: TextStyle(
                            color: Color(0xFFC2D0DD),
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Eksplor\nDestinasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: AppColors.blueDeep,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12,
                          ),
                          cursorColor: AppColors.orange,
                          decoration: const InputDecoration(
                            hintText: 'Cari nama destinasi atau lokasi',
                            hintStyle: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 25,
                            minHeight: 25,
                          ),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.secondaryText,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Material(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(13),
                      child: IconButton(
                        tooltip: 'Filter destinasi',
                        onPressed: _showFilterSheet,
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD05C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryChip(
                  label: 'Semua',
                  icon: Icons.grid_view_rounded,
                  selected: selectedCategory == 'Semua',
                  onTap: () => setState(() => selectedCategory = 'Semua'),
                ),
                CategoryChip(
                  label: 'Alam',
                  icon: Icons.park_outlined,
                  count: 14,
                  selected: selectedCategory == 'ALAM',
                  onTap: () => setState(() => selectedCategory = 'ALAM'),
                ),
                CategoryChip(
                  label: 'Bahari',
                  icon: Icons.waves_rounded,
                  count: 8,
                  selected: selectedCategory == 'BAHARI',
                  onTap: () => setState(() => selectedCategory = 'BAHARI'),
                ),
                CategoryChip(
                  label: 'Buatan',
                  icon: Icons.account_balance_outlined,
                  selected: selectedCategory == 'BUATAN',
                  onTap: () => setState(() => selectedCategory = 'BUATAN'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filter destinasi',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kategori',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final category in ['Semua', 'ALAM', 'BAHARI', 'BUATAN'])
                    ChoiceChip(
                      label: Text(
                        category == 'Semua'
                            ? category
                            : _categoryLabel(category),
                      ),
                      selected: selectedCategory == category,
                      onSelected: (_) =>
                          setSheetState(() => selectedCategory = category),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Urutkan',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final sort in _sortOptions)
                    ChoiceChip(
                      label: Text(sort),
                      selected: selectedSort == sort,
                      onSelected: (_) =>
                          setSheetState(() => selectedSort = sort),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, (selectedCategory, selectedSort)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                  child: const Text('Tampilkan destinasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        selectedCategory = result.$1;
        selectedSort = result.$2;
      });
    }
  }

  static const _sortOptions = [
    'Terpopuler',
    'Rating Tertinggi',
    'Jarak Terdekat',
    'Harga Terendah',
  ];

  void _sortDestinations(List<Destination> items) {
    switch (selectedSort) {
      case 'Rating Tertinggi':
        items.sort((a, b) => b.rating.compareTo(a.rating));
      case 'Jarak Terdekat':
        items.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case 'Harga Terendah':
        items.sort((a, b) => a.ticketPrice.compareTo(b.ticketPrice));
      default:
        items.sort(
          (a, b) =>
              _reviewValue(b.reviewCount)
                  .compareTo(_reviewValue(a.reviewCount)),
        );
    }
  }

  int _reviewValue(String value) => value.endsWith('k')
      ? ((double.tryParse(value.substring(0, value.length - 1)) ?? 0) * 1000)
            .round()
      : int.tryParse(value) ?? 0;
  String _categoryLabel(String category) =>
      category[0] + category.substring(1).toLowerCase();
}
