// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_pariwisata/main.dart';
import 'package:mobile_pariwisata/presentation/pages/explorer_page.dart';

void main() {
  testWidgets('menampilkan halaman login pariwisata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PariwisataApp());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
  });

  testWidgets('beranda dapat discroll vertikal dan horizontal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(-180, 0));
    await tester.pumpAndSettle();

    expect(find.text('Destinasi Terdekat'), findsOneWidget);
    expect(find.text('Berita & Panduan Wisata'), findsOneWidget);
    expect(
      find.text(
        'Platform pariwisata digital terintegrasi untuk Kabupaten Jember, Jawa Timur.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('explorer menampilkan destinasi dan dapat membuka peta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExplorerPage()));
    await tester.pumpAndSettle();

    expect(find.text('Eksplor Destinasi'), findsOneWidget);
    expect(find.text('Pantai Tanjung Papuma'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.map_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Ketuk pin untuk melihat detail destinasi'), findsOneWidget);
  });
}
