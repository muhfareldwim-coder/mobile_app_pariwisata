import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_mobile_latest.png',
      width: 112,
      height: 112,
      fit: BoxFit.contain,
      semanticLabel: 'JemberGo',
    );
  }
}
