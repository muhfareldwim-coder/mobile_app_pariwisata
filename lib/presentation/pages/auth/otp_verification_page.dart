import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_shell.dart';

enum OtpPurpose { registration, google }

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.purpose,
    this.rememberMe = true,
  });

  final String email;
  final OtpPurpose purpose;
  final bool rememberMe;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isVerifying = false;
  bool _isResending = false;

  String get _apiPurpose =>
      widget.purpose == OtpPurpose.google ? 'google' : 'registration';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isVerifying || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isVerifying = true);
    try {
      if (widget.purpose == OtpPurpose.google) {
        await _authService.verifyGoogleOtp(
          widget.email,
          _otpController.text,
          rememberMe: widget.rememberMe,
        );
      } else {
        await _authService.verifyRegistrationOtp(
          widget.email,
          _otpController.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_isResending || _isVerifying) return;
    setState(() => _isResending = true);
    try {
      await _authService.resendOtp(widget.email, _apiPurpose);
      if (mounted) _showMessage('Kode OTP baru telah dikirim.');
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isGoogle = widget.purpose == OtpPurpose.google;

    return AuthShell(
      form: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: AppColors.orange,
            ),
            const SizedBox(height: 14),
            Text(
              isGoogle ? 'Verifikasi akun Google' : 'Verifikasi email',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF173B60),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan kode 6 digit yang dikirim ke ${widget.email}. Kode berlaku selama 10 menit.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7890A1),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verifikasi OTP'),
              ),
            ),
            TextButton(
              onPressed: _isResending || _isVerifying ? null : _resend,
              style: TextButton.styleFrom(foregroundColor: AppColors.orange),
              child: _isResending
                  ? const Text('Mengirim ulang kode...')
                  : const Text('Kirim ulang kode OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
