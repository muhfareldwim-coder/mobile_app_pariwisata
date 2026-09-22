import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_form_column.dart';
import '../widgets/auth_shell.dart';
import '../widgets/terms_agreement.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreed = false;
  bool _showAgreementError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _handleSubmit() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _showAgreementError = !_agreed);
    if (formOk && _agreed) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'SISTEM INFORMASI DAN LAYANAN PARIWISATA\nKABUPATEN JEMBER',
          description: 'Masuk untuk menikmati informasi dan layanan\npariwisata Kabupaten Jember',
          fields: [
            AppTextField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Masukkan email yang valid'
                  : null,
            ),
            AppTextField(
              label: 'Password',
              hint: 'Masukkan password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (value) => value == null || value.length < 8
                  ? 'Password minimal 8 karakter'
                  : null,
              suffix: IconButton(
                tooltip: 'Tampilkan password',
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
          agreementSection: TermsAgreement(
            value: _agreed,
            showError: _showAgreementError,
            onChanged: (value) => setState(() {
              _agreed = value;
              if (value) _showAgreementError = false;
            }),
          ),
          buttonLabel: 'Masuk',
          onSubmit: _handleSubmit,
          secondaryAction: _goHome,
          secondaryLabel: 'Lanjutkan dengan Google',
          extraLink: TextButton(
            onPressed: () {},
            child: const Text(
              'Lupa password?',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
          footer: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
              children: [
                const TextSpan(text: 'Belum memiliki akun? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
