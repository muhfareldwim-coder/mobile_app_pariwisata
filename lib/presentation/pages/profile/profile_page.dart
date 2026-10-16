import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/user.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/profile_photo_service.dart';
import 'profile_detail_page.dart';

const _profileNavy = Color(0xFF08213E);
const _profileInk = Color(0xFF173657);
const _profileOrange = Color(0xFFE98600);
const _profileBackground = Color(0xFFF9F8FF);
const _customerAvatarUrl =
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=320&q=85';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _photoVersion = 0;

  User get _user => AuthService.currentUser ?? User.sample;
  bool get _isSignedIn => AuthService.currentUser != null;

  Future<void> _openDetails() async {
    if (!_isSignedIn) {
      await _openAuthentication(AppRoutes.login);
      return;
    }
    await Navigator.push<User>(
      context,
      MaterialPageRoute<User>(builder: (_) => ProfileDetailPage(user: _user)),
    );
    if (mounted) {
      setState(() => _photoVersion++);
    }
  }

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
    return Scaffold(
      backgroundColor: _profileBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ProfileHeader(
              isGuest: !_isSignedIn,
              onProfileTap: _isSignedIn
                  ? _openDetails
                  : () => _openAuthentication(AppRoutes.login),
              tooltip: _isSignedIn ? 'Edit profil' : 'Masuk',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  if (_isSignedIn) ...[
                    _CustomerCard(
                      key: ValueKey(_photoVersion),
                      user: _user,
                      onEdit: _openDetails,
                    ),
                    const SizedBox(height: 28),
                    const _GroupHeading('AKUN & PREFERENSI'),
                    const SizedBox(height: 9),
                    _SettingsGroup(
                      children: [
                        _SettingRow(
                          icon: Icons.badge_outlined,
                          iconBackground: const Color(0xFFE9EDF2),
                          title: 'Data Pribadi & Identitas',
                          subtitle: 'kontak,email',
                          onTap: _openDetails,
                        ),
                        _SettingRow(
                          icon: Icons.favorite_rounded,
                          iconBackground: const Color(0xFFFFF1E1),
                          iconColor: const Color(0xFFE07C00),
                          title: 'Destinasi Favorit Saya',
                          subtitle:
                              'Pantai Payangan, Bukit Teletubbies, 6 lainnya',
                          onTap: () => _showMessage(
                            'Daftar destinasi favorit kamu akan tampil di sini.',
                          ),
                        ),
                        _SettingRow(
                          icon: Icons.notifications_active_outlined,
                          iconBackground: const Color(0xFFE8F0FF),
                          title: 'Notifikasi & Promo Wisata',
                          subtitle: 'Info event kebudayaan, flash sale tiket',
                          showDot: true,
                          onTap: _showNotificationSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _GroupHeading('APLIKASI & REGIONAL'),
                    const SizedBox(height: 9),
                    _SettingsGroup(
                      children: [
                        _SettingRow(
                          icon: Icons.language_rounded,
                          iconBackground: const Color(0xFFE9EBFF),
                          title: 'Bahasa',
                          subtitle: 'Bahasa Indonesia (ID)',
                          onTap: _showLanguagePicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _GroupHeading('DUKUNGAN & LEGAL'),
                    const SizedBox(height: 9),
                    _SettingsGroup(
                      children: [
                        _SettingRow(
                          icon: Icons.support_agent_rounded,
                          iconBackground: const Color(0xFFE1EEFF),
                          title: 'Pusat Bantuan Dinas Pariwisata',
                          subtitle:
                              'WhatsApp CS resmi, Posko Wisata & Call Center',
                          onTap: () => _showMessage(
                            'Pusat bantuan Dinas Pariwisata Jember.',
                          ),
                        ),
                        _SettingRow(
                          icon: Icons.policy_outlined,
                          iconBackground: const Color(0xFFE9EBFF),
                          title: 'Syarat Ketentuan & Kebijakan Privasi',
                          subtitle: 'Perlindungan data dan pedoman berkunjung',
                          onTap: _showLegalInformation,
                        ),
                      ],
                    ),
                  ] else ...[
                    _GuestWelcomeCard(
                      onSignIn: () => _openAuthentication(AppRoutes.login),
                      onRegister: () => _openAuthentication(AppRoutes.register),
                    ),
                    const SizedBox(height: 25),
                    const _GuestBenefits(),
                    const SizedBox(height: 28),
                    const _GroupHeading('APLIKASI & BANTUAN'),
                    const SizedBox(height: 9),
                    _SettingsGroup(
                      children: [
                        _SettingRow(
                          icon: Icons.translate_rounded,
                          iconBackground: const Color(0xFFF4F7FA),
                          title: 'Pilihan Bahasa',
                          subtitle: 'Indonesia',
                          onTap: _showLanguagePicker,
                        ),
                        _SettingRow(
                          icon: Icons.support_agent_rounded,
                          iconBackground: const Color(0xFFF4F7FA),
                          title: 'Pusat Bantuan & CS Pariwisata',
                          subtitle: 'WhatsApp',
                          onTap: () => _showMessage(
                            'Pusat bantuan Dinas Pariwisata Jember.',
                          ),
                        ),
                        _SettingRow(
                          icon: Icons.policy_outlined,
                          iconBackground: const Color(0xFFF4F7FA),
                          title: 'Syarat Ketentuan & Kebijakan Privasi',
                          subtitle: '',
                          onTap: _showLegalInformation,
                        ),
                        _SettingRow(
                          icon: Icons.info_outline_rounded,
                          iconBackground: const Color(0xFFF4F7FA),
                          title: 'Tentang JemberGo',
                          subtitle: 'Versi 2.4.0 • Kabupaten Jember',
                          onTap: () => _showMessage(
                            'JemberGo — aplikasi wisata Kabupaten Jember.',
                          ),
                        ),
                      ],
                    ),
                  ],
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
    );
  }

  Future<void> _showNotificationSettings() async {
    var enabled = true;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notifikasi & Promo Wisata'),
          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            title: const Text('Info wisata dan promo'),
            onChanged: (value) => setDialogState(() => enabled = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    await showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Bahasa'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Bahasa Indonesia'),
              subtitle: Text('ID'),
              trailing: Icon(Icons.check_circle, color: _profileOrange),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Pilihan bahasa Inggris segera tersedia.');
            },
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('English'),
              subtitle: Text('EN'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLegalInformation() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Syarat & Kebijakan Privasi'),
        content: const Text(
          'Data akun digunakan untuk mengelola profil, pemesanan tiket, dan '
          'informasi wisata JemberGo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onProfileTap,
    required this.tooltip,
    required this.isGuest,
  });

  final VoidCallback onProfileTap;
  final String tooltip;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isGuest ? 'Profil' : 'Profile',
                style: const TextStyle(
                  color: _profileNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isGuest)
              Tooltip(
                message: tooltip,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FA),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE7ECF2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: _profileOrange),
                          SizedBox(width: 7),
                          Text(
                            'Mode Tamu',
                            style: TextStyle(
                              color: _profileInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              IconButton.filled(
                onPressed: onProfileTap,
                tooltip: tooltip,
                style: IconButton.styleFrom(
                  backgroundColor: _profileNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(42, 42),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuestWelcomeCard extends StatelessWidget {
  const _GuestWelcomeCard({required this.onSignIn, required this.onRegister});

  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102F52), Color(0xFF1D4A78)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F092340),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0x223F6B96),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x667F9BB7), width: 2),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GuestBadge(),
                    SizedBox(height: 8),
                    Text(
                      'Halo, Penjelajah!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Selamat datang di JemberGo',
                      style: TextStyle(color: Color(0xFFBED0E5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Masuk atau daftar untuk memesan tiket wisata, menyimpan destinasi favorit, dan mengelola perjalananmu di Jember.',
            style: TextStyle(
              color: Color(0xFFD4E0EF),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x447F9BB7), height: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _profileNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Masuk Akun',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF7895B5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Daftar Akun Baru',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
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

class _GuestBadge extends StatelessWidget {
  const _GuestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF355778),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined, color: Colors.white, size: 14),
          SizedBox(width: 5),
          Text(
            'PENGUNJUNG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBenefits extends StatelessWidget {
  const _GuestBenefits();

  static const _benefits = [
    (
      Icons.qr_code_2_rounded,
      Color(0xFFEAF3FF),
      Color(0xFF1264CE),
      'Pemesanan Tiket Wisata Cepat',
      'E-tiket instan dengan kode QR tanpa perlu antre di loket.',
    ),
    (
      Icons.favorite_border_rounded,
      Color(0xFFFFF7E7),
      Color(0xFFE98600),
      'Simpan Destinasi Favorit',
      'Tandai pantai, bukit, dan air terjun untuk rencana liburanmu.',
    ),
    (
      Icons.alt_route_rounded,
      Color(0xFFE8FAF3),
      Color(0xFF009A70),
      'Panduan Rute & Akses Offline',
      'Navigasi rute wisata akurat langsung ke lokasi tujuan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keuntungan Punya Akun',
          style: TextStyle(
            color: _profileNavy,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Nikmati kemudahan menjelajah seluruh keindahan Jember',
          style: TextStyle(color: Color(0xFF73829A), fontSize: 13),
        ),
        const SizedBox(height: 14),
        for (final benefit in _benefits) ...[
          _GuestBenefitCard(
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

class _GuestBenefitCard extends StatelessWidget {
  const _GuestBenefitCard({
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({super.key, required this.user, required this.onEdit});

  final User user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF092340), Color(0xFF0D3155)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25091F39),
            blurRadius: 17,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(size: 78, userId: user.id),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF403A35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFA443),
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Wisatawan Terverifikasi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFFFFD6AB),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8FA7C6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8FA7C6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: onEdit,
                  tooltip: 'Edit data pribadi',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A60),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0x66041934),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                _StatItem(value: '7', label: 'Tiket Terbeli'),
                _StatItem(
                  value: '12',
                  label: 'Wisata Dikunjungi',
                  active: true,
                ),
                _StatItem(value: '4', label: 'Ulasan Diberikan'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.size, required this.userId});

  final double size;
  final String userId;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  late Future<File?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = ProfilePhotoService.getPhoto(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFDFE5EC),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: FutureBuilder<File?>(
                future: _photoFuture,
                builder: (context, snapshot) {
                  final photo = snapshot.data;
                  if (photo != null) {
                    return Image.file(
                      photo,
                      width: size - 8,
                      height: size - 8,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _defaultAvatar(),
                    );
                  }
                  return Image.network(
                    _customerAvatarUrl,
                    width: size - 8,
                    height: size - 8,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _defaultAvatar(),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: _profileOrange,
                border: Border.all(color: _profileNavy, width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => const ColoredBox(
    color: Color(0xFFD9E5F1),
    child: Icon(Icons.person, color: _profileNavy, size: 40),
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.active = false,
  });

  final String value;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF112D4D) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD0B2),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8EA7C4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    this.iconColor = _profileInk,
    this.showDot = false,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDot;

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
                child: Icon(icon, color: iconColor, size: 19),
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
              if (showDot) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: _profileOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
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
          'JemberGo Mobile v2.4.0',
          style: TextStyle(color: Color(0xFF777E8B), fontSize: 10),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dinas Pariwisata & Kebudayaan Kabupaten\nJember, Jawa Timur',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF999EAA), fontSize: 10, height: 1.4),
        ),
      ],
    );
  }
}
