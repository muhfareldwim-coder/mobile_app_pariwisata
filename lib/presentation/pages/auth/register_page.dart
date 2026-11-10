import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import 'otp_verification_page.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_form_column.dart';
import '../../widgets/auth_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthService get _authService => widget.authService ?? AuthService();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia.')));
  }

  Future<void> _register() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            email: _emailController.text.trim().toLowerCase(),
            purpose: OtpPurpose.registration,
          ),
        ),
      );
      if (!mounted || verified != true) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on Exception catch (error) {
      if (mounted) {
        await _showRegistrationError(error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showRegistrationError(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1F0),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 30,
          ),
        ),
        title: const Text(
          'Pendaftaran belum berhasil',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          description: 'Daftar untuk mendapatkan akses ke layanan pariwisata Kabupaten Jember',
          isRegister: true,
          fields: [
            AppTextField(
              label: 'Nama Lengkap',
              hint: 'Nama lengkap',
              controller: _nameController,
              validator: (value) =>
                  value != null &&
                      value.trim().isNotEmpty &&
                      RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)
                  ? null
                  : 'Nama lengkap hanya boleh berisi huruf dan spasi.',
            ),
            AppTextField(
              label: 'Nomor Telepon',
              hint: 'Masukkan Nomor Telepon',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value != null &&
                      RegExp(r'^(?:[0-9]{10,12}|\+[0-9]{10,15})$')
                          .hasMatch(value.trim())
                  ? null
                  : 'Masukkan nomor telepon yang valid',
            ),
            AppTextField(
              label: 'Email',
              hint: 'Masukkan Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.trim().contains('@')
                  ? null
                  : 'Masukkan email yang valid',
            ),
            AppTextField(
              label: 'Password',
              hint: 'Minimal 8 karakter',
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (value) => value != null && value.length >= 8
                  ? null
                  : 'Password minimal 8 karakter',
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ],
          buttonLabel: 'Daftar',
          isSubmitting: _isSubmitting,
          onSubmit: _register,
          googleAction: _showUnavailable,
          guestAction: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
          switchAction: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.login),
          switchLabel: 'Masuk',
        ),
      ),
    );
  }
}
