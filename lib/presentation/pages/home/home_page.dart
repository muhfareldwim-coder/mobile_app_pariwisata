import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../destination/explorer_page.dart';
import '../profile/profile_page.dart';
import '../ticket/my_ticket_page.dart';

const _deepNavy = Color(0xFF091F39);
const _raisedNavy = Color(0xFF123B78);
const _softGold = Color(0xFFFFC22F);
const _pageBackground = Color(0xFFF6F8FB);
const _bodyText = Color(0xFF132C49);
const _secondaryText = Color(0xFF8492A5);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _destinations = [
    _DestinationPreview(
      name: 'Air Terjun Tancak',
      category: 'Alam',
      location: 'Desa Suci, Panti, Jember',
      imageAsset: 'assets/jembergo_tancak.jpg',
    ),
    _DestinationPreview(
      name: 'Kali Jompo',
      category: 'Alam',
      location: 'Kecamatan Semboro, Jember',
      imageAsset: 'assets/jembergo_kali_jompo.jpg',
    ),
    _DestinationPreview(
      name: 'Pantai Papuma',
      category: 'Bahari',
      location: 'Desa Lojejer, Wuluhan, Jember',
      imageAsset: 'assets/jembergo_papuma.jpg',
    ),
    _DestinationPreview(
      name: 'Teluk Love',
      category: 'Bahari',
      location: 'Ambulu, Jember',
      imageAsset: 'assets/jembergo_teluk_love.jpg',
    ),
    _DestinationPreview(
      name: 'Taman Botani',
      category: 'Buatan',
      location: 'Jl. Mujahir, Sukorambi, Jember',
      imageAsset: 'assets/jembergo_taman_botani.jpg',
    ),
  ];

  static const _popularOrder = [2, 3, 0, 1, 4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(
              key: const ValueKey('home-header'),
              onSearchTap: () => _openExplorer(context),
              onProfileTap: () => _openPage(context, const ProfilePage()),
              onFavoriteTap: () => _openExplorer(context),
              onNotificationsTap: () =>
                  _openPage(context, const MyTicketPage()),
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
                        icon: Icons.terrain_rounded,
                        label: 'Alam',
                        count: '2 Destinasi',
                        selected: true,
                        onTap: () => _openExplorer(context),
                      ),
                      const SizedBox(width: 9),
                      _CategoryItem(
                        icon: Icons.public_rounded,
                        label: 'Bahari',
                        count: '2 Destinasi',
                        onTap: () => _openExplorer(context),
                      ),
                      const SizedBox(width: 9),
                      _CategoryItem(
                        icon: Icons.location_city_rounded,
                        label: 'Buatan',
                        count: '1 Destinasi',
                        onTap: () => _openExplorer(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'Destinasi Populer',
                    subtitle: 'Pilihan wisata Kabupaten Jember',
                    action: 'Lihat Semua',
                    onAction: () => _openExplorer(context),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 278,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularOrder.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        width: 212,
                        child: _DestinationCard(
                          destination: _destinations[_popularOrder[index]],
                          onTap: () => _openExplorer(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'Destinasi Terdekat',
                    subtitle: 'Rekomendasi destinasi di Jember',
                    action: 'Semua',
                    onAction: () => _openExplorer(context),
                  ),
                  const SizedBox(height: 10),
                  for (final destination in _destinations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _NearbyDestinationTile(
                        destination: destination,
                        onTap: () => _openExplorer(context),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _ArticlesSection(onExploreTap: () => _openExplorer(context)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingBottomNavigation(
        onTap: (index) {
          switch (index) {
            case 1:
              _openExplorer(context);
            case 2:
              _openExplorer(context);
            case 3:
              _openPage(context, const MyTicketPage());
            case 4:
              _openPage(context, const ProfilePage());
          }
        },
      ),
    );
  }

  static void _openExplorer(BuildContext context) {
    _openPage(context, const ExplorerPage());
  }

  static void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    super.key,
    required this.onSearchTap,
    required this.onProfileTap,
    required this.onFavoriteTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onSearchTap;
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Cari destinasi',
                  child: Material(
                    color: const Color(0xFF193D5F),
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: onSearchTap,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF365875)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: Color(0xFF80BDD7),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cari pantai, air terjun, bukit...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFC3D0DE),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.filter_alt_rounded,
                      color: AppColors.white,
                      size: 19,
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
  const _ArticlesSection({required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
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
            imageAsset: 'assets/jembergo_article_jfc.png',
            tag: 'Transportasi & Acara',
            meta: 'Jember Event  •  5 menit baca',
            title: 'Jadwal & Rute Shuttle Wisata Jember Fashion Carnival (JFC) 2026',
            summary: 'Pemerintah Kabupaten Jember menyediakan akses transportasi terpadu untuk memudahkan mobilitas.',
            footer: 'Terbit Terkini',
            onTap: onExploreTap,
          ),
          const SizedBox(height: 10),
          _ArticleCard(
            imageAsset: 'assets/jembergo_article_homestay.png',
            tag: 'Tips & Panduan',
            meta: 'Panduan Petualang  •  3 menit baca',
            title: '5 Panduan Booking Homestay & Destinasi Wisata Tanpa Boncos',
            summary: 'Simak cara memanfaatkan paket liburan awal musim dan spot wisata ramah keluarga di sekitar Kabupaten Jember.',
            footer: 'Tips Lokal',
            onTap: onExploreTap,
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
    this.selected = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? _raisedNavy : AppColors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 92,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? const Color(0xFF4F88B7)
                    : const Color(0xFFE4EAF1),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A14304B),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF315A7E)
                        : const Color(0xFFF0F5FB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? _softGold : _raisedNavy,
                    size: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.white : _bodyText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? const Color(0xFFBCD0E3) : _secondaryText,
                    fontSize: 8,
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

class _DestinationPreview {
  const _DestinationPreview({
    required this.name,
    required this.category,
    required this.location,
    required this.imageAsset,
  });

  final String name;
  final String category;
  final String location;
  final String imageAsset;
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination, required this.onTap});

  final _DestinationPreview destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 151,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    destination.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.landscape_outlined,
                        color: _softGold,
                        size: 36,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD91B4567),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        destination.category,
                        style: const TextStyle(
                          color: Color(0xFFE4F0F9),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xCCFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFF6E7F90),
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _bodyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.orange,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Divider(height: 1, color: Color(0xFFE7ECF2)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mulai dari',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _secondaryText, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rp 15.000',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 10,
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
}

class _NearbyDestinationTile extends StatelessWidget {
  const _NearbyDestinationTile({
    required this.destination,
    required this.onTap,
  });

  final _DestinationPreview destination;
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
                child: Image.asset(
                  destination.imageAsset,
                  width: 66,
                  height: 66,
                  fit: BoxFit.cover,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  destination.category,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

class _FloatingBottomNavigation extends StatelessWidget {
  const _FloatingBottomNavigation({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Beranda'),
      (Icons.explore_outlined, 'Jelajah'),
      (Icons.map_outlined, 'Peta'),
      (Icons.confirmation_number_outlined, 'Tiket'),
      (Icons.person_outline_rounded, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 67,
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5EAF0))),
          boxShadow: [
            BoxShadow(
              color: Color(0x12091F39),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _FloatingNavigationItem(
                  icon: items[index].$1,
                  label: items[index].$2,
                  selected: index == 0,
                  onTap: () => onTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavigationItem extends StatelessWidget {
  const _FloatingNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : const Color(0xFF8190A2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, color: color, size: 19),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
