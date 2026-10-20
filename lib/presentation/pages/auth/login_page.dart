import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  static Future<void>? _googleSignInInitialization;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );
      _completeLogin();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isSubmitting) return;
    if (kIsWeb) {
      _showMessage('Login Google tersedia melalui aplikasi Android atau iOS.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isGoogleSubmitting = true;
    });
    try {
      final serverClientId = await _authService.googleSignInServerClientId();
      _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      try {
        await _googleSignInInitialization;
      } on Exception {
        _googleSignInInitialization = null;
        rethrow;
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const FormatException(
          'Google tidak mengembalikan token akun. Periksa konfigurasi OAuth aplikasi.',
        );
      }

      await _authService.loginWithGoogleIdToken(
        idToken,
        rememberMe: _rememberMe,
      );
      _completeLogin();
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled && mounted) {
        _showMessage(error.toString());
      }
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isGoogleSubmitting = false;
        });
      }
    }
  }

  void _completeLogin() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPasswordRecoveryUnavailable() {
    _showMessage('Pemulihan kata sandi belum tersedia di aplikasi.');
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.pushNamed(context, AppRoutes.register);
    if (!mounted ||
        registered != true ||
        AuthService.currentUser == null ||
        !Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          description: 'Masuk untuk menikmati informasi dan layanan pariwisata Kabupaten Jember',
          isRegister: false,
          fields: [
            AppTextField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.trim().contains('@')
                  ? null
                  : 'Masukkan email yang valid',
            ),
            AppTextField(
              label: 'Kata Sandi',
              hint: 'Masukkan password',
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
              const Flexible(
                child: Text(
                  'Ingat Saya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          forgotAction: _showPasswordRecoveryUnavailable,
          buttonLabel: 'Masuk',
          isSubmitting: _isSubmitting,
          isGoogleSubmitting: _isGoogleSubmitting,
          onSubmit: _login,
          googleAction: _loginWithGoogle,
          guestAction: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
          switchAction: _openRegister,
          switchLabel: 'Daftar',
        ),
      ),
    );
  }
}
