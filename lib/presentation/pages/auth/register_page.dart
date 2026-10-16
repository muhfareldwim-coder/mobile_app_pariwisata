import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_form_column.dart';
import '../../widgets/auth_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
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
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'SISTEM INFORMASI DAN LAYANAN PARIWISATA KABUPATEN JEMBER',
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
