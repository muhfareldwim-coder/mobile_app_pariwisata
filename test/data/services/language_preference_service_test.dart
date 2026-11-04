import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/app.dart';
import 'package:mobile_pariwisata/core/localization/app_translations.dart';
import 'package:mobile_pariwisata/data/services/language_preference_service.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/my_ticket_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and restores the selected language', () async {
    SharedPreferences.setMockInitialValues({});
    LanguagePreferenceService.locale.value = const Locale('id', 'ID');

    await LanguagePreferenceService.setLocale(const Locale('en', 'US'));
    expect(LanguagePreferenceService.locale.value, const Locale('en', 'US'));
    expect(AppTranslations.translate('Selamat datang, Ana'), 'Welcome, Ana');
    expect(
      AppTranslations.translate('Pantai Jember yang indah'),
      'Pantai Jember yang indah',
    );
    expect(AppTranslations.translate('Tiket aktif'), 'Active Tickets');
    expect(
      AppTranslations.translate('Login terlebih dahulu'),
      'Please Sign In First',
    );
    expect(
      AppTranslations.translate('login untuk memulai perjalananmu.'),
      'Sign in to start your journey.',
    );
    expect(
      AppTranslations.translate(
        'Tidak dapat terhubung ke server. Periksa alamat API dan koneksi jaringan.',
      ),
      'Could not connect to the server. Check the API address and your network connection.',
    );
    expect(
      AppTranslations.translate('Syarat & Ketentuan'),
      'Terms and Conditions',
    );
    expect(
      AppTranslations.translate(
        'Destinasi terbaru gagal dimuat: '
        'Tidak dapat terhubung ke server. Periksa alamat API dan koneksi jaringan.',
      ),
      'Could not load the latest destinations: '
      'Could not connect to the server. Check the API address and your network connection.',
    );
    expect(AppTranslations.translate('3 jam 15 menit'), '3 hours 15 minutes');
    expect(
      AppTranslations.translate('Pemesanan Tiket Wisata Lebih Praktis'),
      'Easier Tourist Ticket Booking',
    );

    LanguagePreferenceService.locale.value = const Locale('id', 'ID');
    await LanguagePreferenceService.restore();

    expect(LanguagePreferenceService.locale.value, const Locale('en', 'US'));
  });

  testWidgets('applies the selected locale to the application', (tester) async {
    SharedPreferences.setMockInitialValues({'jembergo_language': 'en'});
    await LanguagePreferenceService.restore();
    await tester.pumpWidget(PariwisataApp(locationProvider: () async => null));

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en', 'US'),
    );
    expect(find.text('THE CHARM OF JEMBER REGENCY'), findsOneWidget);
    expect(find.text('Explore Destinations'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await LanguagePreferenceService.setLocale(const Locale('id', 'ID'));
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('id', 'ID'),
    );
    expect(find.text('PESONA KABUPATEN JEMBER'), findsOneWidget);
    expect(find.text('Jelajahi Destinasi'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('translates all visible ticket empty-state labels', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    LanguagePreferenceService.locale.value = const Locale('id', 'ID');
    await tester.pumpWidget(
      const MaterialApp(home: MyTicketPage(isSelected: false)),
    );

    expect(find.text('Tiket aktif'), findsOneWidget);
    expect(find.text('Login terlebih dahulu'), findsOneWidget);

    await LanguagePreferenceService.setLocale(const Locale('en', 'US'));
    await tester.pumpAndSettle();

    expect(find.text('Active Tickets'), findsOneWidget);
    expect(find.text('Ticket History'), findsOneWidget);
    expect(find.text('All Bookings'), findsOneWidget);
    expect(find.text('Please Sign In First'), findsOneWidget);
    expect(find.text('Sign in to start your journey.'), findsOneWidget);
    expect(find.text('Sign In Now'), findsOneWidget);
  });
}
