import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/destination_service.dart';
import '../../../data/services/favorite_destination_service.dart';
import '../../widgets/destination/destination_card.dart';
import 'destination_detail_page.dart';

const _exploreNavy = Color(0xFF12304A);
const _exploreRaisedNavy = Color(0xFF244D70);
const _exploreBackground = Color(0xFFF6F8FB);
const _exploreBodyText = Color(0xFF172B4D);
const _exploreSecondaryText = Color(0xFF8190A5);

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({
    super.key,
    this.initialCategory = 'Semua',
    this.destinationService,
  });

  final String initialCategory;
  final DestinationService? destinationService;

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final searchController = TextEditingController();
  late final DestinationService _destinationService;
  List<Destination> _destinations = const [];
  String? _loadError;
  bool _isLoading = true;
  late String selectedCategory;
  String selectedSort = 'Terpopuler';

  @override
  void initState() {
    super.initState();
    FavoriteDestinationService.revision.addListener(_onFavoritesChanged);
    _destinationService = widget.destinationService ?? DestinationService();
    selectedCategory = widget.initialCategory;
    _loadDestinations();
  }

  @override
  void dispose() {
    FavoriteDestinationService.revision.removeListener(_onFavoritesChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDestinations() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _destinations = const [];
    });
    try {
      final loaded = await _destinationService.getDestinations();
      if (!mounted) return;
      setState(() {
        _destinations = loaded;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _exploreBackground, body: _exploreBody());
  }

  Widget _exploreBody() {
    final filtered = _destinations.where((destination) {
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
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Wisata',
                style: TextStyle(
                  color: _exploreBodyText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Temukan destinasi wisata yang sesuai dengan keinginanmu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _exploreSecondaryText,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: Text(
                'Sedang mempersiapkan wisata...',
                style: TextStyle(color: _exploreSecondaryText, fontSize: 13),
              ),
            ),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _exploreSecondaryText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loadDestinations,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        if (!_isLoading && _loadError == null && filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Destinasi tidak ditemukan',
                style: TextStyle(color: _exploreSecondaryText, fontSize: 13),
              ),
            ),
          ),
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 238,
              ),
              itemBuilder: (context, index) {
                final destination = filtered[index];
                return DestinationCard(
                  destination: destination,
                  isFavorite: FavoriteDestinationService.contains(
                    destination.id,
                  ),
                  onFavoriteChanged: (_) =>
                      FavoriteDestinationService.toggle(destination),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DestinationDetailPage(destination: destination),
                    ),
                  ),
                );
              },
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
        16,
        MediaQuery.viewPaddingOf(context).top + 10,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_exploreNavy, _exploreRaisedNavy],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jelajahi Wisata',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cari pantai, alam, atau tempat seru lainnya.',
            style: TextStyle(
              color: Color(0xFFCCD8E5),
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3EAF2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: _exploreRaisedNavy,
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: _exploreBodyText,
                      fontSize: 14,
                    ),
                    cursorColor: AppColors.orange,
                    decoration: const InputDecoration(
                      hintText: 'Cari wisata yang anda inginkan',
                      hintStyle: TextStyle(
                        color: _exploreSecondaryText,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Hapus pencarian',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 40,
                    ),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close,
                      color: _exploreSecondaryText,
                      size: 19,
                    ),
                  ),
                IconButton(
                  tooltip: 'Filter destinasi',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 40,
                  ),
                  onPressed: _showFilterDialog,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: _exploreRaisedNavy,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
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
                            color: _exploreNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup filter',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _exploreNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      color: _exploreNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      for (final category in [
                        'Semua',
                        'ALAM',
                        'BAHARI',
                        'BUATAN',
                      ])
                        _FilterChoiceChip(
                          label: category == 'Semua'
                              ? category
                              : _categoryLabel(category),
                          selected: selectedCategory == category,
                          onSelected: () => setDialogState(
                            () => selectedCategory = category,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Urutkan',
                    style: TextStyle(
                      color: _exploreNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      for (final sort in _sortOptions)
                        _FilterChoiceChip(
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
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        (selectedCategory, selectedSort),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _exploreNavy,
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
          (a, b) => _reviewValue(
            b.reviewCount,
          ).compareTo(_reviewValue(a.reviewCount)),
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

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: _exploreNavy,
      side: const BorderSide(color: _exploreNavy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _exploreNavy,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
