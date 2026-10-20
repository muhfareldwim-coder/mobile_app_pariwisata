import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand_logo.dart';

class AuthFormColumn extends StatelessWidget {
  const AuthFormColumn({
    super.key,
    this.eyebrow,
    required this.description,
    required this.fields,
    required this.buttonLabel,
    required this.onSubmit,
    required this.isRegister,
    required this.googleAction,
    required this.guestAction,
    required this.switchAction,
    required this.switchLabel,
    this.forgotAction,
    this.loginOptions,
    this.isSubmitting = false,
    this.isGoogleSubmitting = false,
  });

  final String? eyebrow;
  final String description;
  final List<Widget> fields;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final bool isRegister;
  final VoidCallback googleAction;
  final VoidCallback guestAction;
  final VoidCallback switchAction;
  final String switchLabel;
  final VoidCallback? forgotAction;
  final Widget? loginOptions;
  final bool isSubmitting;
  final bool isGoogleSubmitting;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF173B60);
    const orange = Color(0xFFE77D00);
    const muted = Color(0xFF7890A1);
    final eyebrowText = eyebrow;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandLogo()),
          const SizedBox(height: 12),
          if (eyebrowText != null && eyebrowText.isNotEmpty) ...[
            Text(
              eyebrowText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: orange,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),
          ],
          Text(
            isRegister ? 'Daftar Akun JemberGo' : 'Selamat Datang di JemberGo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: navy,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ...fields.expand((field) => [field, const SizedBox(height: 12)]),
          if (loginOptions != null) ...[
            const SizedBox(height: 1),
            loginOptions!,
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0x33E77D00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 9),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
          if (!isRegister) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFFE5EDF2))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'ATAU',
                    style: TextStyle(
                      color: Color(0xFF9AABB7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFFE5EDF2))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: isGoogleSubmitting ? null : googleAction,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: navy,
                  side: const BorderSide(color: Color(0xFFDbe6ee)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGoogleSubmitting)
                      const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const _GoogleMark(size: 19),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        isGoogleSubmitting
                            ? 'Menghubungkan ke Google...'
                            : 'Lanjutkan dengan Google',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (forgotAction != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: forgotAction,
                  style: TextButton.styleFrom(
                    foregroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Lupa password?'),
                ),
              ),
            TextButton.icon(
              onPressed: guestAction,
              icon: const Icon(Icons.travel_explore, size: 18),
              label: const Text('Jelajahi sebagai tamu'),
              style: TextButton.styleFrom(
                foregroundColor: navy,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  isRegister
                      ? 'Sudah memiliki akun? '
                      : 'Belum memiliki akun? ',
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                TextButton(
                  onPressed: switchAction,
                  style: TextButton.styleFrom(
                    foregroundColor: orange,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                  ),
                  child: Text(
                    switchLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.39;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const gap = 0.08;
    final segments = [
      (const Color(0xFF4285F4), -math.pi / 2 + gap, math.pi / 2 - gap * 2),
      (const Color(0xFFEA4335), -math.pi + gap, math.pi / 2 - gap * 2),
      (const Color(0xFFFBBC05), math.pi / 2 + gap, math.pi / 2 - gap * 2),
      (const Color(0xFF34A853), gap, math.pi / 2 - gap * 2),
    ];

    for (final (color, startAngle, sweepAngle) in segments) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.18
          ..strokeCap = StrokeCap.butt,
      );
    }

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width * 0.94, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.shortestSide * 0.18,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
