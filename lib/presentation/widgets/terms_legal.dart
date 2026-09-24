import 'package:flutter/material.dart';

class TermsLegal extends StatelessWidget {
  const TermsLegal({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Saya menyetujui syarat dan ketentuan'),
    );
  }
}