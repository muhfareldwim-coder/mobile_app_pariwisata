import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_form_column.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/terms_agreement.dart';

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
	bool _agreed = false;
	bool _obscurePassword = true;

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _login() async {
		if (!(_formKey.currentState?.validate() ?? false) || !_agreed) return;
		final user = await _authService.login(_emailController.text.trim(), _passwordController.text);
		if (!mounted || user == null) return;
		Navigator.pushReplacementNamed(context, AppRoutes.home);
	}

	@override
	Widget build(BuildContext context) {
		return AuthShell(
			form: Form(
				key: _formKey,
				child: AuthFormColumn(
					eyebrow: 'JEMBERGO',
					description: 'Masuk untuk memesan tiket wisata Kabupaten Jember',
					fields: [
						AppTextField(label: 'Email', hint: 'nama@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: (value) => value != null && value.contains('@') ? null : 'Masukkan email yang valid'),
						AppTextField(label: 'Password', hint: 'Minimal 8 karakter', controller: _passwordController, obscureText: _obscurePassword, validator: (value) => value != null && value.length >= 8 ? null : 'Password minimal 8 karakter', suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
					],
					agreementSection: TermsAgreement(value: _agreed, onChanged: (value) => setState(() => _agreed = value)),
					buttonLabel: 'Masuk',
					onSubmit: _login,
					secondaryAction: () => Navigator.pushNamed(context, AppRoutes.register),
					secondaryLabel: 'Belum punya akun? Daftar',
					footer: const Text('Gunakan akun yang sudah terdaftar', style: TextStyle(color: AppColors.muted)),
				),
			),
		);
	}
}