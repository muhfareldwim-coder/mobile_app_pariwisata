import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final errorColor = showError ? AppColors.danger : AppColors.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(!value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                border: showError
                    ? Border.all(color: AppColors.danger.withValues(alpha: .4))
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: value,
                      onChanged: (v) => onChanged(v ?? false),
                      activeColor: AppColors.orange,
                      side: BorderSide(color: errorColor, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Saya telah membaca dan menyetujui ',
                            ),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' JemberGo.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showError)
            const Padding(
              padding: EdgeInsets.only(left: 32, top: 2),
              child: Text(
                'Kamu harus menyetujui syarat & ketentuan terlebih dahulu',
                style: TextStyle(color: AppColors.danger, fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }
}
