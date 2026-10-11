import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/ticket.dart';
import '../../../data/models/user.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/device_location_service.dart';
import '../../../data/services/destination_review_service.dart';
import '../../../data/services/open_street_map_service.dart';
import '../../../data/services/ticket_service.dart';
import '../booking/booking_page.dart';
import '../ticket/qr_ticket_page.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({
    super.key,
    required this.destination,
  });

  final Destination destination;

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  bool isFavorite = false;
  bool isDescriptionExpanded = false;

  Destination get destination => widget.destination;

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

  Future<void> _openOpenStreetMap() async {
    var origin = DeviceLocationService.jemberFallback;
    try {
      final currentLocation = await DeviceLocationService.currentLocation();
      if (currentLocation == null && mounted) {
        _showMessage(
          'Lokasi tidak tersedia. Rute dimulai dari Alun-alun Jember.',
        );
      } else if (currentLocation != null) {
        origin = currentLocation;
      }
    } on Exception {
      if (mounted) {
        _showMessage(
          'Lokasi perangkat tidak tersedia. Rute dimulai dari Alun-alun Jember.',
        );
      }
    }
    if (!mounted) return;
    final opened = await OpenStreetMapService.openDirections(
      fromLatitude: origin.latitude,
      fromLongitude: origin.longitude,
      toLatitude: destination.latitude,
      toLongitude: destination.longitude,
    );
    if (!opened && mounted) {
      _showMessage('OpenStreetMap tidak dapat dibuka.');
    }
  }

  static const _galleryImages = [
    'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=85',
    'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=800&q=85',
    'https://images.unsplash.com/photo-1506953823976-52e1fdc0149a?auto=format&fit=crop&w=800&q=85',
  ];

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
        title: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'J',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'Detail',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.navy,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Profil',
                onPressed: () {},
                icon: const Icon(
                  Icons.person_outline,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          _heroAndHighlights(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 19, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  icon: Icons.verified_outlined,
                  title: 'Pesona & Deskripsi',
                ),
                const SizedBox(height: 8),
                _descriptionCard(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(title: 'Fasilitas Wisata'),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1264CE),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lengkap & Nyaman',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _facilityGrid(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(title: 'Galeri Suasana'),
                    ),
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
                const _SectionTitle(title: 'Lokasi & Akses'),
                const SizedBox(height: 10),
                _locationCard(),
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
            const _SectionTitle(title: 'Ulasan Wisatawan'),
            const SizedBox(height: 8),
            if (userReview == null)
              _reviewEligibilityPanel(
                user: user,
                ticket: ticket,
                reviewTicket: reviewTicket,
              )
            else
              const _ReviewEligibilityNote(
                icon: Icons.verified_rounded,
                message: 'Terima kasih! Ulasan Anda sudah tercatat sebagai pengunjung terverifikasi.',
              ),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Belum ada ulasan terverifikasi untuk destinasi ini.',
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
          ],
        );
      },
    ),
  );

  Widget _reviewEligibilityPanel({
    required User? user,
    required Ticket? ticket,
    required Ticket? reviewTicket,
  }) {
    if (user == null) {
      return _ReviewEligibilityNote(
        icon: Icons.lock_outline_rounded,
        message:
            'Masuk dengan akun pembeli tiket untuk memberi rating dan ulasan.',
        actionLabel: 'Masuk',
        onAction: _loginForReview,
      );
    }
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
    return const _ReviewEligibilityNote(
      icon: Icons.lock_outline_rounded,
      message: 'Rating dan ulasan hanya dapat dikirim setelah membeli dan menggunakan tiket destinasi ini.',
    );
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

  Widget _heroAndHighlights() {
    final heroHeight = (MediaQuery.sizeOf(context).width * .78).clamp(
      285.0,
      330.0,
    );
    return SizedBox(
      height: heroHeight + 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImage(url: destination.imageUrl, iconSize: 58),
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
                      const SizedBox(width: 7),
                      _HeroAction(
                        icon: Icons.share_outlined,
                        tooltip: 'Bagikan destinasi',
                        onTap: _shareDestination,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 37,
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
                          'WISATA ${destination.category}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        destination.name.replaceFirst('Pantai ', ''),
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
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFA35B),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            destination.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '(${destination.reviewCount} ulasan)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
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
                                '▣ 1/${_galleryImages.length} Foto',
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
          Positioned(left: 16, right: 16, bottom: 0, child: _highlightCard()),
        ],
      ),
    );
  }

  Widget _highlightCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1408233F),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _HighlightItem(
              icon: Icons.place_outlined,
              label: 'Jarak',
              value: '${destination.distanceKm.toStringAsFixed(1)} km',
              color: const Color(0xFF1264CE),
            ),
          ),
          const _VerticalDivider(),
          const Expanded(
            child: _HighlightItem(
              icon: Icons.schedule_rounded,
              label: 'Jam Buka',
              value: '24 Jam',
              color: AppColors.orange,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _HighlightItem(
              icon: Icons.confirmation_number_outlined,
              label: 'Tiket Masuk',
              value: 'Rp ${_formatPrice(destination.ticketPrice)}',
              color: const Color(0xFF1264CE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard() {
    final description = destination.description.isEmpty
        ? 'Nikmati suasana dan keindahan alam Jember di ${destination.name}. Temukan pengalaman wisata yang nyaman bersama keluarga maupun teman.'
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
        ],
      ),
    );
  }

  Widget _facilityGrid() {
    final facilities = _facilityItems;
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
      itemBuilder: (context, index) =>
          _FacilityCard(facility: facilities[index]),
    );
  }

  List<_Facility> get _facilityItems {
    final values = destination.facilities.map(_facilityFromLabel).toList();
    const defaults = [
      _Facility('Toilet & Bilas', 'Air tawar bersih', Icons.wc_rounded),
      _Facility('Gazebo Santai', 'Area beristirahat', Icons.cabin_outlined),
      _Facility('Mushola', 'Tempat ibadah', Icons.mosque_outlined),
      _Facility('Spot Foto', 'Pemandangan indah', Icons.photo_camera_outlined),
      _Facility('Area Kuliner', 'Makanan lokal', Icons.restaurant_outlined),
      _Facility('Parkir Luas', 'Bus & kendaraan', Icons.local_parking_rounded),
    ];
    for (final item in defaults) {
      if (values.length >= 6) break;
      if (!values.any((value) => value.title == item.title)) values.add(item);
    }
    return values.take(6).toList();
  }

  _Facility _facilityFromLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('parkir')) {
      return _Facility(label, 'Bus & kendaraan', Icons.local_parking_rounded);
    }
    if (normalized.contains('resto') ||
        normalized.contains('cafe') ||
        normalized.contains('pujasera')) {
      return _Facility(label, 'Kuliner sekitar', Icons.restaurant_outlined);
    }
    if (normalized.contains('camp')) {
      return _Facility(label, 'Tenda & api unggun', Icons.terrain_rounded);
    }
    if (normalized.contains('kolam') || normalized.contains('water')) {
      return _Facility(label, 'Area bermain air', Icons.pool_rounded);
    }
    if (normalized.contains('foto') || normalized.contains('sunrise')) {
      return _Facility(label, 'Pemandangan indah', Icons.photo_camera_outlined);
    }
    if (normalized.contains('trekking') ||
        normalized.contains('air pegunungan')) {
      return _Facility(label, 'Jalur petualangan', Icons.hiking_rounded);
    }
    if (normalized.contains('flora') || normalized.contains('fauna')) {
      return _Facility(label, 'Wisata edukasi', Icons.park_outlined);
    }
    return _Facility(
      label,
      'Fasilitas tersedia',
      Icons.check_circle_outline_rounded,
    );
  }

  Widget _gallery() {
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _galleryImages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * .46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImage(url: _galleryImages[index], iconSize: 34),
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
                    index == 0 ? 'Siti Hinggil' : 'Pesisir Jember',
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
              height: 160,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CustomPaint(
                    size: Size(double.infinity, 160),
                    painter: _LocationMapPainter(),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0863C6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40000000), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: Text(
                      'PESISIR JEMBER',
                      style: TextStyle(
                        color: Color(0xFF5B8079),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 11,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'Papuma',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1264CE),
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alamat Lengkap',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${destination.location}\nKabupaten Jember, Jawa Timur',
                      style: const TextStyle(
                        color: Color(0xFF606977),
                        height: 1.4,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 39,
            child: FilledButton.icon(
              onPressed: _openOpenStreetMap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE9EDFF),
                foregroundColor: const Color(0xFF075FC7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.directions_outlined, size: 17),
              label: const Text(
                'Buka lokasi di OpenStreetMap',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
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
                    'Total Tarif',
                    style: TextStyle(color: Color(0xFF5F6672), fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_formatPrice(destination.ticketPrice)}',
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
                label: const Text(
                  'Beli Tiket Sekarang',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _NetworkImage(
                  url: destination.imageUrl ?? _galleryImages.first,
                  iconSize: 50,
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

  Future<void> _shareDestination() async {
    await Clipboard.setData(
      ClipboardData(text: 'JemberGo: ${destination.name}'),
    );
    _showMessage('Nama destinasi disalin untuk dibagikan');
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

class _Facility {
  const _Facility(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.facility});
  final _Facility facility;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDFF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(facility.icon, color: AppColors.navy, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                facility.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                facility.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF737B88), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
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

class _LocationMapPainter extends CustomPainter {
  const _LocationMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFD6EBDD), BlendMode.src);
    final sea = Path()
      ..moveTo(0, size.height * .58)
      ..cubicTo(
        size.width * .16,
        size.height * .45,
        size.width * .2,
        size.height * .72,
        size.width * .38,
        size.height * .66,
      )
      ..cubicTo(
        size.width * .53,
        size.height * .58,
        size.width * .63,
        size.height * .82,
        size.width * .73,
        size.height * .73,
      )
      ..lineTo(size.width * .73, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(sea, Paint()..color = const Color(0xFF88C7D6));
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFEF5)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final roads = [
      Path()
        ..moveTo(-8, size.height * .25)
        ..cubicTo(
          size.width * .28,
          size.height * .12,
          size.width * .42,
          size.height * .47,
          size.width + 8,
          size.height * .28,
        ),
      Path()
        ..moveTo(size.width * .12, -5)
        ..cubicTo(
          size.width * .35,
          size.height * .4,
          size.width * .5,
          size.height * .48,
          size.width * .86,
          size.height + 5,
        ),
      Path()
        ..moveTo(-5, size.height * .43)
        ..cubicTo(
          size.width * .36,
          size.height * .34,
          size.width * .62,
          size.height * .6,
          size.width + 5,
          size.height * .55,
        ),
    ];
    for (final path in roads) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFC6C4AD)
          ..strokeWidth = .7
          ..style = PaintingStyle.stroke,
      );
    }
    final parkPaint = Paint()..color = const Color(0xFFB7D9B7);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .58,
        size.height * .05,
        size.width * .3,
        size.height * .2,
      ),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .08,
        size.height * .05,
        size.width * .26,
        size.height * .19,
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
