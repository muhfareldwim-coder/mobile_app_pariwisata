import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/language_preference_service.dart';
import '../main_navigation_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.locationProvider});

  final Future<LatLng?> Function()? locationProvider;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait<void>([
      AuthService.restoreSession(),
      LanguagePreferenceService.restore(),
      Future<void>.delayed(const Duration(seconds: 5)),
    ]);
  }

  void _retry() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupErrorPage(error: snapshot.error!, onRetry: _retry);
        }

        final isReady = snapshot.connectionState == ConnectionState.done;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: isReady
              ? MainNavigationPage(
                  key: const ValueKey('main-navigation'),
                  locationProvider: widget.locationProvider,
                )
              : const _LoadingPage(key: ValueKey('loading')),
        );
      },
    );
  }
}

class _LoadingPage extends StatefulWidget {
  const _LoadingPage({super.key});

  @override
  State<_LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<_LoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _verticalOffset;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _verticalOffset = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mascotHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFEFC), AppColors.bg],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -54,
                  right: -54,
                  width: 210,
                  height: 210,
                  child: IgnorePointer(
                    child: CustomPaint(painter: _CornerPatternPainter()),
                  ),
                ),
                Positioned(
                  bottom: -54,
                  left: -54,
                  width: 210,
                  height: 210,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: math.pi,
                      child: CustomPaint(painter: _CornerPatternPainter()),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFE6C6), Color(0xFFE7F4FA)],
                      ),
                      border: Border.all(
                        color: AppColors.ocean.withValues(alpha: 0.48),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ocean.withValues(alpha: 0.12),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _verticalOffset,
                  child: SizedBox(
                    height: mascotHeight,
                    child: Image.asset(
                      'assets/maskot.png',
                      fit: BoxFit.contain,
                      semanticLabel: 'Maskot JemberGo',
                    ),
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _verticalOffset.value),
                    child: child,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'JemberGo',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jelajahi keindahan Jember',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.text),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.86),
                          border: Border.all(
                            color: AppColors.ocean.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Menyiapkan perjalananmu...',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.text),
                      ),
                      const SizedBox(height: 16),
                    ],
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

class _CornerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final flowerPaint = Paint()
      ..color = const Color(0x24316A91)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = const Color(0x2BF58B05)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0x18316A91)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final motifCenters = [
      Offset(size.width * 0.72, size.height * 0.22),
      Offset(size.width * 0.34, size.height * 0.58),
      Offset(size.width * 0.82, size.height * 0.82),
    ];

    canvas.drawPath(
      Path()
        ..moveTo(motifCenters[0].dx, motifCenters[0].dy)
        ..quadraticBezierTo(
          size.width * 0.52,
          size.height * 0.43,
          motifCenters[1].dx,
          motifCenters[1].dy,
        )
        ..quadraticBezierTo(
          size.width * 0.62,
          size.height * 0.72,
          motifCenters[2].dx,
          motifCenters[2].dy,
        ),
      linePaint,
    );

    for (var index = 0; index < motifCenters.length; index++) {
      final center = motifCenters[index];
      final radius = index == 1 ? 17.0 : 13.0;
      for (var petal = 0; petal < 8; petal++) {
        final angle = petal * math.pi / 4;
        canvas.drawCircle(
          center +
              Offset(
                math.cos(angle) * radius * 0.62,
                math.sin(angle) * radius * 0.62,
              ),
          radius * 0.26,
          flowerPaint,
        );
      }
      canvas.drawCircle(center, radius * 0.22, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPatternPainter oldDelegate) => false;
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/maskot.png',
                  height: 260,
                  fit: BoxFit.contain,
                  semanticLabel: 'Maskot JemberGo',
                ),
                const SizedBox(height: 20),
                Text(
                  'JemberGo belum bisa dibuka',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
