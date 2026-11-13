import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/data/models/booking.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/models/payment.dart';
import 'package:mobile_pariwisata/data/services/booking_service.dart';
import 'package:mobile_pariwisata/data/services/payment_service.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/booking_page.dart';
import 'package:mobile_pariwisata/presentation/pages/booking/payment_page.dart';

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

  testWidgets('booking progress keeps payment label on one line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(369, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: BookingPage(destination: testDestination())),
    );

    final paymentLabel = find.text('Pembayaran');
    expect(paymentLabel, findsOneWidget);
    final paymentText = tester.widget<Text>(paymentLabel);
    final textPainter = TextPainter(
      text: TextSpan(text: paymentText.data, style: paymentText.style),
      textDirection: TextDirection.ltr,
      maxLines: paymentText.maxLines,
      textScaler: paymentText.textScaler ?? TextScaler.noScaling,
    )..layout(maxWidth: tester.getSize(paymentLabel).width);
    expect(textPainter.computeLineMetrics(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('new booking opens payment without a confirmation page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: BookingPage(
          destination: testDestination(),
          bookingService: _FakeBookingService(),
          paymentService: _FakePaymentService(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Citra Wijaya');
    await tester.enterText(find.byType(TextFormField).at(1), 'citra@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(2), '081234567890');

    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(find.text('Pilih tanggal kunjungan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih tanggal kunjungan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    final ticketTypeDropdown = find.byType(DropdownButtonFormField<int>);
    await tester.dragUntilVisible(
      ticketTypeDropdown,
      find.byType(ListView),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(ticketTypeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reguler - Rp 25.000'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut Bayar'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PaymentPage), findsOneWidget);
    expect(find.text('Konfirmasi dan pembayaran'), findsNothing);
    expect(find.text('Batalkan pesanan'), findsNothing);
    expect(find.text('Ringkasan pesanan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking follows website date and participant flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: BookingPage(destination: testDestination())),
    );

    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
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

class _FakeBookingService extends BookingService {
  _FakeBookingService() : super();

  @override
  Future<BookingQuotaAvailability> getQuotaAvailability({
    required String destinationId,
    required DateTime visitDate,
  }) async => const BookingQuotaAvailability(enabled: false);

  @override
  Future<Booking> createBooking({
    required String destinationId,
    required DateTime visitDate,
    required String leaderName,
    required String leaderEmail,
    required String leaderPhone,
    required List<BookingParticipant> participants,
  }) async => Booking(
    id: '15',
    code: 'JGO-BOOKING-15',
    destinationId: destinationId,
    visitDate: visitDate,
    totalAmount: 25000,
    leaderName: leaderName,
    leaderEmail: leaderEmail,
    leaderPhone: leaderPhone,
    participants: participants,
    status: 'PENDING',
  );
}

class _FakePaymentService extends PaymentService {
  _FakePaymentService() : super();

  Payment _pendingPayment(String bookingId) => Payment(
    orderId: 'JGO-BOOKING-15',
    bookingId: bookingId,
    amount: 25000,
    status: 'PENDING',
    checkoutUrl: Uri.https('example.test', '/checkout'),
    snapToken: null,
    qrCodeUrl: null,
  );

  @override
  Future<Payment> createPayment(String bookingId) async =>
      _pendingPayment(bookingId);

  @override
  Future<Payment> getPaymentStatus(String bookingId) async =>
      _pendingPayment(bookingId);
}
