import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/data/destination_data.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
import 'package:mobile_pariwisata/data/services/destination_review_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_pdf_service.dart';
import 'package:mobile_pariwisata/data/models/user.dart';
import 'package:mobile_pariwisata/presentation/pages/destination/destination_detail_page.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/my_ticket_page.dart';

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

  test('ticket PDF contains a generated QR code', () async {
    final destination = destinations.first;
    final ticket = await TicketService().issueTicket(
      bookingId: 'BOOK-PDF',
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
    final pdfBytes = await TicketPdfService.generate(ticket);

    expect(utf8.decode(pdfBytes.take(5).toList()), '%PDF-');
    expect(pdfBytes.length, greaterThan(5000));
  });

  testWidgets('ticket page no longer exposes the QR scanner', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyTicketPage()));

    expect(find.byTooltip('Scan QR tiket'), findsNothing);
    expect(find.text('Ticket'), findsOneWidget);
  });

  testWidgets('detail unlocks rating and review after ticket use', (
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
    await tester.tap(find.text('Konfirmasi sudah berkunjung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saya sudah berkunjung'));
    await tester.pumpAndSettle();
    expect(TicketService.findById(ticket.id)?.status, 'used');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Tulis ulasan'), findsOneWidget);

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
    expect(
      find.textContaining('Tempatnya bersih dan nyaman.'),
      findsOneWidget,
    );
    expect(find.text('Tulis ulasan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
