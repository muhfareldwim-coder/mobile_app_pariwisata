import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_form_column.dart';
import '../../widgets/auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted || user == null) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'GERBANG WISATA BUMI PANDHALUNGAN',
          description: 'Jelajahi keindahan pesona alam, budaya, dan pesisir Kabupaten Jember',
          isRegister: false,
          fields: [
            AppTextField(
              label: 'Email atau Nama Pengguna',
              hint: 'nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline,
              validator: (value) => value != null && value.trim().isNotEmpty
                  ? null
                  : 'Masukkan email atau nama pengguna',
            ),
            AppTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi akun',
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
          ],
          loginOptions: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: const Color(0xFF1265B8),
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                ),
              ),
              const SizedBox(width: 6),
              const Text('Ingat Saya'),
            ],
          ),
          forgotAction: _showUnavailable,
          buttonLabel: 'Masuk Sekarang',
          onSubmit: _login,
          googleAction: _showUnavailable,
          guestAction: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
          switchAction: () => Navigator.pushNamed(context, AppRoutes.register),
          switchLabel: 'Daftar Sekarang',
        ),
      ),
    );
  }
}
