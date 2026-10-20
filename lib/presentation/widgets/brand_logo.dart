import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_jembergonobackgroud.png',
      width: 240,
      height: 105,
      fit: BoxFit.cover,
    );
  }
}
