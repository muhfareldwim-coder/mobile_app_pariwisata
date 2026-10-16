import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/booking_service.dart';
import '../../../core/utils/date_formatters.dart';
import 'payment_page.dart';

const _navy = Color(0xFF0B294A);
const _blue = Color(0xFF0874E8);
const _orange = Color(0xFFE98600);
const _pageBackground = Color(0xFFF9F8FF);
const _ink = Color(0xFF183757);
const _softPanel = Color(0xFFF5F6FF);

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.destination});

  final Destination destination;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _leaderNameController =
      TextEditingController(text: AuthService.currentUser?.name ?? '');
  late final TextEditingController _leaderEmailController =
      TextEditingController(text: AuthService.currentUser?.email ?? '');
  late final TextEditingController _leaderPhoneController =
      TextEditingController(text: AuthService.currentUser?.phone ?? '');
  final List<_Passenger> _passengers = [];
  int? _leaderTicketTypeId;
  DateTime? _visitDate;
  BookingQuotaAvailability? _quotaAvailability;
  bool _isCheckingQuota = false;
  int _quotaRequestId = 0;
  bool _isSubmitting = false;
  bool _hasDateError = false;

  List<DestinationTicketType> get _ticketTypes =>
      widget.destination.ticketTypes;
  int get _participantRowsCount => _passengers.length + 1;
  bool get _leaderDetailsReady =>
      _leaderNameController.text.trim().isNotEmpty &&
      _leaderEmailController.text.trim().isNotEmpty &&
      _leaderPhoneController.text.trim().isNotEmpty &&
      _visitDate != null;
  bool get _leaderReady => _leaderDetailsReady && _leaderTicketTypeId != null;
  int get _participantCount =>
      (_leaderReady ? 1 : 0) +
      _passengers
          .where(
            (passenger) =>
                passenger.nameController.text.trim().isNotEmpty &&
                passenger.ticketTypeId != null,
          )
          .length;
  int get _totalPrice => !_leaderReady
      ? 0
      : (_ticketType(_leaderTicketTypeId)?.price ?? 0) +
            _passengers.fold<int>(
              0,
              (total, passenger) =>
                  total + (_ticketType(passenger.ticketTypeId)?.price ?? 0),
            );

  DestinationTicketType? _ticketType(int? id) {
    if (id == null) return null;
    for (final ticket in _ticketTypes) {
      if (ticket.id == id) return ticket;
    }
    return null;
  }

  int _ticketCount(int ticketTypeId) => !_leaderReady
      ? 0
      : (_leaderTicketTypeId == ticketTypeId ? 1 : 0) +
            _passengers
                .where((passenger) => passenger.ticketTypeId == ticketTypeId)
                .length;

  @override
  void dispose() {
    _leaderNameController.dispose();
    _leaderEmailController.dispose();
    _leaderPhoneController.dispose();
    for (final passenger in _passengers) {
      passenger.nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final initialDate = _visitDate ?? todayDate.add(const Duration(days: 7));
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(todayDate) ? todayDate : initialDate,
      firstDate: todayDate,
      lastDate: DateTime(today.year, today.month + 2, today.day),
      helpText: 'Pilih tanggal kunjungan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selectedDate != null && mounted) {
      setState(() {
        _visitDate = selectedDate;
        _quotaAvailability = null;
        _hasDateError = false;
      });
      _loadQuota(selectedDate);
    }
  }

  Future<void> _loadQuota(DateTime visitDate) async {
    final requestId = ++_quotaRequestId;
    setState(() => _isCheckingQuota = true);
    try {
      final availability = await BookingService().getQuotaAvailability(
        destinationId: widget.destination.id,
        visitDate: visitDate,
      );
      if (!mounted || requestId != _quotaRequestId) return;
      setState(() => _quotaAvailability = availability);
    } on ApiException {
      if (!mounted || requestId != _quotaRequestId) return;
      setState(() => _quotaAvailability = null);
    } on FormatException {
      if (!mounted || requestId != _quotaRequestId) return;
      setState(() => _quotaAvailability = null);
    } finally {
      if (mounted && requestId == _quotaRequestId) {
        setState(() => _isCheckingQuota = false);
      }
    }
  }

  void _addPassenger() {
    if (_participantRowsCount >= 10) return;
    setState(() => _passengers.add(_Passenger()));
  }

  void _removePassenger(int index) {
    final passenger = _passengers.removeAt(index);
    passenger.nameController.dispose();
    setState(() {});
  }

  Future<void> _continueToPayment() async {
    if (_isSubmitting) return;
    if (_ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis tiket destinasi belum tersedia.')),
      );
      return;
    }
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasVisitDate = _visitDate != null;
    if (!hasVisitDate) {
      setState(() => _hasDateError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal kunjungan terlebih dahulu.'),
        ),
      );
    }
    if (!isFormValid || !hasVisitDate) return;
    if (_leaderTicketTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis tiket ketua terlebih dahulu.'),
        ),
      );
      return;
    }
    if (_passengers.any(
      (passenger) =>
          _validParticipantName(passenger.nameController.text) != null ||
          _ticketType(passenger.ticketTypeId) == null,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama dan jenis tiket semua anggota.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final leaderTicket = _ticketType(_leaderTicketTypeId);
      if (leaderTicket == null) {
        throw const FormatException('Jenis tiket ketua tidak valid.');
      }
      final participants = <BookingParticipant>[
        BookingParticipant(
          name: _leaderNameController.text.trim(),
          ticketTypeId: leaderTicket.id,
          ticketTypeName: leaderTicket.name,
          ticketPrice: leaderTicket.price,
        ),
        for (final passenger in _passengers)
          if (_ticketType(passenger.ticketTypeId) case final ticket?)
            BookingParticipant(
              name: passenger.nameController.text.trim(),
              ticketTypeId: ticket.id,
              ticketTypeName: ticket.name,
              ticketPrice: ticket.price,
            ),
      ];
      final booking = await BookingService().createBooking(
        destinationId: widget.destination.id,
        visitDate: _visitDate!,
        leaderName: _leaderNameController.text.trim(),
        leaderEmail: _leaderEmailController.text.trim(),
        leaderPhone: _leaderPhoneController.text.trim(),
        participants: participants,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              PaymentPage(booking: booking, destination: widget.destination),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formChanges = Listenable.merge([
      _leaderNameController,
      _leaderEmailController,
      _leaderPhoneController,
      for (final passenger in _passengers) passenger.nameController,
    ]);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BookingHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    _DestinationSummary(
                      destination: widget.destination,
                      visitDate: _visitDate,
                      hasDateError: _hasDateError,
                      isCheckingQuota: _isCheckingQuota,
                      quotaAvailability: _quotaAvailability,
                      onDateTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    const _BookingProgress(),
                    const SizedBox(height: 16),
                    _BookingSection(
                      icon: Icons.badge_outlined,
                      title: 'Data Ketua Kelompok',
                      subtitle: 'E-ticket dan bukti transaksi akan dikirimkan ke kontak penanggung jawab ini.',
                      children: [
                        _BookingInput(
                          label: 'Nama Lengkap (Ketua)',
                          controller: _leaderNameController,
                          icon: Icons.person_outline,
                          validator: _validName,
                        ),
                        _BookingInput(
                          label: 'Alamat Email',
                          controller: _leaderEmailController,
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validEmail,
                        ),
                        _BookingInput(
                          label: 'Nomor WhatsApp / HP',
                          controller: _leaderPhoneController,
                          icon: Icons.phone_iphone_rounded,
                          keyboardType: TextInputType.phone,
                          maxLength: 16,
                          validator: _validPhone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BookingSection(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Peserta dan jenis tiket',
                      subtitle:
                          'Ketua dan setiap anggota memilih satu jenis tiket.',
                      children: [
                        if (_ticketTypes.isEmpty)
                          const Text(
                            'Pilihan tiket belum tersedia dari server.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: formChanges,
                          builder: (context, child) => Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Peserta terisi',
                                  style: TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '$_participantCount/10 orang',
                                style: const TextStyle(
                                  color: _blue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PassengerCard(
                          index: 1,
                          nameController: _leaderNameController,
                          ticketTypeId: _leaderTicketTypeId,
                          ticketTypes: _ticketTypes,
                          isLeader: true,
                          onRemove: null,
                          onTypeChanged: (ticketTypeId) => setState(
                            () => _leaderTicketTypeId = ticketTypeId,
                          ),
                          requiredValidator: _validName,
                        ),
                        const SizedBox(height: 10),
                        for (
                          var index = 0;
                          index < _passengers.length;
                          index++
                        ) ...[
                          _PassengerCard(
                            index: index + 2,
                            nameController: _passengers[index].nameController,
                            ticketTypeId: _passengers[index].ticketTypeId,
                            ticketTypes: _ticketTypes,
                            onRemove: () => _removePassenger(index),
                            isLeader: false,
                            onTypeChanged: (ticketTypeId) => setState(
                              () => _passengers[index].ticketTypeId =
                                  ticketTypeId,
                            ),
                            requiredValidator: _validParticipantName,
                          ),
                          if (index < _passengers.length - 1)
                            const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed:
                                _participantRowsCount < 10 &&
                                    _ticketTypes.isNotEmpty
                                ? _addPassenger
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: _blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.person_add_alt_1, size: 17),
                            label: const Text('Tambah anggota'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: formChanges,
                      builder: (context, child) => _PaymentSummary(
                        ticketTypes: _ticketTypes,
                        ticketCounts: {
                          for (final ticket in _ticketTypes)
                            ticket.id: _ticketCount(ticket.id),
                        },
                        total: _totalPrice,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: formChanges,
        builder: (context, child) => _PaymentBar(
          total: _totalPrice,
          isLoading: _isSubmitting,
          onContinue: _continueToPayment,
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  String? _validName(String? value) {
    if (_required(value) != null) return _required(value);
    if (value!.length > 150) return 'Nama maksimal 150 karakter.';
    return RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value.trim())
        ? null
        : 'Nama lengkap hanya boleh berisi huruf dan spasi.';
  }

  String? _validParticipantName(String? value) {
    if (_required(value) != null) return _required(value);
    if (value!.length > 150) return 'Nama maksimal 150 karakter.';
    return RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value.trim())
        ? null
        : 'Nama peserta hanya boleh berisi huruf dan spasi.';
  }

  String? _validPhone(String? value) {
    if (_required(value) != null) return _required(value);
    if (value!.length > 16) {
      return 'Gunakan 10-12 digit lokal atau awali + untuk nomor internasional (maksimal 15 digit).';
    }
    return RegExp(r'^(?:[0-9]{10,12}|\+[0-9]{10,15})$').hasMatch(value.trim())
        ? null
        : 'Gunakan 10-12 digit lokal atau awali + untuk nomor internasional (maksimal 15 digit).';
  }

  String? _validEmail(String? value) {
    if (_required(value) != null) return _required(value);
    final email = value!.trim();
    final atIndex = email.lastIndexOf('@');
    if (email.length > 150 ||
        !RegExp(
          r"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@gmail\.com$",
          caseSensitive: false,
        ).hasMatch(email) ||
        email.startsWith('.') ||
        email.contains('..') ||
        (atIndex > 0 && email.substring(0, atIndex).endsWith('.'))) {
      return 'Email harus menggunakan alamat @gmail.com.';
    }
    return null;
  }
}

class _Passenger {
  _Passenger() : nameController = TextEditingController();

  final TextEditingController nameController;
  int? ticketTypeId;
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back, color: _ink),
            ),
            const Expanded(
              child: Text(
                'Pemesanan Tiket',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationSummary extends StatelessWidget {
  const _DestinationSummary({
    required this.destination,
    required this.visitDate,
    required this.hasDateError,
    required this.isCheckingQuota,
    required this.quotaAvailability,
    required this.onDateTap,
  });

  final Destination destination;
  final DateTime? visitDate;
  final bool hasDateError;
  final bool isCheckingQuota;
  final BookingQuotaAvailability? quotaAvailability;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  destination.imageUrl ?? '',
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 82,
                    height: 82,
                    color: const Color(0xFFE2EDF5),
                    child: const Icon(Icons.landscape_outlined, color: _navy),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: _Pill(_formatCategory(destination.category)),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '★ ${destination.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: _orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      destination.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF66758A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onDateTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: hasDateError ? Colors.red : _blue,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      visitDate == null
                          ? 'Pilih tanggal kunjungan'
                          : formatIndonesianDate(visitDate!),
                      style: TextStyle(
                        color: hasDateError
                            ? Colors.red
                            : visitDate == null
                            ? const Color(0xFF66758A)
                            : _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: Color(0xFF66758A),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (hasDateError) ...[
            const SizedBox(height: 4),
            const Text(
              'Tanggal kunjungan wajib dipilih.',
              style: TextStyle(color: Color(0xFFB42318), fontSize: 12),
            ),
          ],
          const SizedBox(height: 3),
          _QuotaMessage(
            visitDate: visitDate,
            isCheckingQuota: isCheckingQuota,
            quotaAvailability: quotaAvailability,
          ),
        ],
      ),
    );
  }
}

class _BookingProgress extends StatelessWidget {
  const _BookingProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: _StepIndicator(
              number: '1',
              label: 'Data Peserta',
              active: true,
            ),
          ),
          Expanded(flex: 1, child: Divider(color: Color(0xFFD4DAF2))),
          Expanded(
            flex: 2,
            child: _StepIndicator(number: '2', label: 'Pembayaran'),
          ),
          Expanded(flex: 1, child: Divider(color: Color(0xFFD4DAF2))),
          Expanded(
            flex: 2,
            child: _StepIndicator(number: '3', label: 'E-Tiket'),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? _navy : const Color(0xFF7D8493);
    return Row(
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: active ? _navy : const Color(0xFFDCE2F5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF56637B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingSection extends StatelessWidget {
  const _BookingSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _blue, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF727B8B),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }
}

class _BookingInput extends StatelessWidget {
  const _BookingInput({
    required this.label,
    required this.controller,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.maxLength = 150,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            style: const TextStyle(color: _ink, fontSize: 14),
            decoration: _inputDecoration(icon),
          ),
        ],
      ),
    );
  }
}

class _QuotaMessage extends StatelessWidget {
  const _QuotaMessage({
    required this.visitDate,
    required this.isCheckingQuota,
    required this.quotaAvailability,
  });

  final DateTime? visitDate;
  final bool isCheckingQuota;
  final BookingQuotaAvailability? quotaAvailability;

  @override
  Widget build(BuildContext context) {
    final availability = quotaAvailability;
    final quotaMessage = isCheckingQuota
        ? 'Memeriksa sisa tiket...'
        : visitDate == null
        ? 'Pilih tanggal untuk melihat sisa tiket.'
        : availability == null
        ? 'Sisa tiket akan diperiksa saat pesanan dikirim.'
        : availability.enabled
        ? 'Sisa tiket pada tanggal ini: ${availability.remaining} peserta.'
        : 'Destinasi ini tidak menerapkan batas kuota tiket.';

    return Text(
      quotaMessage,
      style: const TextStyle(
        color: Color(0xFF66758A),
        fontSize: 11,
        height: 1.35,
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({
    required this.index,
    required this.nameController,
    required this.ticketTypeId,
    required this.ticketTypes,
    required this.onRemove,
    required this.onTypeChanged,
    required this.requiredValidator,
    required this.isLeader,
  });

  final int index;
  final TextEditingController nameController;
  final int? ticketTypeId;
  final List<DestinationTicketType> ticketTypes;
  final VoidCallback? onRemove;
  final ValueChanged<int> onTypeChanged;
  final String? Function(String?) requiredValidator;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill('Peserta $index', dark: true),
              const Spacer(),
              if (isLeader)
                const _Pill('Ketua kelompok')
              else
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Hapus peserta $index',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            isLeader ? 'Nama ketua' : 'Nama anggota',
            style: const TextStyle(color: Color(0xFF385872), fontSize: 12),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: nameController,
            readOnly: isLeader,
            validator: isLeader ? null : requiredValidator,
            style: const TextStyle(color: _ink, fontSize: 14),
            maxLength: 150,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            decoration: const InputDecoration(
              hintText: 'Nama lengkap peserta',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE0E5EF)),
              ),
              errorStyle: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Jenis Tiket',
            style: TextStyle(color: Color(0xFF385872), fontSize: 12),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: ticketTypes.any((ticket) => ticket.id == ticketTypeId)
                ? ticketTypeId
                : null,
            hint: const Text('Pilih jenis tiket'),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE0E5EF)),
              ),
              errorStyle: TextStyle(fontSize: 11),
            ),
            items: [
              for (final ticket in ticketTypes)
                DropdownMenuItem(
                  value: ticket.id,
                  child: Text(
                    '${ticket.name} - ${_formatPrice(ticket.price)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
            onChanged: ticketTypes.isEmpty
                ? null
                : (ticketId) {
                    if (ticketId != null) onTypeChanged(ticketId);
                  },
            validator: (ticketId) =>
                ticketId == null ? 'Pilih jenis tiket.' : null,
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.ticketTypes,
    required this.ticketCounts,
    required this.total,
  });

  final List<DestinationTicketType> ticketTypes;
  final Map<int, int> ticketCounts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: _blue, size: 18),
              SizedBox(width: 7),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final ticket in ticketTypes)
            if ((ticketCounts[ticket.id] ?? 0) > 0) ...[
              _PriceLine(
                label: '${ticket.name} (x${ticketCounts[ticket.id]})',
                value: ticket.price * (ticketCounts[ticket.id] ?? 0),
              ),
              const SizedBox(height: 6),
            ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFDDE2F1)),
          const SizedBox(height: 9),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Tagihan',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatPrice(total),
                style: const TextStyle(
                  color: _blue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF5F6673), fontSize: 11),
          ),
        ),
        Text(
          _formatPrice(value),
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar({
    required this.total,
    required this.isLoading,
    required this.onContinue,
  });

  final int total;
  final bool isLoading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1209233F),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(color: Color(0xFF6F7683), fontSize: 10),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _formatPrice(total),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text(
                  'Lanjut Bayar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? _navy : const Color(0xFFE6EAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: dark ? Colors.white : _blue,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(IconData icon) => InputDecoration(
  prefixIcon: Icon(icon, color: const Color(0xFF7A8392), size: 18),
  filled: true,
  fillColor: _softPanel,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: _blue, width: 1.2),
  ),
  errorStyle: const TextStyle(fontSize: 9, height: .7),
);

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(15),
  boxShadow: const [
    BoxShadow(color: Color(0x0809233F), blurRadius: 12, offset: Offset(0, 3)),
  ],
);

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _formatCategory(String category) {
  if (category.isEmpty) return 'Wisata';
  final normalized = category.toLowerCase();
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
