import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pariwisata/main.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/login_page.dart';
import 'package:mobile_pariwisata/presentation/pages/home/home_page.dart';

void main() {
  testWidgets('aplikasi membuka halaman login', (tester) async {
    await tester.pumpWidget(const PariwisataApp());

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('halaman home memiliki aksi pemesanan', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Pesan Tiket'), findsOneWidget);
  });
}
