import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_form_column.dart';
import '../widgets/auth_shell.dart';
import '../widgets/terms_agreement.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(4, (_) => TextEditingController());
  bool _agreed = false;
  bool _showAgreementError = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;

  void _handleSubmit() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _showAgreementError = !_agreed);
    if (formOk && _agreed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'SISTEM INFORMASI DAN LAYANAN PARIWISATA\nKABUPATEN JEMBER',
          description: 'Daftar untuk mendapatkan akses ke layanan pariwisata\nKabupaten Jember',
          fields: [
            AppTextField(
              label: 'Nama Lengkap',
              hint: 'Nama lengkap',
              controller: _controllers[0],
              validator: _required,
            ),
            AppTextField(
              label: 'Nomor Telepon',
              hint: 'Contoh: 081234567890',
              controller: _controllers[1],
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            AppTextField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: _controllers[2],
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Masukkan email yang valid'
                  : null,
            ),
            AppTextField(
              label: 'Password',
              hint: 'Minimal 8 karakter',
              controller: _controllers[3],
              obscureText: true,
              validator: (value) => value == null || value.length < 8
                  ? 'Password minimal 8 karakter'
                  : null,
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
          buttonLabel: 'Daftar',
          onSubmit: _handleSubmit,
          footer: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
              children: [
                const TextSpan(text: 'Sudah memiliki akun? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Masuk',
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
