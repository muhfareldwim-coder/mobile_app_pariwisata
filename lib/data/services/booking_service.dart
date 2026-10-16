import '../models/booking.dart';
import 'api_service.dart';
import 'auth_service.dart';

class BookingService {
  BookingService({ApiService? api, String? Function()? tokenProvider})
    : _api = api ?? ApiService(),
      _tokenProvider = tokenProvider ?? (() => AuthService.accessToken);

  final ApiService _api;
  final String? Function() _tokenProvider;

  Future<BookingQuotaAvailability> getQuotaAvailability({
    required String destinationId,
    required DateTime visitDate,
  }) async {
    final destinationNumericId = int.tryParse(destinationId);
    if (destinationNumericId == null) {
      throw const FormatException(
        'Destinasi ini belum tersedia untuk pemesanan.',
      );
    }

    final response = await _api.get(
      '/customer/destinasi/$destinationNumericId/kuota',
      token: _tokenProvider(),
      queryParameters: {'date': _formatDate(visitDate)},
    );
    if (response['enabled'] is! bool) {
      throw const FormatException('Respons kuota tiket dari server tidak valid.');
    }
    final remaining = response['remaining'];
    if (response['enabled'] == true && remaining is! num) {
      throw const FormatException('Sisa kuota tiket dari server tidak valid.');
    }

    return BookingQuotaAvailability(
      enabled: response['enabled'] as bool,
      remaining: remaining is num ? remaining.toInt() : null,
    );
  }

  Future<Booking> createBooking({
    required String destinationId,
    required DateTime visitDate,
    required String leaderName,
    required String leaderEmail,
    required String leaderPhone,
    required List<BookingParticipant> participants,
  }) async {
    final destinationNumericId = int.tryParse(destinationId);
    if (destinationNumericId == null) {
      throw const FormatException(
        'Destinasi ini belum tersedia untuk pemesanan.',
      );
    }
    if (participants.isEmpty) {
      throw const FormatException('Tambahkan minimal satu peserta.');
    }

    final response = await _api.post(
      '/customer/destinasi/$destinationNumericId/pemesanan',
      token: _tokenProvider(),
      body: {
        'tanggal_kunjungan': _formatDate(visitDate),
        'ketua_nama': leaderName,
        'ketua_email': leaderEmail,
        'ketua_no_hp': leaderPhone,
        'peserta': [
          for (final participant in participants)
            {
              'nama': participant.name,
              'id_jenis_tiket': participant.ticketTypeId,
            },
        ],
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic> ||
        data['id'] == null ||
        data['kode_booking'] is! String ||
        data['total_harga'] is! num) {
      throw const FormatException(
        'Respons pemesanan dari server tidak valid.',
      );
    }

    final paymentDeadline = data['batas_waktu_pembayaran'];
    final visitDateValue = data['tanggal_kunjungan'];
    return Booking(
      id: data['id'].toString(),
      code: data['kode_booking'] as String,
      destinationId: destinationNumericId.toString(),
      visitDate: DateTime.parse(
        visitDateValue is String
            ? visitDateValue
            : visitDate.toIso8601String().substring(0, 10),
      ),
      totalAmount: (data['total_harga'] as num).round(),
      leaderName: leaderName,
      leaderEmail: leaderEmail,
      leaderPhone: leaderPhone,
      participants: List.unmodifiable(participants),
      status: data['status'] is String ? data['status'] as String : 'PENDING',
      paymentDeadline: paymentDeadline is String
          ? DateTime.tryParse(paymentDeadline)
          : null,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class BookingQuotaAvailability {
  const BookingQuotaAvailability({required this.enabled, this.remaining});

  final bool enabled;
  final int? remaining;
}
