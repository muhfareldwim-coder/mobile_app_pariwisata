import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_pariwisata/data/models/article.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/models/ticket.dart';
import 'package:mobile_pariwisata/data/models/ticket_reminder.dart';
import 'package:mobile_pariwisata/data/models/user.dart';
import 'package:mobile_pariwisata/data/services/article_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';
import 'package:mobile_pariwisata/data/services/destination_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_reminder_read_service.dart';
import 'package:mobile_pariwisata/data/services/ticket_service.dart';
import 'package:mobile_pariwisata/presentation/pages/home/home_page.dart';
import 'package:mobile_pariwisata/presentation/pages/profile/profile_page.dart';
import 'package:mobile_pariwisata/presentation/pages/profile/ticket_notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TicketReminder.fromTickets', () {
    test('creates reminders only for active issued tickets today and H-1', () {
      final now = DateTime(2026, 11, 25, 16);
      final reminders = TicketReminder.fromTickets([
        _ticket('today', DateTime(2026, 11, 25, 8)),
        _ticket('tomorrow', DateTime(2026, 11, 26, 22)),
        _ticket('later', DateTime(2026, 11, 27)),
        _ticket('past', DateTime(2026, 11, 24)),
        _ticket('expired', DateTime(2026, 11, 25), status: 'expired'),
        _ticket('expired-later', DateTime(2026, 11, 27), status: 'expired'),
        _ticket('not-issued', DateTime(2026, 11, 25), hasIssuedTicket: false),
      ], now: now);

      expect(reminders, hasLength(3));
      expect(reminders[0].ticket.bookingId, 'today');
      expect(reminders[0].timing, TicketReminderTiming.visitToday);
      expect(reminders[1].ticket.bookingId, 'tomorrow');
      expect(reminders[1].timing, TicketReminderTiming.visitTomorrow);
      expect(reminders[2].ticket.bookingId, 'expired');
      expect(reminders[2].timing, TicketReminderTiming.expiredToday);
    });
  });

  testWidgets('home notification bell opens ticket notifications', (
    tester,
  ) async {
    AuthService.logout();
    TicketService.tickets.clear();
    addTearDown(() {
      AuthService.logout();
      TicketService.tickets.clear();
      TicketService.revision.value++;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          articleService: _EmptyArticleService(),
          destinationService: _EmptyDestinationService(),
          locationProvider: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.byType(TicketNotificationsPage), findsOneWidget);
    expect(find.text('Masuk untuk melihat pengingat tiket'), findsOneWidget);
    expect(find.byTooltip('Muat ulang'), findsNothing);
    final promptColumn = find
        .ancestor(
          of: find.byIcon(Icons.lock_outline_rounded),
          matching: find.byType(Column),
        )
        .first;
    expect(
      tester.getCenter(promptColumn).dy,
      closeTo(
        tester.getRect(find.byType(SingleChildScrollView)).center.dy,
        0.5,
      ),
    );
  });

  testWidgets('home shows its badge only while a ticket reminder exists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const customer = User(
      id: 'badge-test-customer',
      name: 'Test Customer',
      email: 'badge@example.com',
      username: 'badge',
      phone: '08123456789',
    );
    AuthService.currentUser = customer;
    await TicketReminderReadService.loadForCustomer(customer.id);
    TicketService.tickets
      ..clear()
      ..add(_ticket('today', DateTime.now()));
    addTearDown(() {
      AuthService.logout();
      TicketReminderReadService.clearCurrentCustomer();
      TicketService.tickets.clear();
      TicketService.revision.value++;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          articleService: _EmptyArticleService(),
          destinationService: _EmptyDestinationService(),
          ticketService: _NoopTicketService(),
          locationProvider: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notification-badge')), findsOneWidget);

    await TicketReminderReadService.markAllRead(
      customer.id,
      TicketReminder.fromTickets(TicketService.tickets),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-badge')), findsNothing);

    TicketService.tickets
      ..clear()
      ..add(_ticket('tomorrow', DateTime.now().add(const Duration(days: 1))));
    TicketService.revision.value++;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-badge')), findsOneWidget);

    TicketService.tickets.clear();
    TicketService.revision.value++;
    await tester.pumpAndSettle();
  });

  testWidgets('notifications can be marked as read', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const customer = User(
      id: 'read-test-customer',
      name: 'Test Customer',
      email: 'read@example.com',
      username: 'read',
      phone: '08123456789',
    );
    AuthService.currentUser = customer;
    TicketService.tickets
      ..clear()
      ..add(_ticket('read', DateTime.now()));
    await TicketReminderReadService.loadForCustomer(customer.id);
    addTearDown(() {
      AuthService.logout();
      TicketReminderReadService.clearCurrentCustomer();
      TicketService.tickets.clear();
      TicketService.revision.value++;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TicketNotificationsPage(ticketService: _NoopTicketService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tandai dibaca'), findsOneWidget);
    await tester.tap(find.text('Tandai dibaca'));
    await tester.pumpAndSettle();

    expect(find.text('Tandai dibaca'), findsNothing);
    expect(
      TicketReminderReadService.hasUnread(
        customer.id,
        TicketReminder.fromTickets(TicketService.tickets),
      ),
      isFalse,
    );
  });

  test('read status is persisted per customer and reminder stage', () async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(TicketReminderReadService.clearCurrentCustomer);
    await TicketReminderReadService.loadForCustomer('persisted-read-customer');
    final todayReminders = TicketReminder.fromTickets([
      _ticket('booking-read', DateTime(2026, 11, 25)),
    ], now: DateTime(2026, 11, 25, 12));

    expect(
      TicketReminderReadService.hasUnread(
        'persisted-read-customer',
        todayReminders,
      ),
      isTrue,
    );
    await TicketReminderReadService.markAllRead(
      'persisted-read-customer',
      todayReminders,
    );
    expect(
      TicketReminderReadService.hasUnread(
        'persisted-read-customer',
        todayReminders,
      ),
      isFalse,
    );

    TicketReminderReadService.clearCurrentCustomer();
    await TicketReminderReadService.loadForCustomer('persisted-read-customer');
    expect(
      TicketReminderReadService.hasUnread(
        'persisted-read-customer',
        todayReminders,
      ),
      isFalse,
    );

    final tomorrowReminders = TicketReminder.fromTickets([
      _ticket('booking-read', DateTime(2026, 11, 26)),
    ], now: DateTime(2026, 11, 25, 12));
    expect(
      TicketReminderReadService.hasUnread(
        'persisted-read-customer',
        tomorrowReminders,
      ),
      isTrue,
    );
  });

  testWidgets('profile contains an entry to ticket notifications', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.ensureVisible(find.text('Notifikasi Tiket'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifikasi Tiket'));
    await tester.pumpAndSettle();

    expect(find.byType(TicketNotificationsPage), findsOneWidget);
  });
}

Ticket _ticket(
  String bookingId,
  DateTime visitDate, {
  String status = 'valid',
  bool hasIssuedTicket = true,
}) => Ticket(
  id: bookingId,
  bookingId: bookingId,
  destinationName: 'Pantai Papuma',
  visitDate: visitDate,
  adultCount: 1,
  childCount: 0,
  leaderName: 'Pengunjung',
  leaderEmail: 'pengunjung@example.com',
  leaderPhone: '08123456789',
  memberNames: const [],
  status: status,
  hasIssuedTicket: hasIssuedTicket,
);

class _EmptyArticleService extends ArticleService {
  @override
  Future<List<Article>> getArticles() async => const [];
}

class _EmptyDestinationService extends DestinationService {
  @override
  Future<List<Destination>> getDestinations({LatLng? origin}) async => const [];
}

class _NoopTicketService extends TicketService {
  @override
  Future<void> refreshFromServer({String? expectedCustomerId}) async {}
}
