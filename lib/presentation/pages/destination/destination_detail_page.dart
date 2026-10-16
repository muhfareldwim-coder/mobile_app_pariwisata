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
import '../../../data/services/route_estimate_service.dart';
import '../../../data/services/ticket_service.dart';
import '../booking/booking_page.dart';
import '../ticket/qr_ticket_page.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({super.key, required this.destination});

  final Destination destination;

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  bool isFavorite = false;
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

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _loadDestinationDetails();
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
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        toolbarHeight: 58,
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        key: const ValueKey('destination-detail-scroll'),
        padding: const EdgeInsets.only(bottom: 22),
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
                _sectionHeading(
                  icon: Icons.verified_outlined,
                  title: 'Tentang Destinasi',
                ),
                const SizedBox(height: 8),
                _descriptionCard(),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Lokasi & rute'),
                const SizedBox(height: 10),
                _locationCard(),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Fasilitas'),
                const SizedBox(height: 9),
                _facilityGrid(),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Jenis tiket'),
                const SizedBox(height: 9),
                if (destination.ticketTypes.isEmpty)
                  const Text(
                    'Jenis tiket belum tersedia.',
                    style: TextStyle(color: Color(0xFF737B88), fontSize: 11),
                  )
                else
                  for (final ticket in destination.ticketTypes)
                    _TicketTypeRow(ticket: ticket),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jelajahi lebih dekat',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _SectionTitle(title: 'Galeri ${destination.name}'),
                        ],
                      ),
                    ),
                    if (destination.gallery.isNotEmpty)
                      TextButton(
                        onPressed: _openGallery,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1264CE),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                _gallery(),
                const SizedBox(height: 24),
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
            const _SectionTitle(title: 'Ulasan pengunjung'),
            const SizedBox(height: 8),
            if (apiReviews.isNotEmpty) ...[
              const SizedBox(height: 9),
              for (final review in apiReviews) ...[
                _ReviewCard(
                  initial: review.name.isEmpty
                      ? '?'
                      : review.name[0].toUpperCase(),
                  name: review.name,
                  meta: 'Ulasan pengunjung',
                  rating: review.rating,
                  review: review.review,
                ),
                if (review != apiReviews.last) const SizedBox(height: 9),
              ],
            ] else if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Belum ada ulasan.',
                  style: TextStyle(color: Color(0xFF737B88), fontSize: 11),
                ),
              )
            else ...[
              const SizedBox(height: 9),
              for (final review in reviews) ...[
                _ReviewCard(
                  initial: review.userName.isEmpty
                      ? '?'
                      : review.userName[0].toUpperCase(),
                  name: review.userName,
                  meta: 'Pembeli tiket terverifikasi',
                  rating: review.rating,
                  review: review.review,
                ),
                if (review != reviews.last) const SizedBox(height: 9),
              ],
            ],
            if (userReview != null) ...[
              const SizedBox(height: 10),
              const _ReviewEligibilityNote(
                icon: Icons.verified_rounded,
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
        icon: Icons.rate_review_outlined,
        message: 'Tiket Anda sudah digunakan. Bagikan pengalaman wisata Anda.',
        actionLabel: 'Tulis ulasan',
        onAction: () => _writeReview(reviewTicket),
      );
    }
    if (ticket != null && ticket.status == 'valid') {
      return _ReviewEligibilityNote(
        icon: Icons.confirmation_number_outlined,
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
                        onTap: () => setState(() => isFavorite = !isFavorite),
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
                          color: AppColors.ocean,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          destination.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        destination.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
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
                                  color: const Color(0x99334956),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  '▣ ${destination.gallery.length} Foto',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1264CE),
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  destination.location,
                  style: const TextStyle(
                    color: Color(0xFF606977),
                    height: 1.4,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: isDescriptionExpanded ? null : 4,
            overflow: isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4F5663),
              height: 1.55,
              fontSize: 12.5,
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                setState(() => isDescriptionExpanded = !isDescriptionExpanded),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1264CE),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              isDescriptionExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
            ),
            label: Text(
              isDescriptionExpanded ? 'Tutup' : 'Baca Selengkapnya',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                  const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF1264CE),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    destination.openingHours.isEmpty
                        ? 'Jam operasional belum tersedia'
                        : destination.openingHours,
                    style: const TextStyle(
                      color: Color(0xFF606977),
                      fontSize: 11,
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
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFA35B),
                      size: 18,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${destination.rating.toStringAsFixed(1)} (${destination.reviewCount} ulasan)',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
        style: TextStyle(color: Color(0xFF737B88), fontSize: 11),
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
        style: TextStyle(color: Color(0xFF737B88), fontSize: 11),
      );
    }
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: destination.gallery.length,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _isEstimatingRoute ? null : _calculateRouteEstimate,
              icon: _isEstimatingRoute
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.route_outlined, size: 18),
              label: Text(
                _isEstimatingRoute
                    ? 'Menghitung rute...'
                    : _routeEstimate == null
                    ? 'Lihat estimasi jarak & waktu'
                    : 'Perbarui estimasi rute',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          if (_routeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _routeError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 11),
            ),
          ],
          if (route != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HighlightItem(
                    icon: Icons.route_outlined,
                    label: 'Jarak rute',
                    value:
                        '${(route.distanceMeters / 1000).toStringAsFixed(1)} km',
                    color: const Color(0xFF1264CE),
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _HighlightItem(
                    icon: Icons.schedule_rounded,
                    label: 'Estimasi berkendara',
                    value: _formatDuration(durationMinutes),
                    color: AppColors.orange,
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
              child: FilledButton.icon(
                onPressed: _startBooking,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE98600),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: Text(
                  AuthService.currentUser == null
                      ? 'Masuk untuk memesan'
                      : 'Pesan tiket',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading({required IconData icon, required String title}) =>
      Row(
        children: [
          Icon(icon, color: const Color(0xFF1264CE), size: 18),
          const SizedBox(width: 7),
          _SectionTitle(title: title),
        ],
      );

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
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
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
  const _HighlightItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F1FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(color: Color(0xFF707782), fontSize: 9),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 11,
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
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ticket.name,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Rp ${ticket.price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF2FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF1264CE), size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1264CE),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.initial,
    required this.name,
    required this.meta,
    required this.rating,
    required this.review,
  });
  final String initial;
  final String name;
  final String meta;
  final int rating;
  final String review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFDDE4FF),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: Color(0xFF737B88),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFA35B),
                    size: 13,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          '"$review"',
          style: const TextStyle(
            color: Color(0xFF59616E),
            height: 1.45,
            fontSize: 10.5,
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
