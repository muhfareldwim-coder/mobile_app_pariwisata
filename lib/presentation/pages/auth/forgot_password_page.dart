import 'package:flutter/material.dart';

import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_shell.dart';

enum _ResetStage { email, otp, password }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _authService = AuthService();
  _ResetStage _stage = _ResetStage.email;
  bool _isSubmitting = false;
  String? _resetToken;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      switch (_stage) {
        case _ResetStage.email:
          await _authService.requestPasswordResetOtp(_emailController.text);
          if (mounted) {
            setState(() => _stage = _ResetStage.otp);
            _showMessage('Jika email terdaftar, kode OTP telah dikirim.');
          }
          break;
        case _ResetStage.otp:
          _resetToken = await _authService.verifyPasswordResetOtp(
            _emailController.text,
            _otpController.text,
          );
          if (mounted) {
            setState(() => _stage = _ResetStage.password);
          }
          break;
        case _ResetStage.password:
          final token = _resetToken;
          if (token == null) {
            throw ApiException(
              'Verifikasi OTP tidak tersedia. Mulai ulang proses reset password.',
            );
          }
          await _authService.resetPassword(
            email: _emailController.text,
            resetToken: token,
            password: _passwordController.text,
            passwordConfirmation: _confirmationController.text,
          );
          if (mounted) Navigator.pop(context, true);
          break;
      }
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _authService.resendOtp(_emailController.text, 'password_reset');
      if (mounted) {
        _showMessage('Jika email terdaftar, kode OTP telah dikirim.');
      }
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String get _title => switch (_stage) {
    _ResetStage.email => 'Lupa password?',
    _ResetStage.otp => 'Verifikasi OTP',
    _ResetStage.password => 'Buat password baru',
  };

  String get _buttonLabel => switch (_stage) {
    _ResetStage.email => 'Kirim kode OTP',
    _ResetStage.otp => 'Verifikasi OTP',
    _ResetStage.password => 'Simpan password',
  };

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF173B60),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              switch (_stage) {
                _ResetStage.email =>
                  'Masukkan email akun Anda untuk menerima kode OTP.',
                _ResetStage.otp =>
                  'Masukkan kode 6 digit yang dikirim ke ${_emailController.text}.',
                _ResetStage.password => 'Gunakan password minimal 8 karakter.',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7890A1),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (_stage == _ResetStage.email)
              AppTextField(
                label: 'Email',
                hint: 'nama@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
            if (_stage == _ResetStage.otp) ...[
              AppTextField(
                label: 'Kode OTP',
                hint: '6 digit',
                controller: _otpController,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value != null && RegExp(r'^\d{6}$').hasMatch(value.trim())
                    ? null
                    : 'Masukkan kode OTP 6 digit.',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _resend,
                  child: const Text('Kirim ulang kode OTP'),
                ),
              ),
            ],
            if (_stage == _ResetStage.password) ...[
              AppTextField(
                label: 'Password baru',
                hint: 'Minimal 8 karakter',
                controller: _passwordController,
                obscureText: true,
                validator: (value) => value != null && value.length >= 8
                    ? null
                    : 'Password minimal 8 karakter.',
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Konfirmasi password',
                hint: 'Ulangi password baru',
                controller: _confirmationController,
                obscureText: true,
                validator: (value) => value == _passwordController.text
                    ? null
                    : 'Konfirmasi password tidak sama.',
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Masukkan email yang valid.';
  }
}
