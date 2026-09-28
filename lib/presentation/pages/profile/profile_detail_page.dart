import 'package:flutter/material.dart';

import '../../../core/theme/profile_typography.dart';
import '../../../data/models/user.dart';
import '../../../data/services/auth_service.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({
    super.key,
    this.user,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
  });

  final User? user;
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  static const Color navy = Color(0xFF092B4C);
  static const Color blue = Color(0xFF1976E8);
  static const Color background = Color(0xFFF9F8FF);
  static const Color fieldColor = Color(0xFFF0F1FC);
  static const Color textDark = Color(0xFF26384A);
  static const Color textGrey = Color(0xFF7D8490);

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  static const Color navy = ProfileDetailPage.navy;
  static const Color blue = ProfileDetailPage.blue;
  static const Color background = ProfileDetailPage.background;
  static const Color fieldColor = ProfileDetailPage.fieldColor;
  static const Color textDark = ProfileDetailPage.textDark;
  static const Color textGrey = ProfileDetailPage.textGrey;

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String _passwordUpdatedLabel = 'Ketuk untuk memperbarui kata sandi';

  @override
  void initState() {
    super.initState();
    final initialName =
        widget.initialName ?? widget.user?.name ?? 'Pengguna JemberGo';
    _nameController = TextEditingController(text: initialName);
    _usernameController = TextEditingController(
      text: widget.user?.username.isNotEmpty == true
          ? widget.user!.username
          : initialName.toLowerCase().replaceAll(RegExp(r'\s+'), ''),
    );
    _emailController = TextEditingController(
      text: widget.initialEmail ?? widget.user?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialPhone ?? widget.user?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      User(
        id: widget.user?.id ?? 'local-user',
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  Future<void> _changePassword() async {
    final email = _emailController.text.trim();
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmationController = TextEditingController();
    var obscurePasswords = true;
    var isSaving = false;
    String? errorMessage;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah Kata Sandi'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscurePasswords,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi saat ini',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Masukkan kata sandi saat ini'
                      : null,
                ),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscurePasswords,
                  decoration: InputDecoration(
                    labelText: 'Kata sandi baru',
                    suffixIcon: IconButton(
                      tooltip: obscurePasswords
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () => setDialogState(
                        () => obscurePasswords = !obscurePasswords,
                      ),
                      icon: Icon(
                        obscurePasswords
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 8
                      ? 'Kata sandi minimal 8 karakter'
                      : null,
                ),
                TextFormField(
                  controller: confirmationController,
                  obscureText: obscurePasswords,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi kata sandi baru',
                  ),
                  validator: (value) => value != newPasswordController.text
                      ? 'Konfirmasi kata sandi tidak cocok'
                      : null,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      final updated = await _authService.changePassword(
                        email,
                        currentPasswordController.text,
                        newPasswordController.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (updated) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = 'Kata sandi saat ini tidak sesuai.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmationController.dispose();

    if (changed == true && mounted) {
      setState(() => _passwordUpdatedLabel = 'Diperbarui barusan');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diubah.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProfileTypography.apply(Theme.of(context)),
      child: Scaffold(
        backgroundColor: background,

        body: SafeArea(
          child: Column(
            children: [
              // =====================================================
              // HEADER
              // =====================================================

              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE8E8EE))),
                ),

                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: navy,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 22),

                    const Text(
                      'Detail ',
                      style: TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      width: 30,
                      height: 30,
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
              ),

              // =====================================================
              // CONTENT
              // =====================================================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 25),

                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // =================================================
                        // FOTO PROFIL
                        // =================================================

                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              padding: const EdgeInsets.all(4),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFDDE4FF),
                                  width: 4,
                                ),
                              ),

                              child: const CircleAvatar(
                                backgroundColor: Color(0xFFE3E5E8),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF858D95),
                                ),
                              ),
                            ),

                            Container(
                              width: 31,
                              height: 31,

                              decoration: const BoxDecoration(
                                color: blue,
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // =================================================
                        // BUTTON FOTO
                        // =================================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            SizedBox(
                              height: 30,

                              child: TextButton(
                                onPressed: () {},

                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8ECFF),

                                  foregroundColor: blue,

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),

                                child: const Text(
                                  'Ganti Foto',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              height: 30,

                              child: TextButton(
                                onPressed: () {},

                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFECEC),

                                  foregroundColor: const Color(0xFFE54B4B),

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),

                                child: const Text(
                                  'Hapus Foto',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // =================================================
                        // INFORMASI UTAMA
                        // =================================================
                        ProfileDetailCard(
                          title: 'Informasi Utama',
                          icon: Icons.badge_outlined,
                          children: [
                            DetailField(
                              label: 'Nama Lengkap',
                              controller: _nameController,
                              icon: Icons.person_outline,
                              required: true,
                            ),

                            DetailField(
                              label: 'Nama Panggilan / Username',
                              controller: _usernameController,
                              icon: Icons.alternate_email,
                              required: true,
                            ),

                            DetailField(
                              label: 'Alamat Email',
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              required: true,
                              statusLabel: 'Terverifikasi',
                              statusIcon: Icons.verified,
                            ),

                            DetailField(
                              label: 'Nomor WhatsApp / HP',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              required: true,
                              statusLabel: 'Terhubung',
                              statusIcon: Icons.check_circle,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // =================================================
                        // KEAMANAN AKUN
                        // =================================================
                        ProfileDetailCard(
                          title: 'Keamanan Akun',
                          icon: Icons.shield_outlined,
                          children: [
                            InkWell(
                              onTap: _changePassword,

                              child: Container(
                                padding: const EdgeInsets.all(10),

                                decoration: BoxDecoration(
                                  color: fieldColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),

                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,

                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E8FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),

                                      child: const Icon(
                                        Icons.lock_reset,
                                        color: blue,
                                        size: 17,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ubah Kata Sandi',
                                            style: TextStyle(
                                              color: textDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          SizedBox(height: 3),

                                          Text(
                                            _passwordUpdatedLabel,
                                            style: TextStyle(
                                              color: textGrey,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF7D8490),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // =================================================
                        // SIMPAN
                        // =================================================
                        SizedBox(
                          width: double.infinity,
                          height: 42,

                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,

                            icon: const Icon(Icons.save_outlined, size: 15),

                            label: const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              elevation: 2,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        // =================================================
                        // BATAL
                        // =================================================
                        SizedBox(
                          width: double.infinity,
                          height: 40,

                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },

                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE9ECFF),

                              foregroundColor: textDark,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),

                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// =============================================================
// CARD
// =============================================================

class ProfileDetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ProfileDetailCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon, color: ProfileDetailPage.blue, size: 18),

              const SizedBox(width: 5),

              Text(
                title,
                style: const TextStyle(
                  color: ProfileDetailPage.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...children,
        ],
      ),
    );
  }
}

// =============================================================
// DETAIL FIELD
// =============================================================

class DetailField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final String? statusLabel;
  final IconData? statusIcon;

  const DetailField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.statusLabel,
    this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: ProfileDetailPage.textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (required)
                      const Text(
                        ' *',
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (statusLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EAFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon ?? Icons.verified,
                        color: ProfileDetailPage.blue,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel!,
                        style: const TextStyle(
                          color: ProfileDetailPage.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: ProfileDetailPage.fieldColor,

              borderRadius: BorderRadius.circular(10),
            ),

            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: ProfileDetailPage.blue, size: 17),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      color: ProfileDetailPage.navy,
                      fontSize: 13,
                    ),
                    validator: required
                        ? (value) => value == null || value.trim().isEmpty
                              ? '$label wajib diisi'
                              : null
                        : null,
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
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
