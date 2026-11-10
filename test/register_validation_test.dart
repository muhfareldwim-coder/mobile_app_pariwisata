import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
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
    expect(find.text('Daftar Akun JemberGo'), findsNothing);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    expect(find.text('Konfirmasi Kata Sandi'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a clear dialog for a duplicate email from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final api = ApiService(
      baseUrl: 'http://localhost/api/v1',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The email has already been taken.',
            'errors': {
              'email': ['The email has already been taken.'],
            },
          }),
          422,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegisterPage(authService: AuthService(api: api)),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Joko');
    await tester.enterText(fields.at(1), '087765711240');
    await tester.enterText(fields.at(2), 'joko@gmail.com');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Pendaftaran belum berhasil'), findsOneWidget);
    expect(find.text('Alamat email tersebut sudah terdaftar.'), findsOneWidget);
    expect(find.text('Mengerti'), findsOneWidget);
  });
}
