import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/destination_data.dart';
import '../../../data/models/destination.dart';
import '../../widgets/bottom_navigation.dart';
import '../article_detail_page.dart';
import '../destination/destination_detail_page.dart';
import '../destination/explorer_page.dart';
import '../map/map_page.dart';
import '../profile/profile_page.dart';
import '../ticket/my_ticket_page.dart';

const _deepNavy = Color(0xFF091F39);
const _raisedNavy = Color(0xFF123B78);
const _softGold = Color(0xFFFFC22F);
const _pageBackground = Color(0xFFF6F8FB);
const _bodyText = Color(0xFF132C49);
const _secondaryText = Color(0xFF8492A5);

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onTabSelected, this.onCategorySelected});

  final ValueChanged<int>? onTabSelected;
  final ValueChanged<String>? onCategorySelected;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _favoriteDestinationIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final nearestDestinations = [...destinations]
      ..sort((first, second) => first.distanceKm.compareTo(second.distanceKm));
    final popularDestinations = [...destinations]
      ..sort(
        (first, second) =>
            _reviewCountValue(second.reviewCount)
                .compareTo(_reviewCountValue(first.reviewCount)),
      );
    final homeDestinations = nearestDestinations.take(3).toList();
    final homePopularDestinations = popularDestinations.take(3).toList();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(
              key: const ValueKey('home-header'),
              onProfileTap: () => _openTab(context, 4),
              onFavoriteTap: () => _openExplorer(context),
              onNotificationsTap: () => _openTab(context, 3),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('home-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                children: [
                  _HeroBanner(onExploreTap: () => _openExplorer(context)),
                  const SizedBox(height: 20),
                  _SectionHeading(
                    title: 'Kategori Wisata',
                    subtitle: 'Pilih ragam destinasi unggulan',
                    action: 'Semua',
                    onAction: () => _openExplorer(context),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CategoryItem(
                        icon: Icons.forest_rounded,
                        label: 'Alam',
                        count: '1 Destinasi',
                        color: const Color(0xFF287B61),
                        softColor: const Color(0xFFE7F4ED),
                        onTap: () => _openCategory(context, 'ALAM'),
                      ),
                      const SizedBox(width: 9),
                      _CategoryItem(
                        icon: Icons.waves_rounded,
                        label: 'Bahari',
                        count: '3 Destinasi',
                        color: const Color(0xFF2676B5),
                        softColor: const Color(0xFFE8F3FC),
                        onTap: () => _openCategory(context, 'BAHARI'),
                      ),
                      const SizedBox(width: 9),
                      _CategoryItem(
                        icon: Icons.attractions_rounded,
                        label: 'Buatan',
                        count: '2 Destinasi',
                        color: const Color(0xFFB76A1C),
                        softColor: const Color(0xFFFFF1DF),
                        onTap: () => _openCategory(context, 'BUATAN'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'Destinasi Populer',
                    subtitle: 'Paling banyak mendapat ulasan wisatawan',
                    action: 'Lihat Semua',
                    onAction: () => _openExplorer(context),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 330,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: homePopularDestinations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        width: 240,
                        child: _DestinationCard(
                          key: ValueKey(
                            'popular-destination-${homePopularDestinations[index].id}',
                          ),
                          destination: homePopularDestinations[index],
                          isFavorite: _favoriteDestinationIds.contains(
                            homePopularDestinations[index].id,
                          ),
                          onFavoriteTap: () => setState(() {
                            final id = homePopularDestinations[index].id;
                            if (!_favoriteDestinationIds.add(id)) {
                              _favoriteDestinationIds.remove(id);
                            }
                          }),
                          onTap: () => _openDestinationDetail(
                            context,
                            homePopularDestinations[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'Destinasi Terdekat',
                    subtitle: 'Pilihan wisata dengan jarak terdekat',
                    action: 'Lihat Semua',
                    onAction: () => _openExplorer(context),
                  ),
                  const SizedBox(height: 10),
                  for (final destination in homeDestinations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _NearbyDestinationTile(
                        destination: destination,
                        onTap: () =>
                            _openDestinationDetail(context, destination),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _ArticlesSection(
                    onExploreTap: () => _openExplorer(context),
                    onArticleTap: (article) => _openPage(
                      context,
                      ArticleDetailPage(
                        article: article,
                        onCategorySelected: (category) =>
                            _openCategory(context, category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.onTabSelected == null
          ? AppBottomNavigation(
              selectedIndex: 0,
              onSelected: (index) => _openTab(context, index),
            )
          : null,
    );
  }

  void _openExplorer(BuildContext context) {
    _openTab(context, 1);
  }

  void _openCategory(BuildContext context, String category) {
    final onCategorySelected = widget.onCategorySelected;
    if (onCategorySelected != null) {
      onCategorySelected(category);
      return;
    }
    _openPage(context, ExplorerPage(initialCategory: category));
  }

  void _openDestinationDetail(BuildContext context, Destination destination) {
    _openPage(context, DestinationDetailPage(destination: destination));
  }

  void _openTab(BuildContext context, int index) {
    final onTabSelected = widget.onTabSelected;
    if (onTabSelected != null) {
      onTabSelected(index);
      return;
    }
    final page = switch (index) {
      1 => const ExplorerPage(),
      2 => const MapPage(),
      3 => const MyTicketPage(),
      4 => const ProfilePage(),
      _ => null,
    };
    if (page != null) _openPage(context, page);
  }

  static void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    super.key,
    required this.onProfileTap,
    required this.onFavoriteTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepNavy, Color(0xFF133D62)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x30091F39),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _BrandMark(),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• JELAJAH JEMBER',
                      style: TextStyle(
                        color: _softGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Halo, Petualang! 🌿',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderAction(
                icon: Icons.favorite_border_rounded,
                tooltip: 'Favorit',
                onTap: onFavoriteTap,
              ),
              const SizedBox(width: 6),
              _HeaderAction(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifikasi',
                showBadge: true,
                onTap: onNotificationsTap,
              ),
              const SizedBox(width: 7),
              Tooltip(
                message: 'Profil',
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(50),
                  child: const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFFFE4B3),
                    child: Icon(
                      Icons.person_rounded,
                      color: _raisedNavy,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Image.asset(
        'assets/logo_jembergonobackgroud.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppColors.white, size: 17),
                if (showBadge)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
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
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 176,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/jembergo_home_hero.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: _raisedNavy,
                child: const Icon(
                  Icons.landscape_outlined,
                  color: AppColors.white,
                  size: 48,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0A091F39),
                    Color(0x55091F39),
                    Color(0xE6091F39),
                  ],
                  stops: [0.12, 0.50, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xB51C3E5B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Kab. Jember',
                  style: TextStyle(
                    color: Color(0xFFE1EAF3),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: _softGold,
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'EKSPLORASI EKSOTIS',
                        style: TextStyle(
                          color: _softGold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pesona Kota Karnaval,\nTembakau & Surga Selatan',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 9),
                  FilledButton.icon(
                    onPressed: onExploreTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(0, 31),
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                    label: const Text(
                      'Jelajahi Sekarang',
                      style: TextStyle(fontSize: 10),
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
}

class _ArticlesSection extends StatelessWidget {
  const _ArticlesSection({
    required this.onExploreTap,
    required this.onArticleTap,
  });

  final VoidCallback onExploreTap;
  final ValueChanged<NewsArticle> onArticleTap;

  @override
  Widget build(BuildContext context) {
    const jfcArticle = NewsArticle(
      imageAsset: 'assets/jembergo_article_jfc.png',
      category: 'Transportasi & Acara',
      meta: 'Jember Event  •  5 menit baca',
      title: 'Jadwal & Rute Shuttle Wisata Jember Fashion Carnival (JFC) 2026',
      summary: 'Pemerintah Kabupaten Jember menyediakan akses transportasi terpadu untuk memudahkan mobilitas.',
      sections: [
        'Jember Fashion Carnival kembali menghadirkan rangkaian pertunjukan kostum spektakuler di pusat Kota Jember. Untuk membantu pengunjung menikmati acara dengan nyaman, layanan shuttle wisata disiapkan dari sejumlah titik parkir dan pusat keramaian.',
        'Datang lebih awal, periksa informasi titik naik shuttle sebelum berangkat, dan ikuti arahan petugas di lapangan. Jadwal operasional dapat berubah mengikuti pengaturan lalu lintas dan agenda resmi acara.',
        'Sesudah acara, lanjutkan perjalanan dengan menjelajahi destinasi alam, pantai, dan taman wisata di Kabupaten Jember.',
      ],
    );
    const stayArticle = NewsArticle(
      imageAsset: 'assets/jembergo_article_homestay.png',
      category: 'Tips & Panduan',
      meta: 'Panduan Petualang  •  3 menit baca',
      title: '5 Panduan Booking Homestay & Destinasi Wisata Tanpa Boncos',
      summary: 'Simak cara memanfaatkan paket liburan awal musim dan spot wisata ramah keluarga di sekitar Kabupaten Jember.',
      sections: [
        'Rencanakan perjalanan sebelum memesan penginapan. Tentukan area yang paling dekat dengan tujuan utama agar waktu dan biaya perjalanan tetap terukur.',
        'Bandingkan fasilitas, aturan pembatalan, serta ulasan terbaru. Untuk liburan keluarga, pastikan akses kendaraan, jam check-in, dan fasilitas anak tersedia.',
        'Susun itinerary yang realistis. Gabungkan destinasi yang berada di area berdekatan dan sisakan waktu untuk beristirahat.',
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            title: 'Berita & Panduan Wisata',
            subtitle: 'Informasi acara, cerita, dan tips berwisata',
            action: 'Lihat Semua',
            onAction: onExploreTap,
          ),
          const SizedBox(height: 10),
          _ArticleCard(
            imageAsset: jfcArticle.imageAsset,
            tag: jfcArticle.category,
            meta: jfcArticle.meta,
            title: jfcArticle.title,
            summary: jfcArticle.summary,
            footer: 'Terbit Terkini',
            onTap: () => onArticleTap(jfcArticle),
          ),
          const SizedBox(height: 10),
          _ArticleCard(
            imageAsset: stayArticle.imageAsset,
            tag: stayArticle.category,
            meta: stayArticle.meta,
            title: stayArticle.title,
            summary: stayArticle.summary,
            footer: 'Tips Lokal',
            onTap: () => onArticleTap(stayArticle),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.imageAsset,
    required this.tag,
    required this.meta,
    required this.title,
    required this.summary,
    required this.footer,
    required this.onTap,
  });

  final String imageAsset;
  final String tag;
  final String meta;
  final String title;
  final String summary;
  final String footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5EAF0)),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A14304B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 142,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(imageAsset, fit: BoxFit.cover),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xD9163858),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _bodyText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE9EDF2)),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            footer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Baca Selengkapnya →',
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 9,
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
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    required this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _bodyText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: _raisedNavy,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 17),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [softColor, Colors.white, Colors.white],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A14304B),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, softColor],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.13)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _bodyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
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
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final Destination destination;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _deepNavy,
      borderRadius: BorderRadius.circular(18),
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
                errorBuilder: (_, _, _) => _destinationImageFallback(),
              )
            else
              _destinationImageFallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.25, 1],
                  colors: [Colors.transparent, Color(0xF0091F39)],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xD91B4567),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _titleCase(destination.category),
                  style: const TextStyle(
                    color: Color(0xFFE4F0F9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: const Color(0x99091F39),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: isFavorite
                      ? 'Hapus ${destination.name} dari favorit'
                      : 'Tambahkan ${destination.name} ke favorit',
                  onPressed: onFavoriteTap,
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
                    size: 19,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: _softGold,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        destination.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _softGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '(${destination.reviewCount})',
                        style: const TextStyle(
                          color: Color(0xFFD8E2EF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _softGold,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          destination.location.replaceFirst(
                            ', Kabupaten Jember',
                            ', Jember',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB8CCDF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0x40FFFFFF)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mulai dari',
                          style: TextStyle(
                            color: Color(0xFFB8CCDF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${_formatHomePrice(destination.ticketPrice)}',
                        style: const TextStyle(
                          color: _softGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
}

class _NearbyDestinationTile extends StatelessWidget {
  const _NearbyDestinationTile({
    required this.destination,
    required this.onTap,
  });

  final Destination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE5EAF0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 66,
                  height: 66,
                  child: destination.imageUrl == null
                      ? _destinationImageFallback(24)
                      : Image.network(
                          destination.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _destinationImageFallback(24),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _bodyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destination.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${destination.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _destinationImageFallback([double iconSize = 36]) => ColoredBox(
  color: _raisedNavy,
  child: Center(
    child: Icon(Icons.landscape_outlined, color: _softGold, size: iconSize),
  ),
);

String _formatHomePrice(int price) => price.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

double _reviewCountValue(String reviewCount) {
  final normalized = reviewCount.trim().toLowerCase();
  final count = double.tryParse(normalized.replaceFirst('k', ''));
  if (count == null) return 0;
  return normalized.endsWith('k') ? count * 1000 : count;
}

String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0]}${value.substring(1).toLowerCase()}';
