import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pariwisata/main.dart';

void main() {
  testWidgets('aplikasi membuka halaman home', (tester) async {
    await tester.pumpWidget(const PariwisataApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.textContaining('Halo, Petualang!'), findsOneWidget);
  });

  testWidgets('beranda memakai konten resmi JemberGo di layar sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.byType(HomePage), findsOneWidget);
    final header = find.byKey(const ValueKey('home-header'));
    expect(tester.getTopLeft(header).dx, 0);
    expect(tester.getSize(header).width, 320);
    expect(find.byTooltip('Cari destinasi'), findsOneWidget);
    expect(
      find.text('Pesona Kota Karnaval,\nTembakau & Surga Selatan'),
      findsOneWidget,
    );

    expect(find.text('Alam'), findsOneWidget);
    expect(find.text('Bahari'), findsOneWidget);
    expect(find.text('Buatan'), findsOneWidget);
    expect(find.text('Destinasi Populer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
