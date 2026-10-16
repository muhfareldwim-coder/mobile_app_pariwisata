import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/booking_page.dart';

void main() {
  Destination testDestination() => Destination(
    id: '42',
    name: 'Pantai Papuma',
    location: 'Jember',
    latitude: -8.4,
    longitude: 113.5,
    routeDistanceKm: 0,
    ticketTypes: const [
      DestinationTicketType(id: 8, name: 'Reguler', price: 25000),
    ],
  );

  testWidgets('booking follows website date and participant flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: BookingPage(destination: testDestination())),
    );

    expect(find.text('Pemesanan Tiket'), findsOneWidget);
    expect(find.text('Pilih tanggal kunjungan'), findsOneWidget);
    expect(find.text('Nama Lengkap (Ketua) *'), findsOneWidget);
    expect(find.text('Alamat Email *'), findsOneWidget);
    expect(find.text('Nomor WhatsApp / HP *'), findsOneWidget);
    expect(find.byTooltip('Profil'), findsNothing);

    await tester.tap(find.text('Lanjut Bayar'));
    await tester.pump();
    expect(
      find.text('Pilih tanggal kunjungan terlebih dahulu.'),
      findsOneWidget,
    );

    await tester.dragUntilVisible(
      find.text('Tambah anggota'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah anggota'));
    await tester.pumpAndSettle();
    expect(find.text('Peserta 2'), findsOneWidget);
    expect(find.text('0/10 orang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking validates leader details with website rules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: BookingPage(destination: testDestination())),
    );

    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Wajib diisi'), findsNWidgets(3));

    await tester.enterText(find.byType(TextFormField).at(0), 'Nama 123');
    await tester.enterText(find.byType(TextFormField).at(1), 'bukan-email');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    expect(form.validate(), isFalse);
    await tester.pump();

    expect(
      find.text('Nama lengkap hanya boleh berisi huruf dan spasi.'),
      findsOneWidget,
    );
    expect(
      find.text('Email harus menggunakan alamat @gmail.com.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Gunakan 10-12 digit lokal atau awali + untuk nomor internasional (maksimal 15 digit).',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
