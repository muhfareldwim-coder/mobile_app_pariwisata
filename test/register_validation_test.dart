import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/register_page.dart';

void main() {
  testWidgets('registration fields match the website order and copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RegisterPage())),
    );

    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Nomor Telepon'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
