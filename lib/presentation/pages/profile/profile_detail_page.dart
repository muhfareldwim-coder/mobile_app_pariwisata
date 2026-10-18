import 'package:flutter/material.dart';

import '../../../data/models/user.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';

const _profileNavy = Color(0xFF12304A);
const _profileRaisedNavy = Color(0xFF244D70);
const _profileInk = Color(0xFF173657);
const _profileBackground = Color(0xFFF7F9FC);

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key, required this.user, this.authService});

  final User user;
  final AuthService? authService;

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  AuthService get _authService => widget.authService ?? AuthService();

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _emailController = TextEditingController(text: widget.user.email);
  late final _phoneController = TextEditingController(text: widget.user.phone);
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _showPassword = false;
  bool _showPasswordConfirmation = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final updatedUser = await _authService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );
      if (mounted) Navigator.pop(context, updatedUser);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on FormatException catch (error) {
      if (mounted) _showMessage('Respons profil tidak valid: $error');
    } on Exception catch (error) {
      if (mounted) _showMessage('Profil gagal disimpan: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String? _optionalPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty && _passwordConfirmationController.text.isEmpty) {
      return null;
    }
    if (password.length < 8) return 'Minimal 8 karakter';
    if (password != _passwordConfirmationController.text) {
      return 'Konfirmasi kata sandi tidak sama';
    }
    return null;
  }

  String? _optionalPasswordConfirmation(String? value) {
    final confirmation = value ?? '';
    if (_passwordController.text.isEmpty && confirmation.isEmpty) return null;
    if (_passwordController.text.length < 8) {
      return 'Kata sandi baru minimal 8 karakter';
    }
    if (confirmation != _passwordController.text) {
      return 'Konfirmasi kata sandi tidak sama';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _profileBackground,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _DetailHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailSection(
                      title: 'Informasi pribadi',
                      subtitle: 'Pastikan data yang digunakan untuk pemesanan selalu benar.',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _ProfileInput(
                          label: 'Nama lengkap',
                          hint: 'Masukkan nama lengkap',
                          controller: _nameController,
                          validator: _validName,
                        ),
                        _ProfileInput(
                          label: 'Alamat email',
                          hint: 'Masukkan email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value != null &&
                                  value.trim().length <= 150 &&
                                  RegExp(
                                    r'^[^@\s]+@gmail\.com$',
                                    caseSensitive: false,
                                  ).hasMatch(value.trim())
                              ? null
                              : 'Gunakan alamat email @gmail.com yang valid',
                        ),
                        _ProfileInput(
                          label: 'Nomor WhatsApp',
                          hint: 'Masukkan nomor telepon',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: _validPhone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Keamanan akun',
                      subtitle: 'Gunakan minimal 8 karakter. Kosongkan jika tidak ingin mengubahnya.',
                      icon: Icons.shield_outlined,
                      children: [
                        _ProfileInput(
                          label: 'Password baru',
                          hint: 'Password baru',
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Sembunyikan password'
                                : 'Tampilkan password',
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validator: _optionalPassword,
                        ),
                        _ProfileInput(
                          label: 'Konfirmasi password',
                          hint: 'Ulangi password',
                          controller: _passwordConfirmationController,
                          obscureText: !_showPasswordConfirmation,
                          suffixIcon: IconButton(
                            tooltip: _showPasswordConfirmation
                                ? 'Sembunyikan konfirmasi password'
                                : 'Tampilkan konfirmasi password',
                            onPressed: () => setState(
                              () => _showPasswordConfirmation =
                                  !_showPasswordConfirmation,
                            ),
                            icon: Icon(
                              _showPasswordConfirmation
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validator: _optionalPasswordConfirmation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: _profileNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _profileNavy,
                                side: const BorderSide(
                                  color: _profileNavy,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
      ),
    );
  }

  String? _validName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nama wajib diisi';
    if (value.trim().length > 100 ||
        !RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value.trim())) {
      return 'Nama hanya boleh berisi huruf dan spasi (maksimal 100 karakter)';
    }
    return null;
  }

  String? _validPhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty ||
        RegExp(r'^(?:[0-9]{10,12}|\+[0-9]{10,15})$').hasMatch(phone)) {
      return null;
    }
    return 'Gunakan 10-12 digit lokal atau awali + untuk nomor internasional';
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('edit-profile-header'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: _profileBackground,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back_rounded, color: _profileInk),
            ),
            const SizedBox(width: 4),
            const Text(
              'Edit Profil',
              style: TextStyle(
                color: _profileInk,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F6),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _profileNavy, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _profileInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF73829A),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
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
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF31516B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(
              color: _profileInk,
              fontSize: 13,
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA1B0BA),
                fontSize: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFFBFDFE),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 13,
              ),
              suffixIcon: suffixIcon,
              suffixIconColor: const Color(0xFF7890A1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFDBE6EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFDBE6EE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: _profileRaisedNavy,
                  width: 1.3,
                ),
              ),
              errorStyle: const TextStyle(fontSize: 10, height: .8),
            ),
          ),
        ],
      ),
    );
  }
}
