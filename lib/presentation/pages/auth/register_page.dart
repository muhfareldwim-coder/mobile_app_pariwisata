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
	final _authService = AuthService();
	bool _agreed = false;

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _register() async {
		if (!(_formKey.currentState?.validate() ?? false) || !_agreed) return;
		await _authService.register(_nameController.text.trim(), _emailController.text.trim(), _passwordController.text);
		if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
	}

	@override
	Widget build(BuildContext context) {
		String? requiredValue(String? value) => value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;
		return AuthShell(form: Form(key: _formKey, child: AuthFormColumn(eyebrow: 'BUAT AKUN', description: 'Daftar untuk memesan tiket wisata', fields: [
			AppTextField(label: 'Nama', hint: 'Nama lengkap', controller: _nameController, validator: requiredValue),
			AppTextField(label: 'Email', hint: 'nama@email.com', controller: _emailController, validator: (value) => value != null && value.contains('@') ? null : 'Masukkan email yang valid'),
			AppTextField(label: 'Password', hint: 'Minimal 8 karakter', controller: _passwordController, obscureText: true, validator: (value) => value != null && value.length >= 8 ? null : 'Password minimal 8 karakter'),
		], agreementSection: TermsAgreement(value: _agreed, onChanged: (value) => setState(() => _agreed = value)), buttonLabel: 'Daftar', onSubmit: _register, secondaryAction: () => Navigator.pushReplacementNamed(context, AppRoutes.login), secondaryLabel: 'Sudah punya akun? Masuk', footer: const SizedBox.shrink())));
	}
}