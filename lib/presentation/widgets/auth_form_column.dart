import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'brand_logo.dart';

class AuthFormColumn extends StatelessWidget {
  const AuthFormColumn({
    super.key,
    required this.eyebrow,
    required this.description,
    required this.fields,
    required this.buttonLabel,
    required this.onSubmit,
    this.secondaryAction,
    this.secondaryLabel,
    required this.footer,
    this.extraLink,
    this.agreementSection,
  });

  final String eyebrow;
  final String description;
  final List<Widget> fields;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final VoidCallback? secondaryAction;
  final String? secondaryLabel;
  final Widget footer;
  final Widget? extraLink;
  final Widget? agreementSection;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BrandLogo()),
            const SizedBox(height: 48),
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ...fields.expand((field) => [field, const SizedBox(height: 14)]),
            if (agreementSection != null) ...[
              const SizedBox(height: 4),
              agreementSection!,
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            if (extraLink != null)
              Align(alignment: Alignment.centerRight, child: extraLink!),
            if (secondaryAction != null) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'atau',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: secondaryAction,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  label: Text(
                    secondaryLabel!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Center(child: footer),
          ],
        ),
      ),
    );
  }
}
