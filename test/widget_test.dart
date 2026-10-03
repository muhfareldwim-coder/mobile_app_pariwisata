import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pariwisata/core/theme/app_colors.dart';
import 'package:mobile_pariwisata/data/models/user.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
import 'package:mobile_pariwisata/data/services/payment_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/main.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/login_page.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/register_page.dart';
import 'package:mobile_pariwisata/presentation/pages/article_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/booking_page.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/payment_page.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/explorer_page.dart';
import 'package:mobile_pariwisata/presentation/pages/map/map_page.dart';
import 'package:mobile_pariwisata/presentation/pages/profile/profile_page.dart';
import 'package:mobile_pariwisata/presentation/pages/profile/profile_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/my_ticket_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/qr_ticket_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('aplikasi membuka halaman home', (tester) async {
    await tester.pumpWidget(const PariwisataApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.textContaining('Halo, Petualang!'), findsOneWidget);
  });

  testWidgets('tab utama membuka peta, tiket, dan profil', (tester) async {
    await tester.pumpWidget(const PariwisataApp());

    await tester.tap(find.text('Peta'));
    await tester.pump();
    expect(find.byType(MapPage), findsOneWidget);

    await tester.tap(find.text('Tiket'));
    await tester.pump();
    expect(find.byType(MyTicketPage), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('profil membuka halaman login dan register', (tester) async {
    await tester.pumpWidget(const PariwisataApp());
    await tester.tap(find.text('Profil'));
    await tester.pump();

    await tester.tap(find.byTooltip('Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.ensureVisible(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('profil menampilkan data customer tanpa menyimpan edit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    AuthService.logout();
    addTearDown(AuthService.logout);
    await AuthService().login('budi.santoso@example.com', 'password123');
    await tester.pumpWidget(const PariwisataApp());

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('budi.santoso@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    expect(find.text('Informasi Utama'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Budi Santoso Baru',
    );
    final detailScroll = find
        .descendant(
          of: find.byType(ProfileDetailPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.dragUntilVisible(
      find.text('Simpan Perubahan'),
      detailScroll,
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();
    expect(
      find.text('Penyimpanan profil akan tersedia setelah akun terhubung.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile layout fits the reference mobile width', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    AuthService.currentUser = User.sample;
    addTearDown(AuthService.logout);

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(find.text('Ahmad Pratama'), findsOneWidget);
    final layoutError = tester.takeException();
    expect(layoutError, isNull);
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
    expect(find.byTooltip('Cari destinasi'), findsNothing);
    expect(
      find.text('Pesona Kota Karnaval,\nTembakau & Surga Selatan'),
      findsOneWidget,
    );

    expect(find.text('Alam'), findsOneWidget);
    expect(find.text('Bahari'), findsWidgets);
    expect(find.text('Buatan'), findsOneWidget);
    expect(find.text('Destinasi Populer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header eksplor ikut bergulir bersama daftar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExplorerPage()));

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.style?.color, AppColors.navy);
    expect(searchField.decoration?.hintText, 'Cari nama destinasi atau lokasi');
    expect(searchField.decoration?.hintStyle?.color, AppColors.secondaryText);

    final header = find.byKey(const ValueKey('exploreHeader'));
    final initialTop = tester.getTopLeft(header).dy;
    await tester.drag(
      find.byKey(const ValueKey('exploreList')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(initialTop));
  });

  testWidgets('kategori Home membuka Jelajah dengan filter terpilih', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const PariwisataApp());

    await tester.tap(find.text('Bahari').first);
    await tester.pumpAndSettle();

    expect(find.byType(ExplorerPage), findsOneWidget);
    expect(find.text('2 Ditemukan'), findsOneWidget);
    expect(find.text('Pantai Tanjung Papuma'), findsOneWidget);
  });

  testWidgets('berita punya halaman sendiri dan kategorinya membuka Jelajah', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    final homeScroll = find.byKey(const ValueKey('home-scroll'));
    await tester.dragUntilVisible(
      find.text('Berita & Panduan Wisata'),
      homeScroll,
      const Offset(0, -500),
    );
    final readMore = find.text('Baca Selengkapnya →').first;
    await tester.dragUntilVisible(readMore, homeScroll, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(readMore);
    await tester.pumpAndSettle();

    expect(find.byType(ArticleDetailPage), findsOneWidget);
    expect(find.text('Jelajahi wisata Jember'), findsOneWidget);

    final articleBahari = find.descendant(
      of: find.byType(ArticleDetailPage),
      matching: find.text('Bahari'),
    );
    await tester.ensureVisible(articleBahari);
    await tester.pumpAndSettle();
    await tester.tap(articleBahari);
    await tester.pumpAndSettle();
    expect(find.byType(ExplorerPage), findsOneWidget);
    expect(find.text('2 Ditemukan'), findsOneWidget);
  });

  testWidgets('booking dibayar QRIS dan menerbitkan QR e-ticket', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    TicketService.tickets.clear();
    TicketService.revision.value++;
    PaymentService.payments.clear();
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

    await tester.tap(find.text('Beli Tiket Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingPage), findsOneWidget);

    expect(find.text('Total Pembayaran'), findsOneWidget);
    await tester.tap(find.text('Lanjut Bayar'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentPage), findsOneWidget);
    expect(find.text('Bayar dengan QRIS'), findsOneWidget);
    expect(find.text('Transfer Bank'), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('Saya Sudah Bayar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ini simulasi UI.'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan Simulasi'));
    await tester.pumpAndSettle();

    expect(find.byType(MyTicketPage), findsOneWidget);
    expect(find.text('Tiket Aktif'), findsOneWidget);
    expect(find.textContaining('JMB-'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(PaymentService.payments.single.method, 'QRIS');
    expect(TicketService.tickets, hasLength(1));
    expect(find.byType(QrTicketPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
