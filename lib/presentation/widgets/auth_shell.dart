import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const pagePadding = 20.0;
            final minContentHeight = (constraints.maxHeight - pagePadding * 2)
                .clamp(0.0, double.infinity);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(pagePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE7ECF2)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10233F55),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: form,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
