import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/forgot_password_page.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/login_page.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/otp_verification_page.dart';
import 'package:mobile_pariwisata/presentation/pages/auth/register_page.dart';
import 'package:mobile_pariwisata/presentation/widgets/brand_logo.dart';

void main() {
  testWidgets('mobile login and register layouts fit without overflow', (
    tester,
  ) async {
    final cases = [
      (const Size(360, 800), const LoginPage()),
      (const Size(320, 640), const RegisterPage()),
      (
        const Size(320, 640),
        const OtpVerificationPage(
          email: 'siti@example.com',
          purpose: OtpPurpose.registration,
        ),
      ),
      (const Size(320, 640), const ForgotPasswordPage()),
    ];

    for (final (size, page) in cases) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pump();

      expect(find.byType(TextFormField), findsWidgets);
      expect(
        find.text('SISTEM INFORMASI DAN LAYANAN PARIWISATA KABUPATEN JEMBER'),
        findsNothing,
      );
      if (page is LoginPage || page is RegisterPage) {
        final logoSize = tester.getSize(find.byType(BrandLogo));
        expect(logoSize, const Size(112, 112));
        final logoImage = tester.widget<Image>(
          find.descendant(
            of: find.byType(BrandLogo),
            matching: find.byType(Image),
          ),
        );
        expect(logoImage.image, isA<AssetImage>());
        expect(
          (logoImage.image as AssetImage).assetName,
          equals('assets/logo_mobile_latest.png'),
        );
        expect(logoImage.fit, BoxFit.contain);
      }
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
  });
}
