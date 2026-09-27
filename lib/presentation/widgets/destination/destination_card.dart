import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/destination.dart';
import 'facility_chip.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  final Destination destination;
  final VoidCallback? onTap;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final categoryColor = switch (destination.category) {
      'BAHARI' => AppColors.ocean,
      'BUATAN' => AppColors.orange,
      _ => AppColors.leaf,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: const Color(0x1608233F),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 178,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (destination.imageUrl != null)
                    Image.network(
                      destination.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _ImageFallback(color: categoryColor),
                    )
                  else
                    _ImageFallback(color: categoryColor),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x50000000),
                          Colors.transparent,
                          Color(0xB8000000),
                        ],
                        stops: [0, .42, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 13,
                    top: 13,
                    child: Row(
                      children: [
                        _ImageBadge(
                          label: destination.category,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 7),
                        _ImageBadge(
                          label:
                              '${destination.distanceKm.toStringAsFixed(1)} km',
                          color: const Color(0xAA172B3A),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 10,
                    child: Material(
                      color: const Color(0x77000000),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: isFavorite
                            ? 'Hapus dari favorit'
                            : 'Tambah ke favorit',
                        visualDensity: VisualDensity.compact,
                        onPressed: onFavoriteChanged == null
                            ? null
                            : () => onFavoriteChanged!(!isFavorite),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.orange : Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 100,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 13,
                              color: Color(0xFFFFC36B),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                destination.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 13,
                    child: _ImageBadge(
                      label:
                          '★ ${destination.rating.toStringAsFixed(1)}  (${destination.reviewCount})',
                      color: const Color(0xCC172B3A),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      children: [
                        for (final facility in destination.facilities)
                          FacilityChip(label: facility),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  SizedBox(
                    width: 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Tiket Masuk',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${_formatPrice(destination.ticketPrice)}',
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          '/orang',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color.withValues(alpha: .72),
    child: const Center(
      child: Icon(Icons.landscape_rounded, color: Colors.white70, size: 48),
    ),
  );
}
