import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/login_page.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/register_page.dart';

void main() {
  testWidgets('mobile login and register layouts fit without overflow', (
    tester,
  ) async {
    final cases = [
      (const Size(360, 800), const LoginPage()),
      (const Size(320, 640), const RegisterPage()),
    ];

    for (final (size, page) in cases) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pump();

      expect(find.byType(TextFormField), findsWidgets);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
  });
}
