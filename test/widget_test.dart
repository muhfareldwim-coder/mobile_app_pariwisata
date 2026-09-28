import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pariwisata/main.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/booking_page.dart';
import 'package:mobile_pariwisata/presentation/pages/home/home_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/ticket_ui_page.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/explorer_page.dart';

void main() {
  setUp(TicketService.tickets.clear);

  testWidgets('aplikasi membuka halaman booking', (tester) async {
    await tester.pumpWidget(const PariwisataApp());
    await tester.pumpAndSettle();

    expect(find.byType(BookingPage), findsOneWidget);
    expect(find.text('Pilih jumlah tiket'), findsOneWidget);
    expect(find.text('Lanjut bayar'), findsOneWidget);
  });

  testWidgets('form pemesanan tervalidasi sebelum lanjut', (tester) async {
    await tester.pumpWidget(const PariwisataApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut bayar'));
    await tester.pumpAndSettle();

    expect(find.text('Bagian ini wajib diisi'), findsWidgets);
    expect(find.byType(BookingPage), findsOneWidget);
  });

  testWidgets('data pemesan diteruskan ke ringkasan checkout', (tester) async {
    await tester.pumpWidget(const PariwisataApp());
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).at(0);
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Ayu Lestari');
    final emailField = find.byType(TextFormField).at(1);
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'ayu@example.com');
    final phoneField = find.byType(TextFormField).at(2);
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '081234567890');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.text('Lanjut bayar'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan pesanan'), findsOneWidget);
    expect(find.text('Ayu Lestari'), findsOneWidget);
    expect(find.text('ayu@example.com'), findsOneWidget);
  });

  testWidgets('pembayaran selesai lalu menampilkan tiket terbit', (
    tester,
  ) async {
    await tester.pumpWidget(const PariwisataApp());
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).at(0);
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Ayu Lestari');
    final emailField = find.byType(TextFormField).at(1);
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'ayu@example.com');
    final phoneField = find.byType(TextFormField).at(2);
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '081234567890');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.text('Lanjut bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Pembayaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar Sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(TicketUIPage), findsOneWidget);
    expect(find.text('Pantai Tanjung Papuma'), findsWidgets);
    expect(find.text('Tiket Aktif'), findsOneWidget);
  });

  testWidgets('tab riwayat membuka empty state dan jelajah', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TicketUIPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riwayat Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tiket selesai'), findsOneWidget);
    await tester.tap(find.text('Jelajahi wisata'));
    await tester.pumpAndSettle();

    expect(find.byType(ExplorerPage), findsOneWidget);
  });

  testWidgets('QR penuh menampilkan kode tiket yang dapat dipindai', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TicketUIPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('QR Penuh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QR Penuh'));
    await tester.pumpAndSettle();

    expect(find.text('Tiket JMB-2026-88910'), findsOneWidget);
  });

  testWidgets('riwayat contoh membuka detail tiket', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TicketUIPage()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Puncak Rembangan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Puncak Rembangan'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Tiket'), findsOneWidget);
    expect(find.textContaining('JMB-2026-77802'), findsOneWidget);
  });

  testWidgets('tombol PDF membuat tiket dan memberi hasil jelas', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TicketUIPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Unduh PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unduh PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Unduh PDF hanya tersedia di browser.'), findsOneWidget);
  });

  testWidgets('navigasi bawah membuka halaman jelajah', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TicketUIPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jelajah'));
    await tester.pumpAndSettle();

    expect(find.byType(ExplorerPage), findsOneWidget);
  });

  testWidgets('halaman home memiliki aksi pemesanan', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Pesan Tiket'), findsOneWidget);
  });
}
