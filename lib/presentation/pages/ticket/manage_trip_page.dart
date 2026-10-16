import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/destination.dart';
import '../../../data/models/trip_management.dart';
import '../../../data/models/ticket.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../../data/services/trip_management_service.dart';
import '../../../core/utils/date_formatters.dart';
import '../booking/payment_page.dart';

const _manageNavy = Color(0xFF173B60);
const _manageBlue = Color(0xFF0874E8);
const _manageOrange = Color(0xFFF58B05);
const _manageBackground = Color(0xFFF8FAFC);

class ManageTripPage extends StatefulWidget {
  const ManageTripPage({
    super.key,
    required this.ticket,
    this.tripService,
    this.paymentService,
  });

  final Ticket ticket;
  final TripManagementService? tripService;
  final PaymentService? paymentService;

  @override
  State<ManageTripPage> createState() => _ManageTripPageState();
}

class _ManageTripPageState extends State<ManageTripPage> {
  late final TripManagementService _tripService;
  late final PaymentService _paymentService;
  final List<_MemberInput> _newMembers = [];
  TripManagement? _trip;
  DateTime? _visitDate;
  String? _error;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _membersInitialized = false;

  @override
  void initState() {
    super.initState();
    _tripService = widget.tripService ?? TripManagementService();
    _paymentService = widget.paymentService ?? PaymentService();
    unawaited(_loadTrip());
  }

  @override
  void dispose() {
    for (final member in _newMembers) {
      member.nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTrip() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final trip = await _tripService.getTrip(widget.ticket.bookingRecordId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _visitDate ??= trip.booking.visitDate;
        if (!_membersInitialized) {
          _membersInitialized = true;
          if (trip.remainingSlots > 0) {
            _newMembers.add(
              _MemberInput(nameController: TextEditingController()),
            );
          }
        }
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _additionalTotal {
    final trip = _trip;
    if (trip == null) return 0;
    return _newMembers.fold(0, (total, member) {
      final ticketType = trip.ticketTypes.where(
        (type) => type.id == member.ticketTypeId,
      );
      return total + (ticketType.isEmpty ? 0 : ticketType.first.price);
    });
  }

  List<_MemberInput> get _completeMembers => _newMembers
      .where(
        (member) =>
            member.nameController.text.trim().isNotEmpty &&
            member.ticketTypeId != null,
      )
      .toList();

  bool get _hasIncompleteMember => _newMembers.any((member) {
    final hasName = member.nameController.text.trim().isNotEmpty;
    final hasTicketType = member.ticketTypeId != null;
    return hasName != hasTicketType;
  });

  bool get _hasChanges {
    final trip = _trip;
    final visitDate = _visitDate;
    if (trip == null || visitDate == null) return false;
    return !_sameDay(visitDate, trip.booking.visitDate) ||
        _completeMembers.isNotEmpty;
  }

  Future<void> _selectDate() async {
    final trip = _trip;
    if (trip == null) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final latest = DateUtils.dateOnly(
      DateTime(today.year, today.month + 2, today.day),
    );
    final selected = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: _visitDate ?? trip.booking.visitDate,
      firstDate: today,
      lastDate: latest,
      helpText: 'Pilih tanggal kunjungan',
      confirmText: 'Pilih tanggal',
      cancelText: 'Batal',
    );
    if (selected != null && mounted) {
      setState(() => _visitDate = selected);
    }
  }

  void _addMember() {
    final trip = _trip;
    if (trip == null || _newMembers.length >= trip.remainingSlots) return;
    setState(() {
      _newMembers.add(_MemberInput(nameController: TextEditingController()));
    });
  }

  void _removeMember(int index) {
    final member = _newMembers.removeAt(index);
    member.nameController.dispose();
    setState(() {});
  }

  Future<void> _submitChanges() async {
    final trip = _trip;
    final visitDate = _visitDate;
    if (trip == null || visitDate == null || _isSubmitting) return;
    if (!_hasChanges) {
      setState(
        () =>
            _error = 'Pilih tanggal baru atau tambahkan minimal satu anggota.',
      );
      return;
    }
    if (_hasIncompleteMember) {
      setState(() => _error = 'Lengkapi nama dan jenis tiket setiap anggota.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final change = await _tripService.createChange(
        bookingId: trip.booking.id,
        visitDate: visitDate,
        members: [
          for (final member in _completeMembers)
            TripMemberDraft(
              name: member.nameController.text.trim(),
              ticketTypeId: member.ticketTypeId!,
            ),
        ],
      );
      await _continueChange(trip, change);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continuePendingChange() async {
    final trip = _trip;
    final change = trip?.pendingChange;
    if (trip == null || change == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await _continueChange(trip, change);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueChange(
    TripManagement trip,
    PendingTripChange change,
  ) async {
    if (change.amount == 0) {
      final payment = await _paymentService.createAdditionalPayment(
        trip.booking.id,
        change.id,
      );
      if (payment.status.toUpperCase() != 'CONFIRMED') {
        throw const FormatException(
          'Perubahan perjalanan belum dapat dikonfirmasi.',
        );
      }
      if (!mounted) return;
      await TicketService().refreshFromServer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan perjalanan berhasil disimpan.'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PaymentPage(
          booking: trip.booking,
          destination: trip.destination,
          additionalChangeId: change.id,
          paymentAmount: change.amount,
          paymentService: _paymentService,
        ),
      ),
    );
  }

  Future<bool> _confirmChanges() async {
    final trip = _trip;
    if (trip == null) return false;
    final visitDate = _visitDate ?? trip.booking.visitDate;
    final total = _additionalTotal;
    final newMembers = _completeMembers.map((member) {
      final type = trip.ticketTypes.where(
        (item) => item.id == member.ticketTypeId,
      );
      return '${member.nameController.text.trim()} · ${type.isEmpty ? 'Tiket' : type.first.name}';
    }).toList();

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Tinjau perubahan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destinasi: ${trip.destination.name}'),
                const SizedBox(height: 8),
                Text('Tanggal kunjungan: ${formatIndonesianDate(visitDate)}'),
                if (newMembers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Anggota tambahan:'),
                  for (final member in newMembers) Text('• $member'),
                ],
                const SizedBox(height: 8),
                Text('Biaya tambahan: ${_formatPrice(total)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Periksa lagi'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(total > 0 ? 'Lanjut bayar' : 'Konfirmasi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return Scaffold(
      backgroundColor: _manageBackground,
      appBar: AppBar(
        title: const Text('Kelola perjalanan'),
        foregroundColor: _manageNavy,
        backgroundColor: _manageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trip == null
          ? _LoadError(
              message: _error ?? 'Data perjalanan tidak tersedia.',
              onRetry: _loadTrip,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _BookingSummary(trip: trip),
                if (trip.pendingChange != null) ...[
                  const SizedBox(height: 14),
                  _PendingChangeCard(
                    change: trip.pendingChange!,
                    isProcessing: _isSubmitting,
                    onContinue: _continuePendingChange,
                  ),
                ],
                const SizedBox(height: 14),
                _ManageSection(
                  icon: Icons.calendar_month_rounded,
                  eyebrow: 'PERJALANAN',
                  title: 'Ubah jadwal',
                  description: 'Pilih tanggal baru untuk kunjungan Anda.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal kunjungan baru'),
                      const SizedBox(height: 2),
                      const Text(
                        'Pilih tanggal yang paling sesuai untuk perjalanan.',
                        style: TextStyle(
                          color: Color(0xFF7890A1),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _selectDate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _manageNavy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: Color(0xFFD7E2EC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: _manageOrange,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatIndonesianDate(
                                        _visitDate ?? trip.booking.visitDate,
                                      ),
                                      style: const TextStyle(
                                        color: _manageNavy,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Ketuk untuk memilih tanggal',
                                      style: TextStyle(
                                        color: Color(0xFF7890A1),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF7890A1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0xFFE7EDF2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFF7890A1),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jadwal saat ini: ${formatIndonesianDate(trip.booking.visitDate)}',
                                style: const TextStyle(
                                  color: Color(0xFF617486),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tanggal tersedia mulai hari ini hingga 2 bulan ke depan.',
                        style: TextStyle(
                          color: Color(0xFF7890A1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ManageSection(
                  icon: Icons.people_alt_outlined,
                  eyebrow: 'DATA TIKET',
                  title: 'Tambah tiket',
                  description: 'Tambahkan anggota atau tiket tambahan untuk perjalanan Anda.',
                  child: trip.remainingSlots == 0
                      ? const Text(
                          'Jumlah peserta saat ini sudah mencapai batas 10 orang.',
                        )
                      : Column(
                          children: [
                            for (
                              var index = 0;
                              index < _newMembers.length;
                              index++
                            )
                              _MemberForm(
                                key: ValueKey(_newMembers[index]),
                                number: index + 1,
                                member: _newMembers[index],
                                ticketTypes: trip.ticketTypes,
                                onRemove: () => _removeMember(index),
                                onNameChanged: (_) {
                                  setState(() {});
                                },
                                onTicketTypeChanged: (ticketTypeId) {
                                  setState(
                                    () => _newMembers[index].ticketTypeId =
                                        ticketTypeId,
                                  );
                                },
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed:
                                    _newMembers.length >= trip.remainingSlots
                                    ? null
                                    : _addMember,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _manageNavy,
                                  side: const BorderSide(
                                    color: Color(0xFFD7E2EC),
                                  ),
                                  minimumSize: const Size.fromHeight(46),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      color: _manageOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Tambah anggota',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${trip.remainingSlots} slot tiket tersedia · maksimal 10 orang per pemesanan.',
                                style: const TextStyle(
                                  color: Color(0xFF7890A1),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                _ManageSummary(
                  trip: trip,
                  additionalCount: _completeMembers.length,
                  additionalTotal: _additionalTotal,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _InlineError(message: _error!),
                ],
                const SizedBox(height: 14),
                if (trip.pendingChange != null)
                  const _InlineNotice(
                    message: 'Selesaikan perubahan yang tertunda sebelum membuat perubahan baru.',
                  ),
                if (trip.pendingChange != null) const SizedBox(height: 10),
              ],
            ),
      bottomNavigationBar: _isLoading || trip == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE7EDF2))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _isSubmitting ||
                                trip.pendingChange != null ||
                                !_hasChanges
                            ? null
                            : () async {
                                if (_hasIncompleteMember) {
                                  setState(
                                    () => _error = 'Lengkapi nama dan jenis tiket setiap anggota.',
                                  );
                                  return;
                                }
                                if (await _confirmChanges()) {
                                  await _submitChanges();
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: _manageOrange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE8EEF3),
                          disabledForegroundColor: _manageNavy,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _hasChanges
                                    ? Icons.arrow_forward_rounded
                                    : Icons.edit_calendar_outlined,
                              ),
                        label: Text(
                          _isSubmitting
                              ? 'Memproses perubahan...'
                              : trip.pendingChange != null
                              ? 'Perubahan tertunda'
                              : _hasChanges
                              ? 'Lihat perubahan'
                              : 'Pilih tanggal atau tambah anggota',
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      trip.pendingChange != null
                          ? 'Lanjutkan pembayaran dari kartu perubahan di atas.'
                          : _hasChanges
                          ? 'Periksa kembali perubahan sebelum melanjutkan.'
                          : 'Jadwal tetap sampai Anda memilih perubahan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF617486),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MemberInput {
  _MemberInput({required this.nameController});

  final TextEditingController nameController;
  int? ticketTypeId;
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.trip});

  final TripManagement trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: _manageBlue,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  trip.booking.code,
                  style: const TextStyle(
                    color: _manageBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Lunas',
                  style: TextStyle(
                    color: Color(0xFF13795B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            trip.destination.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _manageNavy,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _BookingSummaryItem(
                icon: Icons.people_alt_outlined,
                text: '${trip.booking.quantity} peserta',
              ),
              _BookingSummaryItem(
                icon: Icons.payments_outlined,
                text: '${_formatPrice(trip.booking.totalAmount)} dibayar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingSummaryItem extends StatelessWidget {
  const _BookingSummaryItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: const Color(0xFF7890A1)),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(color: Color(0xFF617486), fontSize: 12),
      ),
    ],
  );
}

class _PendingChangeCard extends StatelessWidget {
  const _PendingChangeCard({
    required this.change,
    required this.isProcessing,
    required this.onContinue,
  });

  final PendingTripChange change;
  final bool isProcessing;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1D5A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: Color(0xFF9A5200),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ada perubahan yang belum selesai',
                  style: TextStyle(
                    color: _manageNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Biaya tambahan: ${_formatPrice(change.amount)}',
                  style: const TextStyle(color: Color(0xFF617486)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: isProcessing ? null : onContinue,
                  child: Text(
                    isProcessing ? 'Memproses...' : 'Lanjutkan pembayaran',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageSection extends StatelessWidget {
  const _ManageSection({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0609233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _manageOrange, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: _manageOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _manageNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF667080),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _MemberForm extends StatelessWidget {
  const _MemberForm({
    super.key,
    required this.number,
    required this.member,
    required this.ticketTypes,
    required this.onRemove,
    required this.onNameChanged,
    required this.onTicketTypeChanged,
  });

  final int number;
  final _MemberInput member;
  final List<DestinationTicketType> ticketTypes;
  final VoidCallback onRemove;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int?> onTicketTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EDF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Anggota ${number.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: _manageNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus anggota',
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFB54747),
                  ),
                ),
              ],
            ),
            TextField(
              controller: member.nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: onNameChanged,
              decoration: InputDecoration(
                labelText: 'Nama anggota',
                hintText: 'Masukkan nama',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD7E2EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD7E2EC)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: member.ticketTypeId,
              isExpanded: true,
              hint: const Text('Pilih jenis tiket'),
              decoration: InputDecoration(
                labelText: 'Jenis tiket',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD7E2EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD7E2EC)),
                ),
              ),
              items: [
                for (final type in ticketTypes)
                  DropdownMenuItem<int>(
                    value: type.id,
                    child: Text('${type.name} · ${_formatPrice(type.price)}'),
                  ),
              ],
              onChanged: onTicketTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageSummary extends StatelessWidget {
  const _ManageSummary({
    required this.trip,
    required this.additionalCount,
    required this.additionalTotal,
  });

  final TripManagement trip;
  final int additionalCount;
  final int additionalTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0609233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan pesanan',
            style: TextStyle(
              color: _manageOrange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            trip.destination.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _manageNavy,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF7890A1),
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  trip.destination.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7890A1),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryLine(
            label: 'Jadwal saat ini',
            value: formatIndonesianDate(trip.booking.visitDate),
          ),
          const SizedBox(height: 8),
          _SummaryLine(
            label: 'Jumlah tiket',
            value: '${trip.booking.quantity} tiket',
          ),
          const Divider(height: 22),
          _SummaryLine(
            label: 'Tiket tambahan',
            value: '$additionalCount tiket',
          ),
          const SizedBox(height: 8),
          _SummaryLine(
            label: 'Subtotal tambahan',
            value: _formatPrice(additionalTotal),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _SummaryLine(
              label: 'Total biaya tambahan',
              value: _formatPrice(additionalTotal),
              emphasize: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: emphasize ? _manageNavy : const Color(0xFF667080),
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasize ? 15 : 13,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF1D5A8)),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Color(0xFF80520B), fontSize: 12),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _formatPrice(int amount) =>
    'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
