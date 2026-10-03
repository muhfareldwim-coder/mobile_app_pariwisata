import 'package:flutter/material.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
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
  final _leaderNameController = TextEditingController(text: 'Ahmad Pratama');
  final _leaderEmailController = TextEditingController(
    text: 'ahmad.pratama@email.com',
  );
  final _leaderPhoneController = TextEditingController(
    text: '+62 812-3456-7890',
  );
  final List<_Passenger> _passengers = [
    _Passenger(name: 'Siti Nurhaliza'),
    _Passenger(name: 'Rian Pratama', isChild: true),
    _Passenger(name: 'Citra Lestari'),
  ];
  DateTime _visitDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  int get _adultCount =>
      1 + _passengers.where((passenger) => !passenger.isChild).length;
  int get _childCount =>
      _passengers.where((passenger) => passenger.isChild).length;
  int get _childPrice =>
      ((widget.destination.ticketPrice * .6) / 1000).round() * 1000;
  int get _totalPrice =>
      (_adultCount * widget.destination.ticketPrice) +
      (_childCount * _childPrice);

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
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _visitDate.isBefore(today) ? today : _visitDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2),
      helpText: 'Pilih tanggal kunjungan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (selectedDate != null) setState(() => _visitDate = selectedDate);
  }

  void _addPassenger() {
    setState(() => _passengers.add(_Passenger()));
  }

  void _removePassenger(int index) {
    final passenger = _passengers.removeAt(index);
    passenger.nameController.dispose();
    setState(() {});
  }

  Future<void> _continueToPayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final booking = Booking(
      id: 'JMB-${DateTime.now().millisecondsSinceEpoch % 1000000}',
      destinationId: widget.destination.id,
      visitDate: _visitDate,
      adultCount: _adultCount,
      childCount: _childCount,
      leaderName: _leaderNameController.text.trim(),
      leaderEmail: _leaderEmailController.text.trim(),
      leaderPhone: _leaderPhoneController.text.trim(),
      memberNames: [
        for (final passenger in _passengers)
          passenger.nameController.text.trim(),
      ],
    );
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            PaymentPage(booking: booking, destination: widget.destination),
      ),
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
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
                          validator: _required,
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
                          validator: _required,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BookingSection(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Pilih Jumlah Tiket Masuk',
                      subtitle: 'Atur jenis tiket untuk seluruh rombongan.',
                      children: [
                        _TicketPriceRow(
                          title: 'Tiket Dewasa',
                          age: '12+ thn',
                          price: widget.destination.ticketPrice,
                        ),
                        const SizedBox(height: 10),
                        _TicketPriceRow(
                          title: 'Tiket Anak-anak',
                          age: '3-11 thn',
                          price: _childPrice,
                          note: 'Balita usia < 3 tahun gratis masuk',
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: _QuantityTile(
                                label: 'Tiket Dewasa',
                                value: _adultCount,
                                onDecrease: _passengers.isNotEmpty
                                    ? () {
                                        final index = _passengers
                                            .lastIndexWhere(
                                              (passenger) => !passenger.isChild,
                                            );
                                        if (index >= 0) _removePassenger(index);
                                      }
                                    : null,
                                onIncrease: _addPassenger,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _QuantityTile(
                                label: 'Tiket Anak',
                                value: _childCount,
                                onDecrease:
                                    _passengers.any(
                                      (passenger) => passenger.isChild,
                                    )
                                    ? () {
                                        final index = _passengers
                                            .lastIndexWhere(
                                              (passenger) => passenger.isChild,
                                            );
                                        if (index >= 0) _removePassenger(index);
                                      }
                                    : null,
                                onIncrease: () {
                                  setState(
                                    () => _passengers.add(
                                      _Passenger(isChild: true),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BookingSection(
                      icon: Icons.groups_2_outlined,
                      iconColor: _orange,
                      title: 'Data Anggota Rombongan',
                      subtitle: 'Cantumkan nama dan jenis tiket untuk manifest loket.',
                      children: [
                        for (
                          var index = 0;
                          index < _passengers.length;
                          index++
                        ) ...[
                          _PassengerCard(
                            index: index + 2,
                            passenger: _passengers[index],
                            onRemove: () => _removePassenger(index),
                            onTypeChanged: (isChild) => setState(
                              () => _passengers[index].isChild = isChild,
                            ),
                            requiredValidator: _required,
                          ),
                          if (index < _passengers.length - 1)
                            const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 11),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: TextButton.icon(
                            onPressed: _addPassenger,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F1FF),
                              foregroundColor: _blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.person_add_alt_1, size: 17),
                            label: const Text('+ Tambah Anggota Rombongan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PaymentSummary(
                      adultCount: _adultCount,
                      childCount: _childCount,
                      adultPrice: widget.destination.ticketPrice,
                      childPrice: _childPrice,
                      total: _totalPrice,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PaymentBar(
        total: _totalPrice,
        isLoading: _isSubmitting,
        onContinue: _continueToPayment,
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  String? _validEmail(String? value) {
    if (_required(value) != null) return _required(value);
    if (!value!.contains('@') || !value.contains('.')) {
      return 'Alamat email tidak valid';
    }
    return null;
  }
}

class _Passenger {
  _Passenger({String name = '', this.isChild = false})
    : nameController = TextEditingController(text: name);

  final TextEditingController nameController;
  bool isChild;
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
                'Detail',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: () {},
              tooltip: 'Profil',
              style: IconButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 19),
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
    required this.onDateTap,
  });

  final Destination destination;
  final DateTime visitDate;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              destination.imageUrl ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
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
                        fontSize: 11,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: _blue, size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formatDate(visitDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF576276),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_calendar_outlined, size: 15),
                    ],
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
              label: 'Data Rombongan',
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
              fontSize: 9,
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
    this.iconColor = _blue,
  });

  final IconData icon;
  final Color iconColor;
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
                  color: iconColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 19),
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
                        fontSize: 10,
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
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 42,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(color: _ink, fontSize: 12),
              decoration: _inputDecoration(icon),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketPriceRow extends StatelessWidget {
  const _TicketPriceRow({
    required this.title,
    required this.age,
    required this.price,
    this.note,
  });

  final String title;
  final String age;
  final int price;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              _Pill(age),
            ],
          ),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _formatPrice(price),
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: ' / orang',
                  style: TextStyle(color: Color(0xFF656D7A), fontSize: 10),
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: const TextStyle(color: Color(0xFF818895), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityTile extends StatelessWidget {
  const _QuantityTile({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 6, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E9F5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontSize: 10),
                ),
                Text(
                  '$value tiket',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            tooltip: 'Kurangi $label',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_circle_outline, size: 17),
          ),
          IconButton(
            onPressed: onIncrease,
            tooltip: 'Tambah $label',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_circle_outline, size: 17),
          ),
        ],
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({
    required this.index,
    required this.passenger,
    required this.onRemove,
    required this.onTypeChanged,
    required this.requiredValidator,
  });

  final int index;
  final _Passenger passenger;
  final VoidCallback onRemove;
  final ValueChanged<bool> onTypeChanged;
  final String? Function(String?) requiredValidator;

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
          const SizedBox(height: 5),
          const Text(
            'Nama Anggota',
            style: TextStyle(color: Color(0xFF4C5666), fontSize: 10),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 38,
            child: TextFormField(
              controller: passenger.nameController,
              validator: requiredValidator,
              style: const TextStyle(color: _ink, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Nama lengkap peserta',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
                errorStyle: TextStyle(fontSize: 9, height: .7),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Jenis Tiket',
            style: TextStyle(color: Color(0xFF4C5666), fontSize: 10),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Dewasa', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Anak-anak', style: TextStyle(fontSize: 10)),
                ),
              ],
              selected: {passenger.isChild},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? _navy
                      : Colors.white,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : _ink,
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Color(0xFFE3E6F2)),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              onSelectionChanged: (selection) => onTypeChanged(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.adultCount,
    required this.childCount,
    required this.adultPrice,
    required this.childPrice,
    required this.total,
  });

  final int adultCount;
  final int childCount;
  final int adultPrice;
  final int childPrice;
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
          _PriceLine(
            label: 'Tiket Dewasa (x$adultCount)',
            value: adultCount * adultPrice,
          ),
          if (childCount > 0) ...[
            const SizedBox(height: 6),
            _PriceLine(
              label: 'Tiket Anak (x$childCount)',
              value: childCount * childPrice,
            ),
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
                      fontSize: 21,
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
                  padding: const EdgeInsets.symmetric(horizontal: 23),
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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

String _formatDate(DateTime date) {
  const weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatCategory(String category) {
  if (category.isEmpty) return 'Wisata';
  final normalized = category.toLowerCase();
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
