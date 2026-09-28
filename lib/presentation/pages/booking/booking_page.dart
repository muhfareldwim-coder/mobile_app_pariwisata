import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/booking_service.dart';
import '../ticket/ticket_ui_page.dart';
import 'checkout_page.dart';

String _rupiah(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.destination});

  final Destination destination;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _memberControllers = <TextEditingController>[];

  DateTime _visitDate = DateUtils.dateOnly(DateTime.now());
  int _adultCount = 1;
  int _childCount = 0;
  bool _isSubmitting = false;

  int get _quantity => _adultCount + _childCount;
  int get _total => widget.destination.ticketPrice * _quantity;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final controller in _memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncMemberFields() {
    final memberCount = _quantity - 1;
    while (_memberControllers.length < memberCount) {
      _memberControllers.add(TextEditingController());
    }
    while (_memberControllers.length > memberCount) {
      _memberControllers.removeLast().dispose();
    }
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _visitDate.isBefore(today) ? today : _visitDate,
      firstDate: today,
      lastDate: DateTime(today.year + 3),
      helpText: 'Pilih tanggal kunjungan',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
    );
    if (selected != null && mounted) {
      setState(() => _visitDate = DateUtils.dateOnly(selected));
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bagian ini wajib diisi';
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    final at = email.indexOf('@');
    if (at <= 0 ||
        at == email.length - 1 ||
        !email.substring(at).contains('.')) {
      return 'Masukkan alamat email yang valid';
    }
    return null;
  }

  Future<void> _continueToCheckout() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final booking = await BookingService().createBooking(
        Booking(
          id: 'BOOK-${BookingService.bookings.length + 1}',
          destinationId: widget.destination.id,
          visitDate: _visitDate,
          adultCount: _adultCount,
          childCount: _childCount,
          leaderName: _nameController.text.trim(),
          leaderEmail: _emailController.text.trim(),
          leaderPhone: _phoneController.text.trim(),
          memberNames: List.unmodifiable(
            _memberControllers.map((controller) => controller.text.trim()),
          ),
        ),
      );
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              CheckoutPage(booking: booking, destination: widget.destination),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TicketUIPage()),
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.support_agent,
                color: AppColors.blueDeep,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Butuh bantuan pemesanan?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Isi data pemesan dan jumlah tiket. Setelah menekan Lanjut Bayar, '
                'periksa kembali pesanan sebelum memilih metode pembayaran.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _BookingTopBar(onBack: _goBack, onHelp: _showHelp),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BookingSteps(),
                          const SizedBox(height: 12),
                          _DestinationCard(destination: widget.destination),
                          const SizedBox(height: 12),
                          _SectionCard(
                            icon: Icons.person_outline,
                            title: 'Data ketua kelompok',
                            subtitle:
                                'Informasi ini digunakan untuk mengirim tiket.',
                            child: Column(
                              children: [
                                _BookingInput(
                                  controller: _nameController,
                                  label: 'Nama lengkap',
                                  hint: 'Masukkan nama pemesan',
                                  icon: Icons.badge_outlined,
                                  validator: _required,
                                  capitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 10),
                                _BookingInput(
                                  controller: _emailController,
                                  label: 'Email aktif',
                                  hint: 'nama@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                ),
                                const SizedBox(height: 10),
                                _BookingInput(
                                  controller: _phoneController,
                                  label: 'Nomor WhatsApp',
                                  hint: '08xxxxxxxxxx',
                                  icon: Icons.phone_android_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: _required,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SectionCard(
                            icon: Icons.confirmation_number_outlined,
                            title: 'Pilih jumlah tiket',
                            subtitle: 'Tentukan tiket untuk rombongan Anda.',
                            child: Column(
                              children: [
                                _TicketCounter(
                                  label: 'Tiket dewasa',
                                  helper: 'Usia 12 tahun ke atas',
                                  count: _adultCount,
                                  minimum: 1,
                                  onChanged: (value) {
                                    setState(() {
                                      _adultCount = value;
                                      _syncMemberFields();
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                _TicketCounter(
                                  label: 'Tiket anak',
                                  helper: 'Usia di bawah 12 tahun',
                                  count: _childCount,
                                  minimum: 0,
                                  onChanged: (value) {
                                    setState(() {
                                      _childCount = value;
                                      _syncMemberFields();
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                _DateSelector(
                                  date: _visitDate,
                                  onTap: _selectDate,
                                ),
                              ],
                            ),
                          ),
                          if (_memberControllers.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _SectionCard(
                              icon: Icons.groups_outlined,
                              title: 'Data anggota kelompok',
                              subtitle:
                                  'Isi nama peserta selain ketua kelompok.',
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < _memberControllers.length;
                                    index++
                                  ) ...[
                                    _BookingInput(
                                      controller: _memberControllers[index],
                                      label: 'Nama anggota ${index + 1}',
                                      hint: 'Masukkan nama peserta',
                                      icon: Icons.person_outline,
                                      validator: _required,
                                      capitalization: TextCapitalization.words,
                                    ),
                                    if (index < _memberControllers.length - 1)
                                      const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _PaymentSummary(
                            adultCount: _adultCount,
                            childCount: _childCount,
                            ticketPrice: widget.destination.ticketPrice,
                            total: _total,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _BookingFooter(
              quantity: _quantity,
              total: _total,
              isSubmitting: _isSubmitting,
              onContinue: _continueToCheckout,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingTopBar extends StatelessWidget {
  const _BookingTopBar({required this.onBack, required this.onHelp});

  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Detail',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onHelp,
            tooltip: 'Bantuan',
            icon: const Icon(Icons.help_outline, color: AppColors.blueDeep),
          ),
        ],
      ),
    );
  }
}

class _BookingSteps extends StatelessWidget {
  const _BookingSteps();

  @override
  Widget build(BuildContext context) {
    const labels = ['Data pemesan', 'Pembayaran', 'E-Tiket'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index == 0 ? AppColors.orange : AppColors.border,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0 ? AppColors.orange : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == 0
                              ? AppColors.orange
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index == 0 ? Colors.white : AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < labels.length - 1
                            ? AppColors.border
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: index == 0 ? AppColors.blueDeep : AppColors.muted,
                    fontSize: 9,
                    fontWeight: index == 0
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final imageUrl = destination.imageUrl;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 70,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const _DestinationPlaceholder()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const _DestinationPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sky.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DESTINASI WISATA',
                    style: TextStyle(
                      color: AppColors.blueDeep,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${destination.location}  •  ${_rupiah(destination.ticketPrice)}/tiket',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.muted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationPlaceholder extends StatelessWidget {
  const _DestinationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB8E3EE), Color(0xFF5AA8BC), Color(0xFF126080)],
        ),
      ),
      child: Icon(Icons.landscape_outlined, color: Colors.white, size: 32),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: AppColors.blueDeep),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BookingInput extends StatelessWidget {
  const _BookingInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.blueDeep, width: 1.4),
        ),
      ),
    );
  }
}

class _TicketCounter extends StatelessWidget {
  const _TicketCounter({
    required this.label,
    required this.helper,
    required this.count,
    required this.minimum,
    required this.onChanged,
  });

  final String label;
  final String helper;
  final int count;
  final int minimum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: count > minimum ? () => onChanged(count - 1) : null,
            tooltip: 'Kurangi $label',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(count + 1),
            tooltip: 'Tambah $label',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.blueDeep,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.blueDeep,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal kunjungan',
                      style: TextStyle(color: AppColors.muted, fontSize: 9),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date.day.toString().padLeft(2, '0')}/'
                      '${date.month.toString().padLeft(2, '0')}/${date.year}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.adultCount,
    required this.childCount,
    required this.ticketPrice,
    required this.total,
  });

  final int adultCount;
  final int childCount;
  final int ticketPrice;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Rincian pembayaran',
      subtitle: 'Total biaya akan diperbarui sesuai jumlah tiket.',
      child: Column(
        children: [
          _PriceRow(
            label: 'Tiket dewasa  ×  $adultCount',
            value: _rupiah(adultCount * ticketPrice),
          ),
          if (childCount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Tiket anak  ×  $childCount',
              value: _rupiah(childCount * ticketPrice),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 9),
            child: Divider(height: 1),
          ),
          _PriceRow(
            label: 'Total pembayaran',
            value: _rupiah(total),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: emphasize ? AppColors.blueDeep : AppColors.muted,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _BookingFooter extends StatelessWidget {
  const _BookingFooter({
    required this.quantity,
    required this.total,
    required this.isSubmitting,
    required this.onContinue,
  });

  final int quantity;
  final int total;
  final bool isSubmitting;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total pembayaran  •  $quantity tiket',
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  _rupiah(total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.blueDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: isSubmitting ? null : onContinue,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward, size: 17),
            label: Text(isSubmitting ? 'Memproses' : 'Lanjut bayar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blueDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
