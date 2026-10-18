import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/ticket.dart';
import '../../../data/models/user.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/device_location_service.dart';
import '../../../data/services/destination_service.dart';
import '../../../data/services/destination_review_service.dart';
import '../../../data/services/favorite_destination_service.dart';
import '../../../data/services/route_estimate_service.dart';
import '../../../data/services/ticket_service.dart';
import '../booking/booking_page.dart';
import 'destination_collection_page.dart';
import '../ticket/qr_ticket_page.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({super.key, required this.destination});

  final Destination destination;

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  bool isDescriptionExpanded = false;
  late Destination _destination;
  final _mapController = MapController();
  final _destinationService = DestinationService();
  final _routeEstimateService = RouteEstimateService();
  RouteEstimate? _routeEstimate;
  String? _routeError;
  String? _detailError;
  bool _isEstimatingRoute = false;

  Destination get destination => _destination;
  bool get isFavorite => FavoriteDestinationService.contains(destination.id);

  @override
  void initState() {
    super.initState();
    FavoriteDestinationService.revision.addListener(_onFavoritesChanged);
    _destination = widget.destination;
    _loadDestinationDetails();
  }

  @override
  void dispose() {
    FavoriteDestinationService.revision.removeListener(_onFavoritesChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDestinationDetails() async {
    if (int.tryParse(destination.id) == null) return;
    try {
      final details = await _destinationService.getDestination(destination.id);
      if (!mounted) return;
      setState(() {
        _destination = details;
        _detailError = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _detailError = error.toString());
    }
  }

  Future<void> _calculateRouteEstimate() async {
    if (_isEstimatingRoute) return;
    setState(() {
      _isEstimatingRoute = true;
      _routeError = null;
    });
    try {
      final origin = await DeviceLocationService.currentLocation();
      if (origin == null) {
        throw const FormatException(
          'Lokasi perangkat tidak tersedia. Aktifkan GPS dan izinkan akses lokasi.',
        );
      }
      final estimate = await _routeEstimateService.estimate(
        origin: origin,
        destination: LatLng(destination.latitude, destination.longitude),
      );
      if (!mounted) return;
      setState(() {
        _routeEstimate = estimate;
        _isEstimatingRoute = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || estimate.routePoints.length < 2) return;
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(estimate.routePoints),
            padding: const EdgeInsets.all(32),
            maxZoom: 15,
          ),
        );
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _routeError = error.toString();
        _isEstimatingRoute = false;
        _routeEstimate = null;
      });
    }
  }

  Future<void> _startBooking() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text(
          destination.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        key: const ValueKey('destination-detail-scroll'),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          if (_detailError != null)
            MaterialBanner(
              content: Text('Detail terbaru tidak dapat dimuat: $_detailError'),
              actions: [
                TextButton(
                  onPressed: _loadDestinationDetails,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          _hero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 19, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DetailSectionHeading(title: 'Tentang Destinasi'),
                const SizedBox(height: 10),
                _descriptionCard(),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Lokasi & rute'),
                const SizedBox(height: 10),
                _locationCard(),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Fasilitas'),
                const SizedBox(height: 10),
                _facilityGrid(),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Jenis tiket'),
                const SizedBox(height: 10),
                if (destination.ticketTypes.isEmpty)
                  const Text(
                    'Jenis tiket belum tersedia.',
                    style: TextStyle(color: Color(0xFF8190A5), fontSize: 13),
                  )
                else
                  for (final ticket in destination.ticketTypes)
                    _TicketTypeRow(ticket: ticket),
                const SizedBox(height: 22),
                _DetailSectionHeading(
                  title: 'Galeri ${destination.name}',
                  actionKey: const ValueKey('gallery-see-all'),
                  action: destination.gallery.isNotEmpty ? 'Lihat Semua' : null,
                  onAction: _openAllGallery,
                ),
                const SizedBox(height: 9),
                _gallery(),
                const SizedBox(height: 22),
                _reviewSection(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _purchaseBar(),
    );
  }

  Widget _reviewSection() => ValueListenableBuilder<int>(
    valueListenable: TicketService.revision,
    builder: (context, ticketRevision, child) => ValueListenableBuilder<int>(
      valueListenable: DestinationReviewService.revision,
      builder: (context, reviewRevision, child) {
        final user = AuthService.currentUser;
        final userEmail = user?.email ?? '';
        final reviews = DestinationReviewService.forDestination(destination.id);
        final apiReviews = destination.reviews;
        final userReview = user == null
            ? null
            : DestinationReviewService.byUserForDestination(
                destination.id,
                userEmail,
              );
        final ticket = user == null
            ? null
            : TicketService.tickets
                  .where(
                    (item) =>
                        item.destinationId == destination.id &&
                        item.status == 'valid' &&
                        item.leaderEmail.trim().toLowerCase() ==
                            userEmail.trim().toLowerCase(),
                  )
                  .firstOrNull;
        final allReviews = apiReviews.isNotEmpty
            ? apiReviews
            : reviews
                  .map(
                    (review) => DestinationReviewEntry(
                      name: review.userName,
                      rating: review.rating,
                      review: review.review,
                    ),
                  )
                  .toList();
        final previewReviews = allReviews.take(2).toList();
        final reviewTicket = user == null || userReview != null
            ? null
            : TicketService.tickets
                  .where(
                    (item) =>
                        item.destinationId == destination.id &&
                        item.status == 'used' &&
                        item.leaderEmail.trim().toLowerCase() ==
                            userEmail.trim().toLowerCase(),
                  )
                  .firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailSectionHeading(
              title: 'Ulasan pengunjung',
              actionKey: const ValueKey('reviews-see-all'),
              action: allReviews.isNotEmpty ? 'Lihat Semua' : null,
              onAction: _openAllReviews,
            ),
            const SizedBox(height: 10),
            if (allReviews.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Belum ada ulasan.',
                  style: TextStyle(color: Color(0xFF8190A5), fontSize: 13),
                ),
              )
            else ...[
              for (final review in previewReviews) ...[
                _ReviewCard(
                  name: review.name,
                  meta: apiReviews.isNotEmpty
                      ? 'Ulasan pengunjung'
                      : 'Pembeli tiket terverifikasi',
                  rating: review.rating,
                  review: review.review,
                ),
                if (review != previewReviews.last) const SizedBox(height: 10),
              ],
            ],
            if (userReview != null) ...[
              const SizedBox(height: 10),
              const _ReviewEligibilityNote(
                message: 'Terima kasih! Ulasan Anda sudah tercatat sebagai pengunjung terverifikasi.',
              ),
            ] else if (user != null &&
                (reviewTicket != null || ticket?.status == 'valid')) ...[
              const SizedBox(height: 10),
              _reviewEligibilityPanel(
                user: user,
                ticket: ticket,
                reviewTicket: reviewTicket,
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _reviewEligibilityPanel({
    required User user,
    required Ticket? ticket,
    required Ticket? reviewTicket,
  }) {
    if (reviewTicket != null) {
      return _ReviewEligibilityNote(
        message: 'Tiket Anda sudah digunakan. Bagikan pengalaman wisata Anda.',
        actionLabel: 'Tulis ulasan',
        onAction: () => _writeReview(reviewTicket),
      );
    }
    if (ticket != null && ticket.status == 'valid') {
      return _ReviewEligibilityNote(
        message: 'Rating dan ulasan tersedia setelah tiket digunakan pada hari kunjungan.',
        actionLabel: 'Buka e-tiket',
        onAction: () => _openTicket(ticket),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _loginForReview() async {
    await Navigator.pushNamed(context, AppRoutes.login);
    if (mounted) setState(() {});
  }

  Future<void> _openTicket(Ticket ticket) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => QrTicketPage(ticket: ticket)),
    );
  }

  Future<void> _writeReview(Ticket ticket) async {
    final user = AuthService.currentUser;
    if (user == null) {
      await _loginForReview();
      return;
    }

    final result = await showDialog<(int, String)>(
      context: context,
      builder: (_) => _WriteReviewDialog(destinationName: destination.name),
    );

    if (result == null || !mounted) return;
    try {
      DestinationReviewService.submit(
        destinationId: destination.id,
        ticketId: ticket.id,
        userEmail: user.email,
        userName: user.name,
        rating: result.$1,
        review: result.$2,
      );
    } on StateError {
      _showMessage(
        'Ulasan hanya dapat dikirim dengan tiket yang sudah digunakan.',
      );
    }
  }

  Widget _hero() {
    final heroHeight = (MediaQuery.sizeOf(context).width * .78).clamp(
      285.0,
      330.0,
    );
    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImage(
                  url:
                      destination.imageUrl ??
                      destination.gallery.firstOrNull?.url,
                  iconSize: 58,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x18000000),
                        Colors.transparent,
                        Color(0xE6000000),
                      ],
                      stops: [0, .35, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 14,
                  child: Row(
                    children: [
                      _HeroAction(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        tooltip: isFavorite
                            ? 'Hapus favorit'
                            : 'Simpan favorit',
                        iconColor: isFavorite
                            ? AppColors.orange
                            : AppColors.navy,
                        onTap: () =>
                            FavoriteDestinationService.toggle(destination),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          destination.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        destination.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Spacer(),
                          if (destination.gallery.isNotEmpty)
                            InkWell(
                              onTap: _openGallery,
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xB30C1C2E),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  '${destination.gallery.length} foto',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _descriptionCard() {
    final description = destination.description.isEmpty
        ? 'Deskripsi destinasi belum tersedia.'
        : destination.description;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            destination.location,
            style: const TextStyle(
              color: Color(0xFF68778A),
              height: 1.45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: isDescriptionExpanded ? null : 4,
            overflow: isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF465568),
              height: 1.65,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () =>
                setState(() => isDescriptionExpanded = !isDescriptionExpanded),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navy,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isDescriptionExpanded ? 'Tutup' : 'Baca Selengkapnya',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    destination.openingHours.isEmpty
                        ? 'Jam operasional belum tersedia'
                        : destination.openingHours,
                    style: const TextStyle(
                      color: Color(0xFF68778A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (destination.reviewCount.isNotEmpty &&
                  destination.reviewCount != '0')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(color: Color(0xFF68778A), fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${destination.rating.toStringAsFixed(1)} (${destination.reviewCount} ulasan)',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _facilityGrid() {
    final facilities = destination.facilities;
    if (facilities.isEmpty) {
      return const Text(
        'Belum tersedia.',
        style: TextStyle(color: Color(0xFF8190A5), fontSize: 13),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: facilities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 60,
      ),
      itemBuilder: (context, index) => _FacilityCard(label: facilities[index]),
    );
  }

  Widget _gallery() {
    if (destination.gallery.isEmpty) {
      return const Text(
        'Galeri destinasi belum tersedia.',
        style: TextStyle(color: Color(0xFF8190A5), fontSize: 13),
      );
    }
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: destination.gallery.length.clamp(0, 3),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * .46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImage(
                  url: destination.gallery[index].url,
                  iconSize: 34,
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
                  left: 9,
                  bottom: 8,
                  child: Text(
                    destination.gallery[index].caption?.trim().isNotEmpty ==
                            true
                        ? destination.gallery[index].caption!.trim()
                        : 'Foto destinasi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationCard() {
    final destinationPoint = LatLng(
      destination.latitude,
      destination.longitude,
    );
    final route = _routeEstimate;
    final durationMinutes = route == null
        ? 0
        : (route.durationSeconds / 60 / 5).ceil() * 5;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: FlutterMap(
                key: ValueKey('destination-map-${destination.id}'),
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: destinationPoint,
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mobile_pariwisata',
                  ),
                  if (route != null && route.routePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route.routePoints,
                          color: const Color(0xFF0863C6),
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: destinationPoint,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFF0863C6),
                          size: 42,
                        ),
                      ),
                      if (route != null && route.routePoints.isNotEmpty)
                        Marker(
                          point: route.routePoints.first,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF22A06B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                    showFlutterMapAttribution: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _isEstimatingRoute ? null : _calculateRouteEstimate,
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
                      _routeEstimate == null
                          ? 'Lihat estimasi jarak & waktu'
                          : 'Perbarui estimasi rute',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          if (_routeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _routeError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          if (route != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HighlightItem(
                    label: 'Jarak rute',
                    value:
                        '${(route.distanceMeters / 1000).toStringAsFixed(1)} km',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _HighlightItem(
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

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '$hours jam'
        : '$hours jam $remainingMinutes menit';
  }

  Widget _purchaseBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1608233F),
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Harga tiket mulai',
                    style: TextStyle(color: Color(0xFF5F6672), fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.ticketTypes.isEmpty
                        ? 'Belum tersedia'
                        : 'Rp ${_formatPrice(destination.ticketPrice)}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _startBooking,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AuthService.currentUser == null
                      ? 'Masuk untuk memesan'
                      : 'Pesan tiket',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGallery() async {
    if (destination.gallery.isEmpty) {
      _showMessage('Galeri destinasi belum tersedia.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .72,
              width: double.infinity,
              child: PageView.builder(
                itemCount: destination.gallery.length,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _NetworkImage(
                    url: destination.gallery[index].url,
                    iconSize: 50,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Tutup galeri',
            ),
          ],
        ),
      ),
    );
  }

  void _openAllGallery() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationCollectionPage(
          destination: destination,
          section: DestinationCollectionSection.gallery,
        ),
      ),
    );
  }

  void _openAllReviews() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationCollectionPage(
          destination: destination,
          section: DestinationCollectionSection.reviews,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.navy,
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DetailSectionHeading extends StatelessWidget {
  const _DetailSectionHeading({
    required this.title,
    this.action,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
      if (action != null)
        OutlinedButton(
          key: actionKey,
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3974D8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: Color(0xFF3974D8), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            action!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
    ],
  );
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = AppColors.navy,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .9),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: iconColor, size: 20),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _HighlightItem extends StatelessWidget {
  const _HighlightItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(color: Color(0xFF8190A5), fontSize: 11),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 42, color: const Color(0xFFE5E8F5));
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8EDF3)),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _TicketTypeRow extends StatelessWidget {
  const _TicketTypeRow({required this.ticket});

  final DestinationTicketType ticket;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ticket.name,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Rp ${ticket.price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _WriteReviewDialog extends StatefulWidget {
  const _WriteReviewDialog({required this.destinationName});

  final String destinationName;

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  final _controller = TextEditingController();
  int _selectedRating = 5;
  String? _validationMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Ulas ${widget.destinationName}'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rating Anda'),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  tooltip: '$star bintang',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 40,
                  ),
                  onPressed: () => setState(() => _selectedRating = star),
                  icon: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFA35B),
                  ),
                ),
            ],
          ),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Ceritakan pengalaman Anda',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (_validationMessage != null)
            Text(
              _validationMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (_controller.text.trim().isEmpty) {
            setState(() => _validationMessage = 'Ulasan tidak boleh kosong.');
            return;
          }
          Navigator.pop(context, (_selectedRating, _controller.text.trim()));
        },
        child: const Text('Kirim ulasan'),
      ),
    ],
  );
}

class _ReviewEligibilityNote extends StatelessWidget {
  const _ReviewEligibilityNote({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF3F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
    padding: const EdgeInsets.all(15),
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: Color(0xFF737B88),
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
        const SizedBox(height: 9),
        Text(
          '"$review"',
          style: const TextStyle(
            color: Color(0xFF59616E),
            height: 1.45,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url, required this.iconSize});
  final String? url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (url == null) return _fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => ColoredBox(
    color: const Color(0xFFB8CDD2),
    child: Center(
      child: Icon(Icons.landscape_rounded, color: Colors.white, size: iconSize),
    ),
  );
}
