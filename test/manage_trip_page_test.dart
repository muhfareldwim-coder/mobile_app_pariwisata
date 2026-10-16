import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pariwisata/data/models/booking.dart';
import 'package:mobile_pariwisata/data/models/destination.dart';
import 'package:mobile_pariwisata/data/models/ticket.dart';
import 'package:mobile_pariwisata/data/models/trip_management.dart';
import 'package:mobile_pariwisata/data/services/trip_management_service.dart';
import 'package:mobile_pariwisata/presentation/pages/ticket/manage_trip_page.dart';

void main() {
  testWidgets('active ticket can open trip management and add a member row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final trip = TripManagement(
      booking: Booking(
        id: '15',
        code: 'JGO-20261016-ABCDE',
        destinationId: '42',
        visitDate: DateTime(2026, 10, 23),
        totalAmount: 25000,
        leaderName: 'Citra Wijaya',
        leaderEmail: 'citra@example.com',
        leaderPhone: '081234567890',
        participants: const [
          BookingParticipant(
            name: 'Citra Wijaya',
            ticketTypeId: 8,
            ticketTypeName: 'Dewasa',
            ticketPrice: 25000,
          ),
        ],
        status: 'PAID',
      ),
      destination: const Destination(
        id: '42',
        name: 'Pantai Papuma',
        location: 'Jember',
        latitude: -8.4,
        longitude: 113.5,
        routeDistanceKm: 0,
        ticketTypes: [
          DestinationTicketType(id: 8, name: 'Dewasa', price: 25000),
        ],
      ),
      ticketTypes: const [
        DestinationTicketType(id: 8, name: 'Dewasa', price: 25000),
      ],
      remainingSlots: 9,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ManageTripPage(
          ticket: Ticket(
            id: 'ticket-1',
            bookingId: 'JGO-20261016-ABCDE',
            bookingRecordId: '15',
            destinationName: 'Pantai Papuma',
            visitDate: DateTime(2026, 10, 23),
            adultCount: 1,
            childCount: 0,
            leaderName: 'Citra Wijaya',
            leaderEmail: 'citra@example.com',
            leaderPhone: '081234567890',
            memberNames: [],
          ),
          tripService: _FakeTripManagementService(trip),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kelola perjalanan'), findsOneWidget);
    expect(find.text('Pantai Papuma'), findsOneWidget);
    expect(find.text('Jumat, 23 Oktober 2026'), findsOneWidget);
    expect(find.text('Pilih tanggal atau tambah anggota'), findsOneWidget);
    expect(find.text('Ubah jadwal'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('Tambah tiket'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Tambah tiket'), findsOneWidget);
    expect(
      find.text('Tambahkan anggota atau tiket tambahan untuk perjalanan Anda.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Tambah anggota'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Pilih jenis tiket'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ringkasan pesanan'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Total biaya tambahan'), findsOneWidget);
    expect(find.text('Jumlah tiket'), findsOneWidget);
    expect(find.text('Subtotal tambahan'), findsOneWidget);
    expect(find.text('Tambah anggota'), findsOneWidget);
    expect(
      find.text('9 slot tiket tersedia · maksimal 10 orang per pemesanan.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Tambah anggota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah anggota'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'Dewi Anggraini');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dewasa · Rp 25.000').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.scrollUntilVisible(
      find.text('Lihat perubahan'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lihat perubahan'), findsOneWidget);
    await tester.tap(find.text('Lihat perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Tinjau perubahan'), findsOneWidget);
    expect(find.textContaining('Dewi Anggraini'), findsNWidgets(2));
    await tester.tap(find.text('Periksa lagi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _FakeTripManagementService extends TripManagementService {
  _FakeTripManagementService(this.trip);

  final TripManagement trip;

  @override
  Future<TripManagement> getTrip(String bookingId) async => trip;
}
