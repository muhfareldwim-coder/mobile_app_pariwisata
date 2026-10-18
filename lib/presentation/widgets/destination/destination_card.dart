import 'package:flutter/material.dart';

import '../../../data/models/destination.dart';

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
    const navy = Color(0xFF12304A);
    const gold = Color(0xFFFFC22F);

    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (destination.imageUrl != null)
              Image.network(
                destination.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImageFallback(color: navy),
              )
            else
              const _ImageFallback(color: navy),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.2, 1],
                  colors: [Colors.transparent, Color(0xF0091F39)],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _ImageBadge(
                label: _titleCase(destination.category),
                color: const Color(0xCC12304A),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: const Color(0x99091F39),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: isFavorite
                      ? 'Hapus dari favorit'
                      : 'Tambah ke favorit',
                  onPressed: onFavoriteChanged == null
                      ? null
                      : () => onFavoriteChanged!(!isFavorite),
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? const Color(0xFFFF6B81) : Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 11,
              right: 11,
              bottom: 11,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: gold, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        destination.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '(${destination.reviewCount})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD8E2EF),
                            fontSize: 9,
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
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: gold,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          destination.location.replaceFirst(
                            ', Kabupaten Jember',
                            ', Jember',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD8E2EF),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Divider(height: 1, color: Color(0x40FFFFFF)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mulai dari',
                          style: TextStyle(
                            color: Color(0xFFD8E2EF),
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${_formatPrice(destination.ticketPrice)}',
                        style: const TextStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

  String _titleCase(String value) =>
      value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();
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
