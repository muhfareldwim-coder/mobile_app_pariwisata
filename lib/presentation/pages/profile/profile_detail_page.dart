import 'package:flutter/material.dart';

import '../../../data/models/user.dart';

const _profileBlue = Color(0xFF1674E8);
const _profileInk = Color(0xFF153454);
const _profileBackground = Color(0xFFF9F8FF);
const _avatarUrl =
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=320&q=85';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key, required this.user});

  final User user;

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _usernameController = TextEditingController(
    text: widget.user.username,
  );
  late final _emailController = TextEditingController(text: widget.user.email);
  late final _phoneController = TextEditingController(text: widget.user.phone);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _showPhotoMessage(
      'Penyimpanan profil akan tersedia setelah akun terhubung.',
    );
  }

  void _showPhotoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _profileBackground,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              onProfileTap: () {
                Navigator.maybePop(context);
              },
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  children: [
                    _ProfilePhoto(
                      onChange: () => _showPhotoMessage(
                        'Pemilihan foto profil belum tersedia.',
                      ),
                      onRemove: () =>
                          _showPhotoMessage('Fitur hapus foto belum tersedia.'),
                    ),
                    const SizedBox(height: 24),
                    _DetailSection(
                      title: 'Informasi Utama',
                      icon: Icons.badge_outlined,
                      children: [
                        _ProfileInput(
                          label: 'Nama Lengkap',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          validator: _required,
                        ),
                        _ProfileInput(
                          label: 'Nama Panggilan / Username',
                          controller: _usernameController,
                          icon: Icons.alternate_email_rounded,
                          validator: _required,
                        ),
                        _ProfileInput(
                          label: 'Alamat Email',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          trailing: const _StatusPill(
                            icon: Icons.verified_rounded,
                            label: 'Terverifikasi',
                          ),
                          validator: (value) =>
                              value != null && value.contains('@')
                              ? null
                              : 'Masukkan alamat email yang valid',
                        ),
                        _ProfileInput(
                          label: 'Nomor WhatsApp / HP',
                          controller: _phoneController,
                          icon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          trailing: const _StatusPill(
                            icon: Icons.check_circle_rounded,
                            label: 'Terhubung',
                          ),
                          validator: _required,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _DetailSection(
                      title: 'Keamanan Akun',
                      icon: Icons.shield_outlined,
                      children: [_PasswordTile(onTap: _showChangePassword)],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: _profileBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.save_outlined, size: 19),
                        label: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEDEEFF),
                          foregroundColor: _profileInk,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;

  Future<void> _showChangePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Kata Sandi'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Kata sandi baru'),
                validator: (value) => value != null && value.length >= 8
                    ? null
                    : 'Minimal 8 karakter',
              ),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi kata sandi',
                ),
                validator: (value) => value == passwordController.text
                    ? null
                    : 'Kata sandi tidak sama',
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                _showPhotoMessage('Kata sandi berhasil diperbarui.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    confirmController.dispose();
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back, color: _profileInk),
            ),
            const SizedBox(width: 4),
            const Text(
              'Detail',
              style: TextStyle(
                color: _profileInk,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: onProfileTap,
              tooltip: 'Profil',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF061D38),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.onChange, required this.onRemove});

  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E7FF),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  _avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                        color: Color(0xFFDCE8F6),
                        child: Icon(Icons.person, size: 54, color: _profileInk),
                      ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 2,
              child: IconButton.filled(
                onPressed: onChange,
                tooltip: 'Ganti foto',
                style: IconButton.styleFrom(
                  backgroundColor: _profileBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE9EBFF),
                foregroundColor: _profileBlue,
                minimumSize: const Size(84, 31),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text('Ganti Foto', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFECEE),
                foregroundColor: const Color(0xFFDC2435),
                minimumSize: const Size(84, 31),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text('Hapus Foto', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _profileBlue, size: 19),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: _profileInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.label,
    required this.controller,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFE2303A)),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    color: Color(0xFF424956),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(color: Color(0xFF273244), fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon,
                  color: const Color(0xFF7A8392),
                  size: 19,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F1FE),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _profileBlue, width: 1.3),
                ),
                errorStyle: const TextStyle(fontSize: 10, height: .7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE1EBFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _profileBlue),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: _profileBlue,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordTile extends StatelessWidget {
  const _PasswordTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F1FE),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: _profileBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubah Kata Sandi',
                      style: TextStyle(
                        color: Color(0xFF29364A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Terakhir diperbarui 2 bulan lalu',
                      style: TextStyle(color: Color(0xFF7B8290), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF77808D)),
            ],
          ),
        ),
      ),
    );
  }
}
