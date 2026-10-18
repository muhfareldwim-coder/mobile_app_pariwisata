import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/destination_data.dart';
import 'package:mobile_pariwisata/data/models/ticket.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
import 'package:mobile_pariwisata/data/services/destination_review_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_pdf_service.dart';
import 'package:mobile_pariwisata/data/models/user.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/destination_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/my_ticket_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/qr_ticket_page.dart';

void main() {
  setUp(() {
    AuthService.currentUser = User.sample;
    TicketService.tickets.clear();
    TicketService.revision.value++;
    DestinationReviewService.reviews.clear();
    DestinationReviewService.revision.value++;
  });

  tearDown(() {
    AuthService.logout();
    TicketService.tickets.clear();
    TicketService.revision.value++;
    DestinationReviewService.reviews.clear();
    DestinationReviewService.revision.value++;
  });

  test('only an owned used ticket can submit a destination review', () async {
    final destination = destinations.first;
    final ticket = await TicketService().issueTicket(
      bookingId: 'BOOK-1',
      destinationId: destination.id,
      destinationName: destination.name,
      visitDate: DateTime.now().subtract(const Duration(days: 1)),
      adultCount: 1,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
    );

    expect(
      DestinationReviewService.canReview(
        destinationId: destination.id,
        userEmail: User.sample.email,
      ),
      isFalse,
    );
    expect(
      () => DestinationReviewService.submit(
        destinationId: destination.id,
        ticketId: ticket.id,
        userEmail: User.sample.email,
        userName: User.sample.name,
        rating: 5,
        review: 'Pengalaman menyenangkan.',
      ),
      throwsStateError,
    );

    expect(TicketService.markAsUsed(ticket.id, User.sample.email), isTrue);
    expect(
      DestinationReviewService.canReview(
        destinationId: destination.id,
        userEmail: User.sample.email,
      ),
      isTrue,
    );
    DestinationReviewService.submit(
      destinationId: destination.id,
      ticketId: ticket.id,
      userEmail: User.sample.email,
      userName: User.sample.name,
      rating: 5,
      review: 'Pengalaman menyenangkan.',
    );
    expect(
      DestinationReviewService.canReview(
        destinationId: destination.id,
        userEmail: User.sample.email,
      ),
      isFalse,
    );
  });

  test('cannot mark another user or a future ticket as used', () async {
    final destination = destinations.first;
    final ticket = await TicketService().issueTicket(
      bookingId: 'BOOK-2',
      destinationId: destination.id,
      destinationName: destination.name,
      visitDate: DateTime.now().add(const Duration(days: 2)),
      adultCount: 1,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
    );

    expect(
      TicketService.markAsUsed(ticket.id, 'someone-else@example.com'),
      isFalse,
    );
    expect(TicketService.markAsUsed(ticket.id, User.sample.email), isFalse);
    expect(TicketService.findById(ticket.id)?.status, 'valid');
  });

  test('ticket PDF is downloaded from the website booking endpoint', () async {
    final destination = destinations.first;
    final ticket = Ticket(
      id: 'ticket-1',
      bookingId: 'JGO-20261016-ABCDE',
      bookingRecordId: '15',
      destinationName: destination.name,
      visitDate: DateTime.now(),
      adultCount: 1,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
    );
    const pdf = '%PDF-1.7 website-generated-ticket';
    final service = ApiService(
      baseUrl: 'http://localhost/api/v1',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/customer/pesanan/15/e-ticket/pdf');
        expect(request.headers['Authorization'], isNotEmpty);
        expect(request.headers['Accept'], 'application/json, application/pdf');
        return http.Response.bytes(
          utf8.encode(pdf),
          200,
          headers: {'content-type': 'application/pdf'},
        );
      }),
    );

    final pdfBytes = await TicketPdfService.download(
      ticket,
      api: service,
      token: 'test-token',
    );

    expect(utf8.decode(pdfBytes), pdf);
  });

  testWidgets('ticket page hides scanner and ticket help section', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MyTicketPage()));

    expect(find.byTooltip('Scan QR tiket'), findsNothing);
    expect(find.text('Tiket Saya'), findsOneWidget);
    expect(find.text('Bantuan & Kebijakan Tiket'), findsNothing);
  });

  testWidgets('e-ticket detail uses a compact QR card and visit status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final destination = destinations.first;
    final ticket = Ticket(
      id: 'detail-ticket',
      bookingId: 'BOOK-DETAIL',
      destinationName: destination.name,
      visitDate: DateTime.now().add(const Duration(days: 3)),
      adultCount: 2,
      childCount: 1,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
      amountPaid: 50000,
    );

    await tester.pumpWidget(MaterialApp(home: QrTicketPage(ticket: ticket)));
    await tester.pumpAndSettle();

    expect(find.text('Detail E-Tiket'), findsOneWidget);
    expect(find.text('Terkonfirmasi'), findsWidgets);
    expect(find.text('Kelola perjalanan'), findsNothing);
    expect(find.text('Konfirmasi sudah berkunjung'), findsNothing);
    expect(
      find.text(
        'Tunjukkan kode booking kepada petugas saat tiba di destinasi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kode QR booking'), findsOneWidget);
    expect(
      find.text('Satu kode QR untuk seluruh peserta dalam booking ini.'),
      findsOneWidget,
    );
    expect(find.text('Total peserta'), findsOneWidget);
    expect(find.text('Total dibayar'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget);
    expect(find.text('QR Penuh'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active and completed tickets use the same compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final destination = destinations.first;
    final activeTicket = Ticket(
      id: 'active',
      bookingId: 'BOOK-ACTIVE',
      bookingRecordId: '1',
      destinationId: destination.id,
      destinationName: destination.name,
      visitDate: DateTime.now().add(const Duration(days: 2)),
      adultCount: 1,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
    );
    TicketService.tickets.add(activeTicket);
    TicketService.revision.value++;
    final usedTicket = await TicketService().issueTicket(
      bookingId: 'BOOK-USED',
      destinationId: destination.id,
      destinationName: destination.name,
      visitDate: DateTime.now().subtract(const Duration(days: 2)),
      adultCount: 1,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
    );
    TicketService.markAsUsed(usedTicket.id, User.sample.email);

    await tester.pumpWidget(
      const MaterialApp(home: MyTicketPage(isSelected: false)),
    );

    expect(find.text('E-ticket'), findsOneWidget);
    expect(find.text('Kelola perjalanan'), findsOneWidget);
    expect(find.text('Tanggal Kunjungan'), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
    expect(find.text('QR Penuh'), findsNothing);

    await tester.tap(find.text('Riwayat tiket'));
    await tester.pumpAndSettle();

    expect(find.text('E-ticket'), findsOneWidget);
    expect(find.text('Kelola perjalanan'), findsNothing);
    expect(find.text('Tanggal Kunjungan'), findsOneWidget);
    expect(find.text('Sudah digunakan'), findsOneWidget);
    expect(find.text('QR Penuh'), findsNothing);
    expect(TicketService.findById(activeTicket.id)?.status, 'valid');
    await tester.tap(find.text('Semua pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('E-ticket'), findsNWidgets(2));
    expect(find.text('Kelola perjalanan'), findsNothing);
  });

  testWidgets('mixed bookings appear in both tabs like the website', (
    tester,
  ) async {
    final mixedBooking = Ticket(
      id: 'mixed-booking',
      bookingId: 'BOOK-MIXED',
      destinationName: 'Pantai Papuma',
      visitDate: DateTime.now().add(const Duration(days: 2)),
      adultCount: 2,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: const [],
      status: 'partial',
      hasActiveTicket: true,
      hasUsedTicket: true,
    );
    TicketService.tickets.add(mixedBooking);
    TicketService.revision.value++;
    addTearDown(() {
      TicketService.tickets.clear();
      TicketService.revision.value++;
    });

    await tester.pumpWidget(
      const MaterialApp(home: MyTicketPage(isSelected: false)),
    );

    expect(find.text('E-ticket'), findsOneWidget);
    expect(find.text('Sudah digunakan'), findsOneWidget);

    await tester.tap(find.text('Riwayat tiket'));
    await tester.pumpAndSettle();
    expect(find.text('E-ticket'), findsOneWidget);
    expect(find.text('Sudah digunakan'), findsOneWidget);

    await tester.tap(find.text('Semua pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Sudah digunakan'), findsOneWidget);
  });

  testWidgets('all orders includes pending bookings with a pay action', (
    tester,
  ) async {
    final pendingBooking = Ticket(
      id: 'booking-16',
      bookingId: 'JGO-PENDING',
      bookingRecordId: '16',
      destinationId: destinations.first.id,
      destinationName: destinations.first.name,
      visitDate: DateTime.now().add(const Duration(days: 2)),
      adultCount: 2,
      childCount: 0,
      leaderName: 'Citra Wijaya',
      leaderEmail: 'citra@example.com',
      leaderPhone: '081234567890',
      memberNames: ['Siti Wijaya'],
      amountPaid: 50000,
      status: 'pending',
      bookingStatus: 'PENDING',
      paymentStatus: 'PENDING',
      hasIssuedTicket: false,
    );
    TicketService.tickets.add(pendingBooking);
    TicketService.revision.value++;
    addTearDown(() {
      TicketService.tickets.clear();
      TicketService.revision.value++;
    });

    await tester.pumpWidget(
      const MaterialApp(home: MyTicketPage(isSelected: false)),
    );

    await tester.tap(find.text('Semua pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('JGO-PENDING'), findsOneWidget);
    expect(find.text('Menunggu pembayaran'), findsWidgets);
    expect(find.text('Bayar'), findsOneWidget);
    expect(find.text('E-ticket'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired booking without an issued ticket is labeled failed', (
    tester,
  ) async {
    final expiredBooking = Ticket(
      id: 'booking-expired',
      bookingId: 'JGO-EXPIRED',
      bookingRecordId: '18',
      destinationId: destinations.first.id,
      destinationName: destinations.first.name,
      visitDate: DateTime(2026, 10, 17),
      adultCount: 1,
      childCount: 0,
      leaderName: 'Citra Wijaya',
      leaderEmail: 'citra@example.com',
      leaderPhone: '081234567890',
      memberNames: const [],
      status: 'expired',
      bookingStatus: 'EXPIRED',
      paymentStatus: 'EXPIRED',
      hasIssuedTicket: false,
    );
    TicketService.tickets.add(expiredBooking);
    TicketService.revision.value++;
    addTearDown(() {
      TicketService.tickets.clear();
      TicketService.revision.value++;
    });

    await tester.pumpWidget(
      const MaterialApp(home: MyTicketPage(isSelected: false)),
    );

    await tester.tap(find.text('Semua pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('JGO-EXPIRED'), findsOneWidget);
    expect(find.text('Gagal'), findsOneWidget);
    expect(find.text('Kadaluarsa'), findsNothing);
    expect(find.text('E-ticket'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticket total matches the booking total from the website API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final ticket = Ticket(
      id: 'price-ticket',
      bookingId: 'BOOK-PRICE',
      destinationName: 'Taman Botani',
      visitDate: DateTime(2026, 10, 21),
      adultCount: 5,
      childCount: 0,
      leaderName: 'Citra Wijaya',
      leaderEmail: 'citra@gmail.com',
      leaderPhone: '081234567890',
      memberNames: ['Citra Wijaya'],
      amountPaid: 125000,
    );
    TicketService.tickets.add(ticket);
    TicketService.revision.value++;

    await tester.pumpWidget(
      const MaterialApp(home: MyTicketPage(isSelected: false)),
    );

    expect(find.text('Total pesanan'), findsOneWidget);
    expect(find.text('Rp 125.000'), findsOneWidget);
    expect(find.text('Rp 25.000'), findsNothing);
  });

  testWidgets('server-recorded ticket usage unlocks rating and review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final destination = destinations.first;

    final ticket = await TicketService().issueTicket(
      bookingId: 'BOOK-3',
      destinationId: destination.id,
      destinationName: destination.name,
      visitDate: DateTime.now().subtract(const Duration(days: 1)),
      adultCount: 1,
      childCount: 0,
      leaderName: User.sample.name,
      leaderEmail: User.sample.email,
      leaderPhone: User.sample.phone,
      memberNames: [User.sample.name],
    );
    await tester.pumpWidget(
      MaterialApp(home: DestinationDetailPage(destination: destination)),
    );
    await tester.ensureVisible(find.text('Buka e-tiket'));
    await tester.pumpAndSettle();
    expect(find.text('Buka e-tiket'), findsOneWidget);

    await tester.tap(find.text('Buka e-tiket'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi sudah berkunjung'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final ticketIndex = TicketService.tickets.indexWhere(
      (item) => item.id == ticket.id,
    );
    TicketService.tickets[ticketIndex] = ticket.copyWith(status: 'used');
    TicketService.revision.value++;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(TicketService.findById(ticket.id)?.status, 'used');
    expect(find.text('Tulis ulasan'), findsOneWidget);

    await tester.ensureVisible(find.text('Tulis ulasan'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tulis ulasan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('4 bintang'));
    await tester.enterText(
      find.byType(TextField).last,
      'Tempatnya bersih dan nyaman.',
    );
    await tester.tap(find.text('Kirim ulasan'));
    await tester.pumpAndSettle();

    expect(DestinationReviewService.reviews, hasLength(1));
    expect(find.textContaining('Tempatnya bersih dan nyaman.'), findsOneWidget);
    expect(find.text('Tulis ulasan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
