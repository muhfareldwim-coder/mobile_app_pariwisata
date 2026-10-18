import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/user.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/favorite_destination_service.dart';
import '../destination/destination_detail_page.dart';
import 'profile_detail_page.dart';

const _profileNavy = Color(0xFF08213E);
const _profileInk = Color(0xFF173657);
const _profileOrange = Color(0xFFE98600);
const _profileBackground = Color(0xFFF9F8FF);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  AuthService get _authService => widget.authService ?? AuthService();

  User? get _user => AuthService.currentUser;
  bool get _isSignedIn => AuthService.currentUser != null;

  Future<void> _openDetails() async {
    if (AuthService.accessToken != null) {
      await _refreshProfile();
    }
    if (!mounted) return;
    final user = _user;
    if (user == null) {
      await _openAuthentication(AppRoutes.login);
      return;
    }
    await Navigator.push<User>(
      context,
      MaterialPageRoute<User>(
        builder: (_) =>
            ProfileDetailPage(user: user, authService: _authService),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _refreshProfile() async {
    if (AuthService.accessToken == null ||
        AuthService.currentUser?.role != 'CUSTOMER') {
      return;
    }
    try {
      await _authService.refreshProfile();
    } on Exception catch (error) {
      if (mounted) _showMessage('Profil gagal disegarkan: $error');
    }
  }

  Future<void> refreshProfile() => _refreshProfile();

  Future<bool> _openAuthentication(String route) async {
    final authenticated = await Navigator.pushNamed(context, route);
    if (mounted) setState(() {});
    return authenticated == true && AuthService.currentUser != null;
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Kamu yakin ingin keluar dari akun JemberGo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AuthService().logoutFromServer();
      if (mounted) setState(() {});
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AuthService.currentUserListenable,
      builder: (context, _, _) => Scaffold(
        backgroundColor: _profileBackground,
        body: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(
                  identityCard: _ProfileIdentityCard(
                    user: _user,
                    onEdit: _openDetails,
                    onSignIn: () => _openAuthentication(AppRoutes.login),
                    onRegister: () =>
                        _openAuthentication(AppRoutes.register),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignedIn) ...[
                        const SizedBox(height: 10),
                        const _GroupHeading('WISATA FAVORIT'),
                        const SizedBox(height: 9),
                        const _FavoriteDestinations(),
                      ],
                      const SizedBox(height: 25),
                      const _ProfileBenefits(),
                      const SizedBox(height: 28),
                      const _GroupHeading('PUSAT INFORMASI'),
                      const SizedBox(height: 9),
                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.language_rounded,
                            iconBackground: const Color(0xFFF4F7FA),
                            title: 'Pilihan Bahasa',
                            subtitle: 'Bahasa Indonesia (ID)',
                            onTap: _showLanguagePicker,
                          ),
                          _SettingRow(
                            icon: Icons.policy_outlined,
                            iconBackground: const Color(0xFFF4F7FA),
                            title: 'Syarat Ketentuan & Kebijakan Privasi',
                            subtitle: 'Informasi syarat dan kebijakan',
                            onTap: _showLegalInformation,
                          ),
                          _SettingRow(
                            icon: Icons.info_outline_rounded,
                            iconBackground: const Color(0xFFF4F7FA),
                            title: 'Tentang JemberGo',
                            subtitle: 'Informasi aplikasi',
                            onTap: _showAboutJemberGo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (_isSignedIn)
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _signOut,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFDCD9),
                              foregroundColor: const Color(0xFFC91F1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 19),
                            label: const Text(
                              'Keluar Akun',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const _ProfileFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    await _showInformationDialog(
      title: 'Pilihan Bahasa',
      placeholder: 'Informasi pilihan bahasa akan ditambahkan di sini.',
    );
  }

  Future<void> _showLegalInformation() async {
    await _showInformationDialog(
      title: 'Syarat Ketentuan & Kebijakan Privasi',
      placeholder: 'Informasi syarat dan kebijakan akan ditambahkan di sini.',
    );
  }

  Future<void> _showAboutJemberGo() async {
    await _showInformationDialog(
      title: 'Tentang JemberGo',
      placeholder: 'Informasi tentang JemberGo akan ditambahkan di sini.',
    );
  }

  Future<void> _showInformationDialog({
    required String title,
    required String placeholder,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _profileNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                placeholder,
                style: const TextStyle(
                  color: Color(0xFF73829A),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.identityCard});

  final Widget identityCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('profile-header'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.viewPaddingOf(context).top + 18,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12304A), Color(0xFF244D70)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Kelola akun dan preferensi wisatamu.',
                  style: TextStyle(
                    color: Color(0xFFCCD8E5),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          identityCard,
        ],
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.user,
    required this.onEdit,
    required this.onSignIn,
    required this.onRegister,
  });

  final User? user;
  final VoidCallback onEdit;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = user != null;
    return Container(
      key: const ValueKey('profile-identity-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFEAF0F6),
                child: user == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        color: _profileNavy,
                        size: 30,
                      )
                    : Text(
                        _profileInitial(user!.name),
                        style: const TextStyle(
                          color: _profileNavy,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Mode Tamu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _profileNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isSignedIn && user!.email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user!.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF73829A),
                          fontSize: 12,
                        ),
                      ),
                    ] else if (!isSignedIn) ...[
                      const SizedBox(height: 3),
                      const Text(
                        'Masuk untuk memesan tiket dan menyimpan destinasi favoritmu.',
                        style: TextStyle(
                          color: Color(0xFF73829A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSignedIn)
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit profil',
                  icon: const Icon(Icons.edit_outlined),
                  color: _profileNavy,
                ),
            ],
          ),
          if (!isSignedIn) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('profile-sign-in'),
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: _profileNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Masuk'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('profile-register'),
                    onPressed: onRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _profileNavy,
                      side: const BorderSide(color: _profileNavy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Daftar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _profileInitial(String? name) {
  final trimmedName = name?.trim() ?? '';
  if (trimmedName.isEmpty) return '?';
  return trimmedName.characters.first.toUpperCase();
}

class _ProfileBenefits extends StatelessWidget {
  const _ProfileBenefits();

  static const _benefits = [
    (
      Icons.confirmation_number_outlined,
      Color(0xFFEAF3FF),
      _profileNavy,
      'Pemesanan Tiket Wisata Lebih Praktis',
      'Pesan tiket destinasi wisata di Kabupaten Jember secara online dengan mudah dan nyaman, kapan saja.',
    ),
    (
      Icons.payments_outlined,
      Color(0xFFE8F4FF),
      _profileNavy,
      'Pembayaran QRIS yang Mudah dan Transparan',
      'Selesaikan pembayaran dengan QRIS serta pantau status transaksi Anda secara praktis.',
    ),
    (
      Icons.qr_code_2_rounded,
      Color(0xFFE8FAF3),
      _profileNavy,
      'E-Ticket Digital yang Siap Digunakan',
      'Dapatkan tiket digital dengan kode QR untuk memudahkan proses verifikasi saat tiba di destinasi wisata.',
    ),
    (
      Icons.receipt_long_outlined,
      Color(0xFFFFF7E7),
      _profileNavy,
      'Riwayat Pemesanan Tersimpan Rapi',
      'Akses kembali riwayat transaksi, detail pemesanan, dan informasi tiket Anda dalam satu akun.',
    ),
    (
      Icons.groups_outlined,
      Color(0xFFF0EBFF),
      _profileNavy,
      'Pengelolaan Rombongan dan Jadwal yang Mudah',
      'Atur data ketua kelompok, anggota rombongan, serta jadwal kunjungan agar perjalanan lebih terencana.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nikmati Kemudahan Berwisata Bersama JemberGo',
          style: TextStyle(
            color: _profileNavy,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        for (final benefit in _benefits) ...[
          _ProfileBenefitCard(
            icon: benefit.$1,
            iconBackground: benefit.$2,
            iconColor: benefit.$3,
            title: benefit.$4,
            description: benefit.$5,
          ),
          if (benefit != _benefits.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ProfileBenefitCard extends StatelessWidget {
  const _ProfileBenefitCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEFF1F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _profileNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF73829A),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteDestinations extends StatelessWidget {
  const _FavoriteDestinations();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: FavoriteDestinationService.revision,
      builder: (context, _, _) {
        final favorites = FavoriteDestinationService.destinations;
        if (favorites.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EAF2)),
            ),
            child: const Text(
              'Destinasi yang kamu simpan akan muncul di sini.',
              style: TextStyle(color: Color(0xFF73829A), fontSize: 13),
            ),
          );
        }

        return Column(
          children: [
            for (final destination in favorites) ...[
              _FavoriteDestinationCard(destination: destination),
              if (destination != favorites.last) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _FavoriteDestinationCard extends StatelessWidget {
  const _FavoriteDestinationCard({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DestinationDetailPage(destination: destination),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EAF2)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: destination.imageUrl == null
                      ? const ColoredBox(
                          color: Color(0xFFEAF0F6),
                          child: Icon(
                            Icons.landscape_outlined,
                            color: _profileNavy,
                          ),
                        )
                      : Image.network(
                          destination.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFEAF0F6),
                            child: Icon(
                              Icons.landscape_outlined,
                              color: _profileNavy,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _profileNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF73829A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus dari favorit',
                onPressed: () => FavoriteDestinationService.toggle(destination),
                icon: const Icon(Icons.favorite_rounded),
                color: _profileOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF405A7D),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<_SettingRow> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, color: Color(0xFFE5E8FA)),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _profileInk, size: 19),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _profileInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF858B97),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF80858E),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: Color(0xFFE7EAF3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.settings_rounded,
            size: 14,
            color: _profileInk,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dinas Pariwisata & Kebudayaan Kabupaten\nJember, Jawa Timur',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF999EAA), fontSize: 10, height: 1.4),
        ),
      ],
    );
  }
}
