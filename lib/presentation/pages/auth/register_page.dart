import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_form_column.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/terms_agreement.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _agreed = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia.')));
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_agreed) return;
    await _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    String? requiredValue(String? value) =>
        value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'WISATA • BUDAYA • PETUALANGAN',
          description: 'Mulai petualangan baru di alam Jember',
          isRegister: true,
          fields: [
            AppTextField(
              label: 'Nama Lengkap',
              hint: 'misal: Ahmad Pratama',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              validator: requiredValue,
            ),
            AppTextField(
              label: 'Email Aktif',
              hint: 'misal: ahmad.pratama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline,
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : 'Masukkan email yang valid',
            ),
            AppTextField(
              label: 'Kata Sandi Baru',
              hint: 'Minimal 8 karakter unik',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
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
            AppTextField(
              label: 'Konfirmasi Kata Sandi',
              hint: 'Ulangi kata sandi Anda',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.check_box_outlined,
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'Konfirmasi kata sandi tidak sama',
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
          ],
          agreementSection: TermsAgreement(
            value: _agreed,
            onChanged: (value) => setState(() => _agreed = value),
          ),
          buttonLabel: 'Buat Akun JemberGo',
          onSubmit: _register,
          googleAction: _showUnavailable,
          guestAction: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
          switchAction: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.login),
          switchLabel: 'Masuk di sini',
        ),
      ),
    );
  }
}
