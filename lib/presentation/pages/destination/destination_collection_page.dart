import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/destination_service.dart';

enum DestinationCollectionSection { gallery, reviews }

class DestinationCollectionPage extends StatefulWidget {
  const DestinationCollectionPage({
    super.key,
    required this.destination,
    required this.section,
    this.destinationService,
  });

  final Destination destination;
  final DestinationCollectionSection section;
  final DestinationService? destinationService;

  @override
  State<DestinationCollectionPage> createState() =>
      _DestinationCollectionPageState();
}

class _DestinationCollectionPageState extends State<DestinationCollectionPage> {
  late Destination _destination;
  late final DestinationService _destinationService;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _destinationService = widget.destinationService ?? DestinationService();
  }

  Future<void> _refreshDestination() async {
    try {
      final destination = await _destinationService.getDestination(
        _destination.id,
      );
      if (mounted) setState(() => _destination = destination);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Destinasi gagal diperbarui: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGallery = widget.section == DestinationCollectionSection.gallery;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isGallery ? 'Galeri ${_destination.name}' : 'Ulasan pengunjung',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDestination,
        child: isGallery ? _gallery() : _reviews(),
      ),
    );
  }

  Widget _gallery() {
    if (_destination.gallery.isEmpty) {
      return _emptyContent('Galeri destinasi belum tersedia.');
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _destination.gallery.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final photo = _destination.gallery[index];
        final caption = photo.caption?.trim().isNotEmpty == true
            ? photo.caption!.trim()
            : 'Foto destinasi';
        return Semantics(
          button: true,
          label: 'Buka $caption',
          child: GestureDetector(
            onTap: () => _openGallery(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photo.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFE8EDF3),
                      child: Center(
                        child: Text(
                          'Foto tidak tersedia',
                          style: TextStyle(color: Color(0xFF8190A5)),
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB8000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _reviews() {
    final reviews = _destination.reviews;
    if (reviews.isEmpty) {
      return _emptyContent('Belum ada ulasan.');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _ReviewCard(
          name: review.name,
          meta: 'Ulasan pengunjung',
          rating: review.rating,
          review: review.review,
        );
      },
    );
  }

  Widget _emptyContent(String message) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF8190A5), fontSize: 14),
          ),
        ),
      ),
    ],
  );

  Future<void> _openGallery(BuildContext context, int initialIndex) =>
      showDialog<void>(
        context: context,
        builder: (_) => _GalleryViewer(
          photos: _destination.gallery,
          initialIndex: initialIndex,
        ),
      );
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.photos, required this.initialIndex});

  final List<DestinationGallery> photos;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: Stack(
      alignment: Alignment.topRight,
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.photos[index].url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE8EDF3),
                  child: Center(child: Text('Foto tidak tersedia')),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: localized('Tutup galeri'),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.meta,
    required this.rating,
    required this.review,
  });

  final String name;
  final String meta;
  final int rating;
  final String review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8EDF3)),
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
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: Color(0xFF8190A5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$rating/5',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          review,
          style: const TextStyle(
            color: Color(0xFF465568),
            height: 1.55,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
