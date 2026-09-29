import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Align(alignment: Alignment.topCenter, child: form),
        ),
      ),
    );
  }
}
