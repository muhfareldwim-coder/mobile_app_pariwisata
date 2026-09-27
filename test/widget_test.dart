import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pariwisata/main.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/login_page.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/explorer_page.dart';

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

  testWidgets('header eksplor ikut bergulir bersama daftar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExplorerPage()));

    final header = find.byKey(const ValueKey('exploreHeader'));
    final initialTop = tester.getTopLeft(header).dy;
    await tester.drag(
      find.byKey(const ValueKey('exploreList')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(initialTop));
  });

  testWidgets('eksplor memfilter destinasi dan membuka detail', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExplorerPage()));

    expect(find.text('6 Ditemukan'), findsOneWidget);
    await tester.tap(find.text('Bahari'));
    await tester.pumpAndSettle();
    expect(find.text('2 Ditemukan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Papuma');
    await tester.pumpAndSettle();
    expect(find.text('1 Ditemukan'), findsOneWidget);

    await tester.tap(find.text('Pantai Tanjung Papuma'));
    await tester.pumpAndSettle();
    expect(find.text('Pesona & Deskripsi'), findsOneWidget);
  });
}
