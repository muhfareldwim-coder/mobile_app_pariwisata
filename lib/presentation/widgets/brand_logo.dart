import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_jembergonobackgroud.png',
      width: 150,
      height: 52,
      fit: BoxFit.contain,
    );
  }
}
