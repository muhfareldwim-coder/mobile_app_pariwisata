import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_pariwisata/core/utils/date_formatters.dart';
import 'package:mobile_pariwisata/core/routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/destination_data.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/models/user.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/article_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
import 'package:mobile_pariwisata/data/services/destination_service.dart';
import 'package:mobile_pariwisata/data/services/favorite_destination_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/main.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/login_page.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/register_page.dart';
import 'package:mobile_pariwisata/presentation/pages/article_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/booking_page.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/payment_page.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/destination_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/explorer_page.dart';
import 'package:mobile_pariwisata/presentation/pages/map/map_page.dart';
import 'package:mobile_pariwisata/presentation/pages/profile/profile_page.dart';
import 'package:mobile_pariwisata/presentation/pages/profile/profile_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/my_ticket_page.dart';

void main() {
  testWidgets('aplikasi membuka halaman home', (tester) async {
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('JemberGo'), findsOneWidget);
    expect(find.text('Selamat datang, Petualang'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('ticket-header')), findsOneWidget);
    expect(find.text('Kelola tiket dan pesanan perjalananmu.'), findsOneWidget);
    expect(find.byTooltip('Profil'), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('tiket untuk tamu meminta login dan membuka halaman login', (
    tester,
  ) async {
    AuthService.logout();
    TicketService.tickets.clear();
    TicketService.revision.value++;
    addTearDown(AuthService.logout);
    await tester.pumpWidget(
      MaterialApp(home: const MyTicketPage(), routes: AppRoutes.routes),
    );
    await tester.pumpAndSettle();
    expect(find.text('login untuk memulai perjalananmu.'), findsOneWidget);
    await tester.tap(find.text('Login sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('profil membuka halaman login dan register', (tester) async {
    AuthService.logout();
    addTearDown(AuthService.logout);
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));
    await tester.tap(find.text('Profil'));
    await tester.pump();

    expect(find.text('Mode Tamu'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-header')), findsOneWidget);
    final profileHeader = tester.widget<Container>(
      find.byKey(const ValueKey('profile-header')),
    );
    expect(
      (profileHeader.decoration as BoxDecoration).gradient,
      isA<LinearGradient>().having(
        (gradient) => gradient.colors,
        'colors',
        const [Color(0xFF12304A), Color(0xFF244D70)],
      ),
    );
    expect(find.text('Kelola akun dan preferensi wisatamu.'), findsOneWidget);
    expect(find.byTooltip('Masuk'), findsNothing);
    expect(find.byTooltip('Edit profil'), findsNothing);
    final signInButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('profile-sign-in')),
    );
    expect(
      signInButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF08213E),
    );
    final registerButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('profile-register')),
    );
    expect(
      registerButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF08213E),
    );
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.ensureVisible(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('profil tamu menampilkan manfaat dan pusat informasi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    AuthService.logout();
    addTearDown(AuthService.logout);
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    final header = find.byKey(const ValueKey('profile-header'));
    final identityCard = find.byKey(const ValueKey('profile-identity-card'));
    final headerTop = tester.getTopLeft(header).dy;
    final cardTop = tester.getTopLeft(identityCard).dy;
    expect(
      tester.getBottomLeft(identityCard).dy,
      lessThanOrEqualTo(tester.getBottomLeft(header).dy),
    );
    expect(headerTop, 0);
    expect(cardTop, greaterThan(headerTop));

    expect(
      find.text('Nikmati Kemudahan Berwisata Bersama JemberGo'),
      findsOneWidget,
    );
    expect(find.text('Pemesanan Tiket Wisata Lebih Praktis'), findsOneWidget);
    expect(
      find.text('Pembayaran QRIS yang Mudah dan Transparan'),
      findsOneWidget,
    );
    expect(find.text('E-Ticket Digital yang Siap Digunakan'), findsOneWidget);
    expect(find.text('Riwayat Pemesanan Tersimpan Rapi'), findsOneWidget);
    expect(
      find.text('Pengelolaan Rombongan dan Jadwal yang Mudah'),
      findsOneWidget,
    );
    for (final icon in [
      Icons.confirmation_number_outlined,
      Icons.payments_outlined,
      Icons.qr_code_2_rounded,
      Icons.receipt_long_outlined,
      Icons.groups_outlined,
    ]) {
      expect(
        tester.widget<Icon>(find.byIcon(icon)).color,
        const Color(0xFF08213E),
      );
    }
    expect(find.text('Pusat Bantuan & CS Pariwisata'), findsNothing);
    expect(find.text('WISATA FAVORIT'), findsNothing);

    await tester.ensureVisible(find.text('Pilihan Bahasa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilihan Bahasa'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informasi pilihan bahasa akan ditambahkan di sini.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
      Colors.white,
    );
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.text('Syarat Ketentuan & Kebijakan Privasi'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Syarat Ketentuan & Kebijakan Privasi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informasi syarat dan kebijakan akan ditambahkan di sini.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tentang JemberGo'));
    await tester.pumpAndSettle();
    expect(header, findsNothing);
    expect(identityCard, findsNothing);
    await tester.tap(find.text('Tentang JemberGo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informasi tentang JemberGo akan ditambahkan di sini.'),
      findsOneWidget,
    );
  });

  testWidgets('profil mengirim edit ke API dan meminta sesi yang valid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    AuthService.logout();
    addTearDown(AuthService.logout);
    AuthService.currentUser = User.sample.copyWith(
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      phone: '081234567890',
      username: 'budisantoso',
    );
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

    expect(find.text('Selamat datang, Budi'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('budi.santoso@gmail.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-header')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('AKUN SAYA'), findsNothing);
    final detailHeader = tester.widget<Container>(
      find.byKey(const ValueKey('edit-profile-header')),
    );
    expect((detailHeader.decoration as BoxDecoration?)?.gradient, isNull);
    expect(find.text('Informasi pribadi'), findsOneWidget);
    expect(find.text('Keamanan akun'), findsOneWidget);
    expect(find.text('Ganti Foto'), findsNothing);
    expect(find.text('Hapus Foto'), findsNothing);
    expect(find.text('Nama Panggilan / Username'), findsNothing);
    expect(find.text('Terverifikasi'), findsNothing);
    expect(find.text('Terhubung'), findsNothing);
    expect(find.byTooltip('Profil'), findsNothing);
    expect(find.byType(Image), findsNothing);
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
      find.text('Simpan'),
      detailScroll,
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Simpan')).dy,
      closeTo(tester.getTopLeft(find.text('Batal')).dy, 0.5),
    );
    final cancelButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Batal'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(
      cancelButton.style?.side?.resolve(<WidgetState>{})?.color,
      const Color(0xFF12304A),
    );
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(
      find.text('Sesi login customer tidak tersedia. Silakan login kembali.'),
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

  testWidgets('profil memakai inisial akun dan menampilkan wisata favorit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final user = User(
      id: 'profile-favorites-test',
      name: 'Joko Pratama',
      email: 'joko@example.com',
      username: 'jokopratama',
      phone: '',
    );
    const destination = Destination(
      id: 'profile-favorite-destination',
      name: 'Pantai Favorit',
      location: 'Ambulu, Jember',
      latitude: -8.4,
      longitude: 113.5,
      routeDistanceKm: 0,
    );
    AuthService.currentUser = user;
    FavoriteDestinationService.toggle(destination);
    addTearDown(() {
      if (FavoriteDestinationService.contains(destination.id)) {
        FavoriteDestinationService.toggle(destination);
      }
      AuthService.logout();
    });

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pumpAndSettle();

    expect(find.text('Joko Pratama'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('WISATA FAVORIT'), findsOneWidget);
    expect(find.text('Pantai Favorit'), findsOneWidget);
    expect(find.text('Ambulu, Jember'), findsOneWidget);
    expect(find.text('Wisatawan Terverifikasi'), findsNothing);
    expect(find.text('12'), findsNothing);

    await tester.tap(find.byTooltip('Hapus dari favorit'));
    await tester.pumpAndSettle();
    expect(
      find.text('Destinasi yang kamu simpan akan muncul di sini.'),
      findsOneWidget,
    );
  });

  testWidgets('profil mengikuti perubahan status login saat tetap terbuka', (
    tester,
  ) async {
    AuthService.logout();
    addTearDown(AuthService.logout);
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(find.text('Mode Tamu'), findsOneWidget);
    AuthService.currentUser = User.sample;
    await tester.pump();
    expect(find.text('Mode Tamu'), findsNothing);
    expect(find.text('Ahmad Pratama'), findsOneWidget);
    expect(find.byTooltip('Masuk'), findsNothing);
    expect(find.byTooltip('Edit profil'), findsOneWidget);

    AuthService.logout();
    await tester.pump();
    expect(find.text('Mode Tamu'), findsOneWidget);
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
    expect(find.text('Jember, selalu punya cerita'), findsOneWidget);

    expect(find.text('Alam'), findsOneWidget);
    expect(find.text('Bahari'), findsWidgets);
    expect(find.text('Buatan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Destinasi Populer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
      MaterialApp(
        home: HomePage(
          locationProvider: () async => null,
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

  testWidgets(
    'detail shows short gallery and review previews with full pages',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final destination = Destination(
        id: 'collection-preview',
        name: 'Wisata Uji',
        location: 'Jember',
        latitude: -8.1,
        longitude: 113.7,
        routeDistanceKm: 0,
        gallery: [
          for (var index = 1; index <= 5; index++)
            DestinationGallery(
              url: 'https://example.test/photo-$index.jpg',
              caption: 'Foto $index',
            ),
        ],
        reviews: [
          for (var index = 1; index <= 4; index++)
            DestinationReviewEntry(
              name: 'Pengulas $index',
              rating: 5,
              review: 'Ulasan lengkap $index',
            ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: DestinationDetailPage(destination: destination)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Galeri Wisata Uji'));
      await tester.pumpAndSettle();
      expect(find.text('Foto 1'), findsOneWidget);
      expect(find.text('Foto 2'), findsOneWidget);
      expect(find.text('Foto 4'), findsNothing);
      await tester.ensureVisible(find.text('Ulasan pengunjung').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ulasan lengkap 1'), findsOneWidget);
      expect(find.textContaining('Ulasan lengkap 2'), findsOneWidget);
      expect(find.textContaining('Ulasan lengkap 3'), findsNothing);

      final gallerySeeAllButton = find.byKey(const ValueKey('gallery-see-all'));
      await tester.ensureVisible(gallerySeeAllButton);
      await tester.tap(gallerySeeAllButton);
      await tester.pumpAndSettle();
      expect(find.text('Galeri Wisata Uji'), findsOneWidget);
      expect(find.text('Foto 5'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      final reviewSeeAllButton = find.byKey(const ValueKey('reviews-see-all'));
      await tester.ensureVisible(reviewSeeAllButton);
      await tester.tap(reviewSeeAllButton);
      await tester.pumpAndSettle();
      expect(find.text('Ulasan pengunjung'), findsWidgets);
      expect(find.text('Ulasan lengkap 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tombol favorit destinasi populer dapat diaktifkan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    AuthService.currentUser = User(
      id: 'home-favorites-test',
      name: 'Jember Explorer',
      email: 'explorer@example.com',
      username: 'jemberexplorer',
      phone: '',
    );
    addTearDown(() {
      final destination = destinations.first;
      if (FavoriteDestinationService.contains(destination.id)) {
        FavoriteDestinationService.toggle(destination);
      }
      AuthService.logout();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          locationProvider: () async => null,
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pumpAndSettle();
    expect(find.text('WISATA FAVORIT'), findsOneWidget);
    expect(find.text('Pantai Tanjung Papuma'), findsOneWidget);
  });

  testWidgets('header eksplor ikut bergulir bersama daftar', (tester) async {
    tester.view.physicalSize = const Size(430, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: ExplorerPage(
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.style?.color, const Color(0xFF172B4D));
    expect(searchField.decoration?.hintText, 'Cari wisata yang anda inginkan');
    expect(searchField.decoration?.hintStyle?.color, const Color(0xFF8190A5));
    expect(find.text('Jelajahi Wisata'), findsOneWidget);
    expect(find.text('JEMBER, JAWA TIMUR'), findsNothing);

    final header = find.byKey(const ValueKey('exploreHeader'));
    final initialTop = tester.getTopLeft(header).dy;
    await tester.drag(
      find.byKey(const ValueKey('exploreList')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(initialTop));
  });

  testWidgets('filter pencarian membuka pop-up tengah tanpa badge jumlah', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: ExplorerPage(
          destinationService: _TestDestinationService(destinations),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ditemukan'), findsNothing);
    expect(find.byTooltip('Urutkan destinasi'), findsNothing);
    expect(find.byTooltip('Filter destinasi'), findsOneWidget);
    expect(find.text('JEMBER, JAWA TIMUR'), findsNothing);

    await tester.tap(find.byTooltip('Filter destinasi'));
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(Dialog);
    expect(dialogFinder, findsOneWidget);
    expect(tester.getCenter(dialogFinder).dy, closeTo(600, 1));
    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Alam')),
    );
    await tester.tap(find.text('Tampilkan destinasi'));
    await tester.pumpAndSettle();

    expect(dialogFinder, findsNothing);
    expect(find.text('Air Terjun Tancak'), findsOneWidget);
    expect(find.text('Pantai Tanjung Papuma'), findsNothing);

    final destinationGrid = tester.widget<GridView>(find.byType(GridView));
    final gridLayout =
        destinationGrid.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(gridLayout.crossAxisCount, 2);
    expect(gridLayout.mainAxisExtent, 238);
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
    await tester.tap(find.byTooltip('Filter destinasi'));
    await tester.pumpAndSettle();
    final selectedBahari = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Bahari'),
    );
    expect(selectedBahari.selected, isTrue);
  });

  testWidgets(
    'Home and Jelajah do not show built-in destinations while loading',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final homeDestinationService = _PendingDestinationService();
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            locationProvider: () async => null,
            destinationService: homeDestinationService,
          ),
        ),
      );

      expect(find.text('Sedang mempersiapkan wisata...'), findsWidgets);
      expect(find.text('Pantai Tanjung Papuma'), findsNothing);
      homeDestinationService.completer.complete([]);
      await tester.pump();

      final explorerDestinationService = _PendingDestinationService();
      await tester.pumpWidget(
        MaterialApp(
          home: ExplorerPage(destinationService: explorerDestinationService),
        ),
      );
      expect(find.text('Sedang mempersiapkan wisata...'), findsOneWidget);
      expect(find.text('Pantai Tanjung Papuma'), findsNothing);
      explorerDestinationService.completer.complete([]);
      await tester.pump();
    },
  );

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
      find.text('Artikel Terbaru'),
      homeScroll,
      const Offset(0, -500),
    );
    expect(find.text('Artikel resmi dari website'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('home-article-12')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.horizontal,
        ),
      ),
      findsOneWidget,
    );
    final articleTitle = find.text('Artikel resmi dari website');
    await tester.dragUntilVisible(
      articleTitle,
      homeScroll,
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(articleTitle);
    await tester.pumpAndSettle();

    expect(find.byType(ArticleDetailPage), findsOneWidget);
    expect(find.text('Detail Artikel'), findsOneWidget);
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

class _TestDestinationService extends DestinationService {
  _TestDestinationService(this.destinations);

  final List<Destination> destinations;

  @override
  Future<List<Destination>> getDestinations({LatLng? origin}) async =>
      destinations;
}

class _PendingDestinationService extends DestinationService {
  final completer = Completer<List<Destination>>();

  @override
  Future<List<Destination>> getDestinations({LatLng? origin}) =>
      completer.future;
}
