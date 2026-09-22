import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'explorer_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            _HomeHeader(onLogout: () => _logout(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _ExploreBanner(),
                  SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Kategori Wisata',
                    action: 'Semua',
                    subtitle: 'Pilih ragam destinasi unggulan',
                  ),
                  SizedBox(height: 10),
                  _CategoryRow(),
                  SizedBox(height: 18),
                  _FeatureTabs(),
                  SizedBox(height: 24),
                  _SectionTitle(
                    title: 'Destinasi Populer',
                    action: 'Lihat Semua',
                    subtitle: 'Paling banyak dikunjungi wisatawan pekan ini',
                  ),
                  SizedBox(height: 12),
                  _PopularDestinations(),
                  SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Destinasi Terdekat',
                    action: 'Semua',
                    subtitle: 'Rekomendasi terdekat dari lokasimu',
                  ),
                  SizedBox(height: 12),
                  _NearbyList(),
                  SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Berita & Panduan Wisata',
                    action: 'Lihat Semua',
                    subtitle: 'Informasi acara, akses, & tips berwisata',
                  ),
                  SizedBox(height: 12),
                  _ArticleCard(
                    icon: Icons.directions_bus,
                    label: 'Transportasi & Acara',
                    title: 'Jadwal & Rute Shuttle Wisata Jember Fashion Carnival (JFC) 2026',
                    color: Color(0xFF0E6658),
                    imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=900&q=80',
                  ),
                  SizedBox(height: 12),
                  _ArticleCard(
                    icon: Icons.tips_and_updates,
                    label: 'Tips & Panduan',
                    title: '5 Panduan Booking Homestay & Destinasi Wisata Tanpa Boncos',
                    color: AppColors.orange,
                    imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=900&q=80',
                  ),
                  SizedBox(height: 26),
                  _HomeFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeNavigation(),
    );
  }

  void _logout(BuildContext context) => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, AppColors.blueDeep],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset(
                  'assets/logo_jembergonobackgroud.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JELAJAH JEMBER',
                      style: TextStyle(
                        color: AppColors.sky,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Halo, Petualang! 🌿',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(icon: Icons.favorite_border, onPressed: () {}),
              const SizedBox(width: 4),
              _HeaderIconButton(
                icon: Icons.notifications_none,
                onPressed: () {},
                showDot: true,
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(24),
                child: const CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.yellow,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.text, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cari pantai, air terjun, bukit...',
                          style: TextStyle(color: AppColors.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withValues(alpha: .4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune, color: AppColors.dark, size: 21),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.showDot = false,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          if (showDot)
            const Positioned(
              top: 9,
              right: 10,
              child: CircleAvatar(
                radius: 3.5,
                backgroundColor: AppColors.orange,
              ),
            ),
        ],
      ),
    ),
  );
}

class _ExploreBanner extends StatelessWidget {
  const _ExploreBanner();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () =>
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ExplorerPage())),
    child: Container(
      height: 168,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blueDeep, AppColors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.landscape,
              size: 150,
              color: Colors.white.withValues(alpha: .10),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassPill(icon: Icons.location_on, text: 'Kab. Jember'),
                    SizedBox(height: 12),
                    Text(
                      'EKSPLORASI EKSOTIS',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pesona Kota Karnaval,\nTembakau & Surga Selatan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(left: 0, bottom: 0, child: _BannerButton()),
        ],
      ),
    ),
  );
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      border: Border.all(color: Colors.white.withValues(alpha: .3)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BannerButton extends StatelessWidget {
  const _BannerButton();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Jelajahi Sekarang',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 15, color: AppColors.orange),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.subtitle,
  });
  final String title;
  final String action;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.text, fontSize: 11),
            ),
          ],
        ),
      ),
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (title == 'Destinasi Populer') {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ExplorerPage()));
          }
        },
        child: Row(
          children: [
            Text(
              action,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.orange, size: 17),
          ],
        ),
      ),
    ],
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _Category(
        icon: Icons.terrain,
        name: 'Alam',
        count: '14 Destinasi',
        selected: true,
      ),
      _Category(
        icon: Icons.waves,
        name: 'Bahari',
        count: '8 Pantai',
        selected: false,
      ),
      _Category(
        icon: Icons.account_balance,
        name: 'Buatan',
        count: '12 Wahana',
        selected: false,
      ),
    ],
  );
}

class _Category extends StatelessWidget {
  const _Category({
    required this.icon,
    required this.name,
    required this.count,
    required this.selected,
  });
  final IconData icon;
  final String name;
  final String count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF0E7A66), Color(0xFF0D6657)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          border: selected ? null : Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (selected ? const Color(0xFF0D6657) : Colors.black)
                  .withValues(alpha: selected ? .22 : .05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .18)
                    : AppColors.orange.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.orange,
                size: 18,
              ),
            ),
            const Spacer(),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.dark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              count,
              style: TextStyle(
                color: selected ? Colors.white70 : AppColors.text,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTabs extends StatelessWidget {
  const _FeatureTabs();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 10),
      ],
    ),
    child: const Row(
      children: [
        _Feature(
          icon: Icons.map_outlined,
          label: 'Peta',
          color: AppColors.blueDeep,
        ),
        _Feature(
          icon: Icons.confirmation_num_outlined,
          label: 'Tiket',
          color: AppColors.orange,
        ),
        _Feature(
          icon: Icons.favorite,
          label: 'Populer',
          color: Color(0xFFEF4463),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularDestinations extends StatelessWidget {
  const _PopularDestinations();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 278,
    child: ListView(
      scrollDirection: Axis.horizontal,
      primary: false,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      children: const [
        _DestinationCard(
          title: 'Pantai Tanjung Papuma',
          location: 'Wuluhan, Jember',
          rating: '4.9',
          reviews: '3.1k',
          price: 'Rp 25.000',
          badge: 'Bahari',
          color: Color(0xFF2C7A9E),
          icon: Icons.waves,
          imageUrl: 'https://images.unsplash.com/photo-1507523416380-7b7f7f6c2e8b?auto=format&fit=crop&w=700&q=80',
        ),
        _DestinationCard(
          title: 'Teluk Love Payangan',
          location: 'Ambulu, Jember',
          rating: '4.8',
          reviews: '2.4k',
          price: 'Rp 20.000',
          badge: 'Bahari',
          color: Color(0xFF4C7A63),
          icon: Icons.landscape,
          imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=700&q=80',
        ),
      ],
    ),
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.title,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.badge,
    required this.color,
    required this.icon,
    required this.imageUrl,
  });
  final String title;
  final String location;
  final String rating;
  final String reviews;
  final String price;
  final String badge;
  final Color color;
  final IconData icon;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ExplorerPage())),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .07),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 145,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: .75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: .75)],
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white.withValues(alpha: .82),
                            size: 46,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: .42),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 15,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 11,
                            color: AppColors.yellow,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$rating  •  $reviews',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.text,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mulai dari',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 8.5,
                              ),
                            ),
                            Text(
                              price,
                              style: const TextStyle(
                                color: AppColors.blueDeep,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 15,
                          color: Colors.white,
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

class _NearbyList extends StatelessWidget {
  const _NearbyList();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _NearbyItem(
        icon: Icons.water,
        title: 'Pemandian Patemon',
        type: 'Buatan',
        location: 'Tanggul, Kab. Jember',
        distance: '4.2 km',
        price: 'Rp 15.000',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=300&q=80',
      ),
      _NearbyItem(
        icon: Icons.waterfall_chart,
        title: 'Dira Park Ambulu',
        type: 'Buatan',
        location: 'Ambulu, Kab. Jember',
        distance: '6.5 km',
        price: 'Rp 20.000',
        imageUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=300&q=80',
      ),
      _NearbyItem(
        icon: Icons.terrain,
        title: 'Air Terjun Tancak',
        type: 'Alam',
        location: 'Panti, Kab. Jember',
        distance: '12.0 km',
        price: 'Rp 10.000',
        imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=300&q=80',
      ),
    ],
  );
}

class _NearbyItem extends StatelessWidget {
  const _NearbyItem({
    required this.icon,
    required this.title,
    required this.type,
    required this.location,
    required this.distance,
    required this.price,
    required this.imageUrl,
  });
  final IconData icon;
  final String title;
  final String type;
  final String location;
  final String distance;
  final String price;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.blueDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.blue, AppColors.blueDeep],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sky,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: AppColors.blueDeep,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(color: AppColors.text, fontSize: 9),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.star, size: 11, color: AppColors.orange),
                    SizedBox(width: 2),
                    Text(
                      '4.7  (1.1k ulasan)',
                      style: TextStyle(color: AppColors.text, fontSize: 8.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me, size: 11, color: AppColors.text),
                  const SizedBox(width: 3),
                  Text(
                    distance,
                    style: const TextStyle(color: AppColors.text, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.blueDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.color,
    required this.imageUrl,
  });
  final IconData icon;
  final String label;
  final String title;
  final Color color;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 238,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 132,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: .7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: .7)],
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: .85),
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      '5 menit baca',
                      style: TextStyle(color: AppColors.muted, fontSize: 8.5),
                    ),
                    const Spacer(),
                    Text(
                      'Baca →',
                      style: TextStyle(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.dark, AppColors.blueDeep],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/logo_jembergonobackgroud.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JemberGo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Pariwisata Terpadu Kab. Jember',
                  style: TextStyle(color: Colors.white70, fontSize: 8.5),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Platform pariwisata digital terintegrasi untuk Kabupaten Jember, Jawa Timur.',
          style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.6),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tentang Jember Go',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bantuan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kebijakan Privasi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 4),
        const Text(
          '© 2026 JEMBER GO — Dinas Pariwisata Kabupaten Jember',
          style: TextStyle(color: Colors.white54, fontSize: 8.5),
        ),
      ],
    ),
  );
}

class _HomeNavigation extends StatelessWidget {
  const _HomeNavigation();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ExplorerPage()));
          } else if (index > 1) {
            const labels = ['Tiket', 'Favorit', 'Profil'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${labels[index - 2]} segera hadir.')),
            );
          }
        },
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Eksplor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            activeIcon: Icon(Icons.confirmation_num),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    ),
  );
}
