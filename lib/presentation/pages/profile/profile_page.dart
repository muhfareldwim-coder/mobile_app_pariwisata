import 'package:flutter/material.dart';

import 'profile_detail_page.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/profile_typography.dart';
import '../../../data/models/user.dart';
import '../destination/explorer_page.dart';
import '../ticket/my_ticket_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color navy = Color(0xFF062C4C);
  static const Color orange = Color(0xFFF29900);
  static const Color bg = Color(0xFFF8F7FC);
  static const Color textGrey = Color(0xFF7D8490);

  User? _user;
  String? _profileName;
  String? _profileEmail;
  String? _profilePhone;
  String _selectedLanguage = 'Bahasa Indonesia';
  bool _eventNotifications = true;
  bool _promoNotifications = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is User && _user != arguments) {
      _user = arguments;
      _profileName ??= arguments.name;
      _profileEmail ??= arguments.email;
      _profilePhone ??= arguments.phone;
    }
  }

  Future<void> _openProfileDetails() async {
    final updatedUser = await Navigator.push<User>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailPage(
          user: _user,
          initialName: _profileName,
          initialEmail: _profileEmail,
          initialPhone: _profilePhone,
        ),
      ),
    );
    if (!mounted || updatedUser == null) return;
    setState(() {
      _user = updatedUser;
      _profileName = updatedUser.name;
      _profileEmail = updatedUser.email;
      _profilePhone = updatedUser.phone;
    });
  }

  void _showInformation(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _profileDialog(
        icon: Icons.info_outline,
        title: title,
        subtitle: 'Informasi JemberGo',
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF586675),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showPersonalData() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _profileDialog(
        icon: Icons.badge_outlined,
        title: 'Data pribadi',
        subtitle: 'Informasi yang terhubung ke akunmu',
        content: Column(
          children: [
            _profileDataRow(
              Icons.person_outline,
              'Nama lengkap',
              _profileName ?? _user?.name ?? 'Pengguna JemberGo',
            ),
            const SizedBox(height: 8),
            _profileDataRow(
              Icons.email_outlined,
              'Alamat email',
              _profileEmail ?? _user?.email ?? 'Belum ditambahkan',
            ),
            const SizedBox(height: 8),
            _profileDataRow(
              Icons.phone_outlined,
              'Nomor telepon',
              _profilePhone ?? 'Belum ditambahkan',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openProfileDetails();
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit profil'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _popupHeading(
                Icons.language_outlined,
                'Pilih bahasa',
                'Atur bahasa tampilan aplikasi',
              ),
              const SizedBox(height: 14),
              for (final language in const ['Bahasa Indonesia', 'English'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        _selectedLanguage == language
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _selectedLanguage == language ? navy : textGrey,
                      ),
                      title: Text(
                        language,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: _selectedLanguage == language
                          ? const Icon(Icons.check, color: navy, size: 18)
                          : null,
                      onTap: () {
                        setState(() => _selectedLanguage = language);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _profileDialog(
          icon: Icons.notifications_none,
          title: 'Notifikasi',
          subtitle: 'Pilih informasi yang ingin diterima',
          content: Column(
            children: [
              Material(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text(
                    'Info kegiatan wisata',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Jadwal dan acara terbaru',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _eventNotifications,
                  activeThumbColor: navy,
                  onChanged: (value) =>
                      setDialogState(() => _eventNotifications = value),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text(
                    'Promo dan tiket',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Penawaran dan pembaruan tiket',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _promoNotifications,
                  activeThumbColor: navy,
                  onChanged: (value) =>
                      setDialogState(() => _promoNotifications = value),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavorites() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _popupHeading(
              Icons.favorite_outline,
              'Destinasi favorit',
              'Kumpulan tempat yang ingin kamu kunjungi',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9EAF0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.favorite_border, color: orange, size: 30),
                  SizedBox(height: 10),
                  Text(
                    'Belum ada destinasi tersimpan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jelajahi wisata Jember dan simpan yang kamu suka.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExplorerPage()),
                  );
                },
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Jelajahi destinasi'),
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileDialog({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      title: _popupHeading(icon, title, subtitle),
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.48,
        ),
        child: SingleChildScrollView(child: content),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      actions: actions,
    );
  }

  Widget _popupHeading(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: navy, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileDataRow(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onNavigationSelected(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
          arguments: _user,
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExplorerPage()),
        );
        break;
      case 2:
        _showInformation(
          'Peta wisata',
          'Fitur peta destinasi belum tersedia. Silakan gunakan menu Jelajahi untuk melihat destinasi.',
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTicketPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProfileTypography.apply(Theme.of(context)),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F8FF),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 6,
          leadingWidth: 48,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
            child: Image.asset(
              'assets/logo_jembergonobackgroud.png',
              fit: BoxFit.contain,
            ),
          ),
          title: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JEMBERGO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: orange,
                ),
              ),
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: navy,
                ),
              ),
            ],
          ),

          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),

        // ================= BODY =================
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(13, 8, 13, 8),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= PROFILE CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(12),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    // FOTO + DATA USER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FOTO PROFIL
                        Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,

                              padding: const EdgeInsets.all(3),

                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),

                              child: ClipOval(
                                child: Container(
                                  color: const Color(0xFFE4E4E4),

                                  child: const Icon(
                                    Icons.person,
                                    size: 38,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                            // ICON CAMERA
                            Positioned(
                              right: 0,
                              bottom: 0,

                              child: Container(
                                width: 19,
                                height: 19,

                                decoration: const BoxDecoration(
                                  color: orange,
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 10),

                        // DATA USER
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xFF8A6735),
                                  borderRadius: BorderRadius.circular(10),
                                ),

                                child: const Text(
                                  '● Wisatawan Terverifikasi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                _profileName ??
                                    _user?.name ??
                                    'Pengguna JemberGo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                _profileEmail ??
                                    _user?.email ??
                                    'Belum ada email',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),

                              Text(
                                _profilePhone ??
                                    _user?.phone ??
                                    'Nomor telepon belum ditambahkan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TOMBOL EDIT
                        IconButton(
                          tooltip: 'Edit profil',
                          onPressed: _openProfileDetails,
                          style: IconButton.styleFrom(
                            fixedSize: const Size(38, 38),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.13,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ================= STATISTIK =================
                    Row(
                      children: const [
                        ProfileStatistic(number: '7', label: 'Tiket Terbeli'),

                        ProfileStatistic(
                          number: '12',
                          label: 'Wisata Dikunjungi',
                        ),

                        ProfileStatistic(
                          number: '4',
                          label: 'Ulasan Diberikan',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= AKUN & PREFERENSI =================
              const SectionTitle(title: 'AKUN & PREFERENSI'),

              MenuBox(
                children: [
                  ProfileMenu(
                    icon: Icons.badge_outlined,
                    iconBackground: const Color(0xFFE9EDF1),
                    iconColor: navy,
                    title: 'Data Pribadi & Identitas',
                    subtitle: 'Nama, alamat email, dan kontak',
                    onTap: _showPersonalData,
                  ),

                  ProfileMenu(
                    icon: Icons.favorite,
                    iconBackground: const Color(0xFFFFF0DC),
                    iconColor: orange,
                    title: 'Destinasi Favorit Saya',
                    subtitle: 'Lihat destinasi yang Anda simpan',
                    onTap: _showFavorites,
                  ),

                  ProfileMenu(
                    icon: Icons.notifications_none,
                    iconBackground: const Color(0xFFE8EFFB),
                    iconColor: navy,
                    title: 'Notifikasi & Promo Wisata',
                    subtitle: 'Atur info kegiatan wisata dan promo',
                    showDot: true,
                    onTap: _showNotificationSettings,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= APLIKASI =================
              const SectionTitle(title: 'APLIKASI & REGIONAL'),

              MenuBox(
                children: [
                  ProfileMenu(
                    icon: Icons.language,
                    iconBackground: const Color(0xFFE8EDFA),
                    iconColor: navy,
                    title: 'Bahasa',
                    subtitle: _selectedLanguage,
                    onTap: _showLanguagePicker,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= DUKUNGAN =================
              const SectionTitle(title: 'DUKUNGAN & LEGAL'),

              MenuBox(
                children: [
                  ProfileMenu(
                    icon: Icons.support_agent,
                    iconBackground: const Color(0xFFE4F0FF),
                    iconColor: navy,
                    title: 'Pusat Bantuan',
                    subtitle: 'Informasi bantuan pariwisata Kabupaten Jember',
                    onTap: () => _showInformation(
                      'Pusat Bantuan',
                      'Untuk bantuan terkait wisata Jember, silakan hubungi kanal resmi Dinas Pariwisata dan Kebudayaan Kabupaten Jember.',
                    ),
                  ),

                  ProfileMenu(
                    icon: Icons.policy_outlined,
                    iconBackground: const Color(0xFFE8EDFA),
                    iconColor: navy,
                    title: 'Syarat dan Kebijakan Privasi',
                    subtitle: 'Informasi penggunaan layanan dan data pribadi',
                    onTap: () => _showInformation(
                      'Syarat dan Kebijakan Privasi',
                      'Gunakan informasi akun dengan benar. Data akun digunakan untuk menyediakan layanan JemberGo dan tidak dibagikan tanpa izin.',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= LOGOUT =================
              SizedBox(
                width: double.infinity,
                height: 44,

                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  ),

                  icon: const Icon(Icons.logout, size: 14),

                  label: const Text(
                    'Keluar Akun',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD7D3),

                    foregroundColor: const Color(0xFFD83B32),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 17),

              // ================= FOOTER =================
              const SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'JemberGo Mobile v2.4.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dinas Pariwisata & Kebudayaan Kabupaten',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    Text(
                      'Jember, Jawa Timur',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),

        // ================= BOTTOM NAVIGATION =================
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 4,

          type: BottomNavigationBarType.fixed,

          backgroundColor: Colors.white,

          selectedItemColor: navy,

          unselectedItemColor: const Color(0xFF777777),

          selectedFontSize: 10,

          unselectedFontSize: 10,

          onTap: _onNavigationSelected,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 17),
              label: 'Beranda',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 17),
              label: 'Eksplor',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 17),
              label: 'Peta',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_num_outlined, size: 17),
              label: 'Tiket',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 17),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SECTION TITLE
// =====================================================

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 8),

      child: Text(
        title,

        style: const TextStyle(
          color: Color(0xFF29465C),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =====================================================
// MENU BOX
// =====================================================

class MenuBox extends StatelessWidget {
  final List<Widget> children;

  const MenuBox({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Column(children: children),
    );
  }
}

// =====================================================
// PROFILE MENU
// =====================================================

class ProfileMenu extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool showDot;
  final VoidCallback onTap;

  const ProfileMenu({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),

        padding: const EdgeInsets.symmetric(vertical: 9),

        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE7E7ED), width: 0.7),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(width: 9),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Color(0xFF17344B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // NOTIFICATION DOT
            if (showDot)
              Container(
                width: 6,
                height: 6,

                margin: const EdgeInsets.only(right: 7),

                decoration: const BoxDecoration(
                  color: Color(0xFFF29900),
                  shape: BoxShape.circle,
                ),
              ),

            // ARROW
            const Icon(Icons.chevron_right, size: 15, color: Color(0xFF777777)),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// STATISTIC
// =====================================================

class ProfileStatistic extends StatelessWidget {
  final String number;
  final String label;

  const ProfileStatistic({
    super.key,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,

            textAlign: TextAlign.center,

            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
