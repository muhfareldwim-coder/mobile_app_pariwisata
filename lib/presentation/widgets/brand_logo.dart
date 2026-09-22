import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_jembergonobackgroud.png',
      width: 620,
      height: 190,
      fit: BoxFit.contain,
    );
  }
}
