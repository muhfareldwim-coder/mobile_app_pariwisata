import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/payment.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/ticket_service.dart';
import '../main_navigation_page.dart';

const _paymentNavy = Color(0xFF0B294A);
const _paymentBlue = Color(0xFF0874E8);
const _paymentOrange = Color(0xFFE98600);
const _paymentBackground = Color(0xFFF9F8FF);

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.booking,
    required this.destination,
  });

  final Booking booking;
  final Destination destination;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _paymentDuration = Duration(minutes: 15);
  Timer? _countdownTimer;
  Duration _remaining = _paymentDuration;
  bool _isProcessing = false;

  int get _childPrice =>
      ((widget.destination.ticketPrice * .6) / 1000).round() * 1000;
  int get _total =>
      (widget.booking.adultCount * widget.destination.ticketPrice) +
      (widget.booking.childCount * _childPrice);
  String get _qrPayload =>
      'JEMBERGO|QRIS|${widget.booking.id}|$_total|${widget.booking.destinationId}';

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmDemoPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text(
          'Ini simulasi UI. Belum ada transaksi QRIS sungguhan yang dikirim '
          'ke bank atau payment gateway.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan Simulasi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isProcessing) return;

    setState(() => _isProcessing = true);
    _countdownTimer?.cancel();
    final payment = await PaymentService().createPayment(
      Payment(
        id: 'PAY-${widget.booking.id}',
        bookingId: widget.booking.id,
        amount: _total,
        status: 'paid',
        method: 'QRIS',
      ),
    );
    await TicketService().issueTicket(
      bookingId: widget.booking.id,
      destinationName: widget.destination.name,
      destinationImageUrl: widget.destination.imageUrl,
      visitDate: widget.booking.visitDate,
      adultCount: widget.booking.adultCount,
      childCount: widget.booking.childCount,
      leaderName: widget.booking.leaderName,
      leaderEmail: widget.booking.leaderEmail,
      leaderPhone: widget.booking.leaderPhone,
      memberNames: widget.booking.memberNames,
      amountPaid: payment.amount,
      paymentMethod: payment.method,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MainNavigationPage(initialIndex: 3),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paymentBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PaymentHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                children: [
                  const _PaymentProgress(),
                  const SizedBox(height: 18),
                  _AmountCard(
                    destination: widget.destination,
                    booking: widget.booking,
                    total: _total,
                    formattedTime: _formatDuration(_remaining),
                  ),
                  const SizedBox(height: 16),
                  _QrPaymentCard(
                    payload: _qrPayload,
                    bookingId: widget.booking.id,
                    total: _total,
                  ),
                  const SizedBox(height: 13),
                  const _PaymentInstructions(),
                  const SizedBox(height: 13),
                  const _DemoNotice(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ConfirmPaymentBar(
        total: _total,
        isProcessing: _isProcessing,
        onConfirm: _confirmDemoPayment,
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.onBack});

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
              icon: const Icon(Icons.arrow_back, color: _paymentNavy),
            ),
            const Expanded(
              child: Text(
                'Pembayaran',
                style: TextStyle(
                  color: _paymentNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const _QrisBrandMark(),
          ],
        ),
      ),
    );
  }
}

class _PaymentProgress extends StatelessWidget {
  const _PaymentProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: _PaymentStep(
              number: '1',
              label: 'Data Rombongan',
              complete: true,
            ),
          ),
          Expanded(flex: 1, child: Divider(color: Color(0xFFD4DAF2))),
          Expanded(
            flex: 2,
            child: _PaymentStep(number: '2', label: 'Pembayaran', active: true),
          ),
          Expanded(flex: 1, child: Divider(color: Color(0xFFD4DAF2))),
          Expanded(
            flex: 2,
            child: _PaymentStep(number: '3', label: 'E-Tiket'),
          ),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.number,
    required this.label,
    this.active = false,
    this.complete = false,
  });

  final String number;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final background = active || complete
        ? _paymentNavy
        : const Color(0xFFDCE2F5);
    return Row(
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: complete
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : Text(
                  number,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF56637B),
                    fontSize: 9,
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
              color: active ? _paymentNavy : const Color(0xFF7D8493),
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.destination,
    required this.booking,
    required this.total,
    required this.formattedTime,
  });

  final Destination destination;
  final Booking booking;
  final int total;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
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
              const Expanded(
                child: Text(
                  'Total Pembayaran',
                  style: TextStyle(color: Color(0xFF667080), fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: _paymentOrange,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Color(0xFF8A4D00),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _formatPrice(total),
            style: const TextStyle(
              color: _paymentNavy,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8EAF3)),
          const SizedBox(height: 10),
          _InfoLine(label: 'Destinasi', value: destination.name),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Jumlah tiket',
            value:
                '${booking.quantity} tiket (${booking.adultCount} dewasa, ${booking.childCount} anak)',
          ),
          const SizedBox(height: 6),
          _InfoLine(label: 'Kode booking', value: booking.id),
        ],
      ),
    );
  }
}

class _QrPaymentCard extends StatelessWidget {
  const _QrPaymentCard({
    required this.payload,
    required this.bookingId,
    required this.total,
  });

  final String payload;
  final String bookingId;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: _paymentBlue,
                size: 20,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Bayar dengan QRIS',
                  style: TextStyle(
                    color: _paymentNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const _QrisBrandMark(),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: _paymentNavy,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: _paymentNavy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatPrice(total),
            style: const TextStyle(
              color: _paymentBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Booking $bookingId',
            style: const TextStyle(color: Color(0xFF7B8290), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PaymentInstructions extends StatelessWidget {
  const _PaymentInstructions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara pembayaran',
            style: TextStyle(
              color: _paymentNavy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          _InstructionRow(
            number: '1',
            text: 'Buka aplikasi bank atau e-wallet.',
          ),
          _InstructionRow(
            number: '2',
            text: 'Pilih menu Scan QRIS, lalu pindai kode di atas.',
          ),
          _InstructionRow(
            number: '3',
            text: 'Pastikan nominal sesuai sebelum membayar.',
          ),
        ],
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(
              color: _paymentBlue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF596579), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: _paymentBlue, size: 16),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'QRIS ini masih simulasi UI. Pembayaran asli aktif setelah terhubung ke payment gateway.',
            style: TextStyle(
              color: Color(0xFF727B8B),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmPaymentBar extends StatelessWidget {
  const _ConfirmPaymentBar({
    required this.total,
    required this.isProcessing,
    required this.onConfirm,
  });

  final int total;
  final bool isProcessing;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
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
                  Text(
                    _formatPrice(total),
                    style: const TextStyle(
                      color: _paymentNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 47,
              child: FilledButton(
                onPressed: isProcessing ? null : onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _paymentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Saya Sudah Bayar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrisBrandMark extends StatelessWidget {
  const _QrisBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'QR',
              style: TextStyle(color: _paymentNavy),
            ),
            TextSpan(
              text: 'IS',
              style: TextStyle(color: _paymentOrange),
            ),
          ],
        ),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF777F8E), fontSize: 10),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: Color(0xFF777F8E), fontSize: 10),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _paymentNavy,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
