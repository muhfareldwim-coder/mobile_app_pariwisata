import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pariwisata/core/utils/date_formatters.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/core/theme/app_colors.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/models/user.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/article_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
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

void main() {
  testWidgets('aplikasi membuka halaman home', (tester) async {
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.textContaining('Halo, Petualang!'), findsOneWidget);
    expect(
      formatIndonesianDate(DateTime(2026, 10, 21)),
      'Rabu, 21 Oktober 2026',
    );
    final localizedDate = MaterialLocalizations.of(
      tester.element(find.byType(HomePage)),
    ).formatMediumDate(DateTime(2026, 10, 21));
    expect(localizedDate, contains('Okt'));
    expect(localizedDate, isNot(contains('Oct')));
  });

  testWidgets('tab utama membuka peta, tiket, dan profil', (tester) async {
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

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
    AuthService.logout();
    addTearDown(AuthService.logout);
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));
    await tester.tap(find.text('Profil'));
    await tester.pump();

    expect(find.text('Mode Tamu'), findsOneWidget);
    await tester.tap(find.byTooltip('Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.ensureVisible(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar'));
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
    AuthService.currentUser = User.sample.copyWith(
      name: 'Budi Santoso',
      email: 'budi.santoso@example.com',
      username: 'budisantoso',
    );
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('budi.santoso@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    expect(find.text('Informasi Utama'), findsOneWidget);
    expect(find.textContaining('Foto profil gagal dimuat'), findsNothing);
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

    await tester.pumpWidget(
      MaterialApp(home: HomePage(locationProvider: () async => null)),
    );

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
    await tester.scrollUntilVisible(
      find.text('Destinasi Terdekat'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Destinasi Terdekat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destinasi terdekat di Home membuka detail destinasi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: HomePage(locationProvider: () async => null)),
    );

    expect(find.text('Pantai Tanjung Papuma'), findsWidgets);
    await tester.tap(find.text('Pantai Tanjung Papuma').first);
    await tester.pumpAndSettle();

    expect(find.text('Tentang Destinasi'), findsOneWidget);
    expect(find.text('Lokasi & rute'), findsOneWidget);
    expect(find.text('Fasilitas'), findsOneWidget);
    expect(find.text('Jenis tiket'), findsOneWidget);
    expect(find.text('Galeri Pantai Tanjung Papuma'), findsOneWidget);
    expect(find.text('Ulasan pengunjung'), findsOneWidget);
    expect(find.text('Buka lokasi di OpenStreetMap'), findsNothing);
    expect(
      find.text(
        'Masuk dengan akun pembeli tiket untuk memberi rating dan ulasan.',
      ),
      findsNothing,
    );

    final sectionOrder = [
      'Tentang Destinasi',
      'Lokasi & rute',
      'Fasilitas',
      'Jenis tiket',
      'Galeri Pantai Tanjung Papuma',
      'Ulasan pengunjung',
    ].map((title) => tester.getTopLeft(find.text(title).first).dy).toList();
    expect(sectionOrder, orderedEquals(sectionOrder.toList()..sort()));
  });

  testWidgets('tombol favorit destinasi populer dapat diaktifkan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: HomePage(locationProvider: () async => null)),
    );

    final addFavorite = find.byTooltip(
      'Tambahkan Pantai Tanjung Papuma ke favorit',
    );
    expect(addFavorite, findsOneWidget);
    await tester.tap(addFavorite);
    await tester.pump();

    expect(
      find.byTooltip('Hapus Pantai Tanjung Papuma dari favorit'),
      findsOneWidget,
    );
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('header eksplor ikut bergulir bersama daftar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExplorerPage()));

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.style?.color, AppColors.navy);
    expect(searchField.decoration?.hintText, 'Cari lokasi wisata di peta...');
    expect(searchField.decoration?.hintStyle?.color, const Color(0xFF6B625C));

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
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

    await tester.tap(find.text('Bahari').first);
    await tester.pumpAndSettle();

    expect(find.byType(ExplorerPage), findsOneWidget);
    expect(find.text('3 Ditemukan'), findsOneWidget);
    expect(find.text('Pantai Tanjung Papuma'), findsOneWidget);
  });

  testWidgets('beranda and detail use articles loaded from the website API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final articleService = ArticleService(
      api: ApiService(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/artikel');
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 12,
                  'judul': 'Artikel resmi dari website',
                  'isi': 'Konten artikel dari website.',
                  'gambar': null,
                  'tanggal_publikasi': '2026-10-15T09:30:00+07:00',
                },
              ],
            }),
            200,
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          articleService: articleService,
          locationProvider: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final homeScroll = find.byKey(const ValueKey('home-scroll'));
    await tester.dragUntilVisible(
      find.text('Berita & Panduan Wisata'),
      homeScroll,
      const Offset(0, -500),
    );
    expect(find.text('Artikel resmi dari website'), findsOneWidget);
    final readMore = find.text('Baca selengkapnya →').first;
    await tester.dragUntilVisible(readMore, homeScroll, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(readMore);
    await tester.pumpAndSettle();

    expect(find.byType(ArticleDetailPage), findsOneWidget);
    expect(find.text('Konten artikel dari website.'), findsOneWidget);
    expect(find.text('Jelajahi wisata Jember'), findsNothing);
  });

  testWidgets('booking tanpa tipe tiket dari API tidak memakai data simulasi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BookingPage(
          destination: Destination(
            id: 'sample-destination',
            name: 'Pantai Papuma',
            location: 'Jember',
            latitude: -8.4,
            longitude: 113.5,
            routeDistanceKm: 0,
          ),
        ),
      ),
    );

    expect(
      find.text('Pilihan tiket belum tersedia dari server.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lanjut Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Jenis tiket destinasi belum tersedia.'), findsOneWidget);
    expect(find.byType(PaymentPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
