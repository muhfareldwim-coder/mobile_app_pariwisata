import '../models/booking.dart';
import '../models/destination.dart';
import '../models/trip_management.dart';
import 'api_service.dart';
import 'auth_service.dart';

class TripManagementService {
  TripManagementService({ApiService? api, String? Function()? tokenProvider})
    : _api = api ?? ApiService(),
      _tokenProvider = tokenProvider ?? (() => AuthService.accessToken);

  final ApiService _api;
  final String? Function() _tokenProvider;

  Future<TripManagement> getTrip(String bookingId) async {
    final response = await _api.get(
      '/customer/pesanan/$bookingId/kelola',
      token: _tokenProvider(),
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Data kelola perjalanan dari server tidak valid.',
      );
    }

    return _tripFromJson(data);
  }

  Future<PendingTripChange> createChange({
    required String bookingId,
    required DateTime visitDate,
    required List<TripMemberDraft> members,
  }) async {
    final response = await _api.post(
      '/customer/pesanan/$bookingId/kelola',
      token: _tokenProvider(),
      body: {
        'tanggal_kunjungan': _formatDate(visitDate),
        'anggota': [
          for (final member in members)
            {'nama': member.name, 'id_jenis_tiket': member.ticketTypeId},
        ],
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic> ||
        data['id'] == null ||
        data['status'] is! String ||
        data['amount'] is! num) {
      throw const FormatException('Respons perubahan perjalanan tidak valid.');
    }

    return PendingTripChange(
      id: data['id'].toString(),
      amount: (data['amount'] as num).round(),
      status: data['status'] as String,
    );
  }

  TripManagement _tripFromJson(Map<String, dynamic> json) {
    final bookingData = json['booking'];
    final typesData = json['ticket_types'];
    if (bookingData is! Map<String, dynamic> ||
        typesData is! List<dynamic> ||
        bookingData['id'] == null ||
        bookingData['code'] is! String ||
        bookingData['visit_date'] is! String ||
        bookingData['total_amount'] is! num) {
      throw const FormatException('Data perjalanan dari server tidak lengkap.');
    }

    final ticketTypes = typesData
        .whereType<Map<String, dynamic>>()
        .where(
          (type) =>
              type['id'] is num &&
              type['name'] is String &&
              type['price'] is num,
        )
        .map(
          (type) => DestinationTicketType(
            id: (type['id'] as num).toInt(),
            name: type['name'] as String,
            price: (type['price'] as num).round(),
          ),
        )
        .toList();
    final destinationData = bookingData['destination'];
    final leaderData = bookingData['leader'];
    final participantData = bookingData['participants'];
    if (destinationData is! Map<String, dynamic> ||
        destinationData['id'] == null ||
        destinationData['name'] is! String ||
        leaderData is! Map<String, dynamic> ||
        participantData is! List<dynamic>) {
      throw const FormatException(
        'Informasi peserta perjalanan tidak lengkap.',
      );
    }

    final participants = participantData.whereType<Map<String, dynamic>>().map((
      participant,
    ) {
      final typeId = participant['ticket_type_id'];
      final typeName = participant['ticket_type_name'];
      final price = participant['ticket_price'];
      if (participant['name'] is! String) {
        throw const FormatException(
          'Data peserta perjalanan dari server tidak valid.',
        );
      }
      return BookingParticipant(
        name: participant['name'] as String,
        ticketTypeId: typeId is num ? typeId.toInt() : 0,
        ticketTypeName: typeName is String ? typeName : 'Tiket',
        ticketPrice: price is num ? price.round() : 0,
      );
    }).toList();
    final latitude = destinationData['latitude'];
    final longitude = destinationData['longitude'];
    final pendingData = json['pending_change'];
    final pendingChange =
        pendingData is Map<String, dynamic> &&
            pendingData['id'] != null &&
            pendingData['amount'] is num &&
            pendingData['status'] is String
        ? PendingTripChange(
            id: pendingData['id'].toString(),
            amount: (pendingData['amount'] as num).round(),
            status: pendingData['status'] as String,
          )
        : null;

    return TripManagement(
      booking: Booking(
        id: bookingData['id'].toString(),
        code: bookingData['code'] as String,
        destinationId: destinationData['id'].toString(),
        visitDate: DateTime.parse(bookingData['visit_date'] as String),
        totalAmount: (bookingData['total_amount'] as num).round(),
        leaderName: leaderData['name'] is String
            ? leaderData['name'] as String
            : '',
        leaderEmail: leaderData['email'] is String
            ? leaderData['email'] as String
            : '',
        leaderPhone: leaderData['phone'] is String
            ? leaderData['phone'] as String
            : '',
        participants: List.unmodifiable(participants),
        status: bookingData['status'] is String
            ? bookingData['status'] as String
            : 'PAID',
      ),
      destination: Destination(
        id: destinationData['id'].toString(),
        name: destinationData['name'] as String,
        location: destinationData['location'] is String
            ? destinationData['location'] as String
            : '',
        latitude: latitude is num ? latitude.toDouble() : 0,
        longitude: longitude is num ? longitude.toDouble() : 0,
        routeDistanceKm: 0,
        ticketPrice: ticketTypes.isEmpty
            ? 0
            : ticketTypes
                  .map((type) => type.price)
                  .reduce((first, second) => first < second ? first : second),
        ticketTypes: List.unmodifiable(ticketTypes),
      ),
      ticketTypes: List.unmodifiable(ticketTypes),
      remainingSlots: json['remaining_slots'] is num
          ? (json['remaining_slots'] as num).toInt()
          : 0,
      pendingChange: pendingChange,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
