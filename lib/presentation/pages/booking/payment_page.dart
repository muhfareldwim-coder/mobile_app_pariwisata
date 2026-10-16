import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/payment.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/payment_service.dart';
import '../../../core/utils/date_formatters.dart';
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
    this.paymentService,
    this.additionalChangeId,
    this.paymentAmount,
  });

  final Booking booking;
  final Destination destination;
  final PaymentService? paymentService;
  final String? additionalChangeId;
  final int? paymentAmount;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Payment? _payment;
  String? _error;
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _isOpeningCheckout = false;
  bool _didComplete = false;

  PaymentService get _paymentService =>
      widget.paymentService ?? PaymentService();

  String get _remainingText {
    final deadline = _payment?.expiresAt ?? widget.booking.paymentDeadline;
    if (deadline == null) return '--:--';
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    return _formatDuration(remaining);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_createPayment());
    if (widget.booking.paymentDeadline != null ||
        widget.additionalChangeId != null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshPaymentStatus(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPaymentStatus());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPayment() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final payment = widget.additionalChangeId == null
          ? await _paymentService.createPayment(widget.booking.id)
          : await _paymentService.createAdditionalPayment(
              widget.booking.id,
              widget.additionalChangeId!,
            );
      if (!mounted) return;
      setState(() => _payment = payment);
      if (payment.isPaid) {
        await _completePayment();
      } else if (payment.status.toUpperCase() == 'EXPIRED') {
        setState(
          () => _error = 'Batas waktu pembayaran berakhir. Buat pemesanan baru untuk melanjutkan.',
        );
      } else if (!payment.isPending) {
        setState(() => _error = 'Status pembayaran: ${payment.status}.');
      } else if (payment.checkoutUrl == null && payment.qrCodeUrl == null) {
        setState(
          () => _error = 'Kode pembayaran belum tersedia. Hubungi pengelola atau coba lagi.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPaymentStatus() async {
    if (!mounted ||
        _isLoading ||
        _isCheckingStatus ||
        _payment?.isPending != true) {
      return;
    }
    _isCheckingStatus = true;
    try {
      final payment = widget.additionalChangeId == null
          ? await _paymentService.getPaymentStatus(widget.booking.id)
          : await _paymentService.getAdditionalPaymentStatus(
              widget.booking.id,
              widget.additionalChangeId!,
            );
      if (!mounted) return;
      setState(() {
        _payment = payment;
        _error = null;
      });
      if (payment.isPaid) {
        await _completePayment();
      } else if (payment.status.toUpperCase() == 'EXPIRED') {
        setState(
          () => _error = 'Batas waktu pembayaran berakhir. Buat pemesanan baru untuk melanjutkan.',
        );
      } else if (!payment.isPending) {
        setState(() => _error = 'Status pembayaran: ${payment.status}.');
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      _isCheckingStatus = false;
    }
  }

  Future<void> _openCheckout() async {
    final checkoutUrl = _payment?.checkoutUrl;
    if (checkoutUrl == null) {
      setState(() => _error = 'Tautan pembayaran belum tersedia. Coba lagi.');
      return;
    }

    setState(() {
      _isOpeningCheckout = true;
      _error = null;
    });
    try {
      final opened = await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _error = 'Halaman pembayaran tidak dapat dibuka.');
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _isOpeningCheckout = false);
    }
  }

  Future<void> _completePayment() async {
    if (!mounted || _didComplete) return;
    _didComplete = true;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
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
                  const Text(
                    'Ringkasan pesanan',
                    style: TextStyle(
                      color: _paymentNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AmountCard(
                    destination: widget.destination,
                    booking: widget.booking,
                    total: widget.paymentAmount ?? widget.booking.totalAmount,
                    isAdditional: widget.additionalChangeId != null,
                    formattedTime: _remainingText,
                  ),
                  const SizedBox(height: 16),
                  _SecurePaymentCard(
                    bookingCode: widget.booking.code,
                    orderId: _payment?.orderId,
                    status: _payment?.status ?? 'MENYIAPKAN',
                  ),
                  if (_payment?.qrCodeUrl != null) ...[
                    const SizedBox(height: 13),
                    _PaymentQrCodeCard(
                      url: _payment!.qrCodeUrl!,
                      headers: _paymentService.qrCodeImageHeaders,
                      qrCodeSourceUrl: _payment!.qrCodeSourceUrl,
                    ),
                  ],
                  const SizedBox(height: 13),
                  _PaymentInstructions(hasQrCode: _payment?.qrCodeUrl != null),
                  const SizedBox(height: 13),
                  const _PaymentStatusNotice(),
                  if (_error != null) const SizedBox(height: 12),
                  if (_error != null) _PaymentError(message: _error!),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ConfirmPaymentBar(
        total: widget.paymentAmount ?? widget.booking.totalAmount,
        isProcessing: _isLoading || _isOpeningCheckout,
        isQrPayment: _payment?.qrCodeUrl != null && _payment!.isPending,
        isRetry:
            _payment == null || (!_payment!.isPending && !_payment!.isPaid),
        isExpired: _payment?.status.toUpperCase() == 'EXPIRED',
        isEnabled:
            !_isLoading &&
            _payment?.status.toUpperCase() != 'EXPIRED' &&
            (_payment == null ||
                _payment?.qrCodeUrl != null ||
                _payment?.checkoutUrl != null ||
                _payment?.isPending == false),
        onPressed:
            _payment == null || (!_payment!.isPending && !_payment!.isPaid)
            ? _createPayment
            : _payment?.qrCodeUrl != null
            ? _refreshPaymentStatus
            : _openCheckout,
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
    required this.isAdditional,
    required this.formattedTime,
  });

  final Destination destination;
  final Booking booking;
  final int total;
  final bool isAdditional;
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
              Expanded(
                child: Text(
                  isAdditional ? 'Biaya Tambahan' : 'Total Pembayaran',
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
            label: 'Tanggal kunjungan',
            value: formatIndonesianDate(booking.visitDate),
          ),
          const SizedBox(height: 6),
          _InfoLine(label: 'Total peserta', value: '${booking.quantity} orang'),
          const SizedBox(height: 6),
          _InfoLine(
            label: isAdditional ? 'Tagihan tambahan' : 'Total pesanan',
            value: _formatPrice(total),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8EAF3)),
          const SizedBox(height: 10),
          const Text(
            'Rincian peserta',
            style: TextStyle(
              color: _paymentNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < booking.participants.length; index++) ...[
            _InfoLine(
              label: index == 0
                  ? '${booking.participants[index].name} (Ketua)'
                  : booking.participants[index].name,
              value: booking.participants[index].ticketTypeName,
            ),
            if (index < booking.participants.length - 1)
              const SizedBox(height: 5),
          ],
          const SizedBox(height: 6),
          _InfoLine(label: 'Kode booking', value: booking.code),
        ],
      ),
    );
  }
}

class _SecurePaymentCard extends StatelessWidget {
  const _SecurePaymentCard({
    required this.bookingCode,
    required this.orderId,
    required this.status,
  });

  final String bookingCode;
  final String? orderId;
  final String status;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: _paymentBlue,
                size: 20,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Pembayaran diproses dengan aman',
                  style: TextStyle(
                    color: _paymentNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(label: 'Status', value: status),
          if (orderId != null) ...[
            const SizedBox(height: 7),
            _InfoLine(label: 'Kode transaksi', value: orderId!),
          ],
          const SizedBox(height: 7),
          _InfoLine(label: 'Kode booking', value: bookingCode),
          const SizedBox(height: 13),
          const Text(
            'Data pesananmu tercatat dan e-ticket akan diterbitkan setelah pembayaran berhasil dikonfirmasi.',
            style: TextStyle(
              color: Color(0xFF596579),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentQrCodeCard extends StatelessWidget {
  const _PaymentQrCodeCard({
    required this.url,
    required this.headers,
    required this.qrCodeSourceUrl,
  });

  final Uri url;
  final Map<String, String> headers;
  final Uri? qrCodeSourceUrl;

  @override
  Widget build(BuildContext context) {
    final sourceUrl = qrCodeSourceUrl;

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
        children: [
          const Text(
            'Selesaikan pembayaran',
            style: TextStyle(
              color: _paymentNavy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/logo-qris-transparent.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 240,
            height: 240,
            child: Image.network(
              url.toString(),
              headers: headers,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text(
                  'Kode pembayaran tidak dapat dimuat. Periksa koneksi lalu coba lagi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF596579), fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Buka aplikasi pembayaran yang mendukung, lalu pindai kode di atas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF596579),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          if (sourceUrl != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(
                    ClipboardData(text: sourceUrl.toString()),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan Midtrans berhasil disalin.'),
                    ),
                  );
                } on PlatformException {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan Midtrans gagal disalin.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Salin tautan Midtrans'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentInstructions extends StatelessWidget {
  const _PaymentInstructions({required this.hasQrCode});

  final bool hasQrCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
          if (hasQrCode) ...[
            _InstructionRow(
              number: '1',
              text: 'Pindai kode pembayaran yang tampil di atas.',
            ),
            _InstructionRow(
              number: '2',
              text: 'Selesaikan pembayaran dari aplikasi pembayaranmu.',
            ),
            _InstructionRow(
              number: '3',
              text: 'Status pesanan akan diperbarui otomatis.',
            ),
          ] else ...[
            _InstructionRow(
              number: '1',
              text: 'Tekan Bayar Sekarang untuk membuka halaman pembayaran.',
            ),
            _InstructionRow(
              number: '2',
              text: 'Pilih metode pembayaran yang tersedia.',
            ),
            _InstructionRow(
              number: '3',
              text: 'Selesaikan pembayaran lalu kembali ke aplikasi untuk memeriksa status.',
            ),
          ],
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

class _PaymentStatusNotice extends StatelessWidget {
  const _PaymentStatusNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: _paymentBlue, size: 16),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Pembayaran diproses dengan aman. Status transaksi diperiksa kembali ke server dan e-ticket diterbitkan setelah pembayaran dikonfirmasi.',
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

class _PaymentError extends StatelessWidget {
  const _PaymentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8B2822),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPaymentBar extends StatelessWidget {
  const _ConfirmPaymentBar({
    required this.total,
    required this.isProcessing,
    required this.isEnabled,
    required this.isQrPayment,
    required this.isRetry,
    required this.isExpired,
    required this.onPressed,
  });

  final int total;
  final bool isProcessing;
  final bool isEnabled;
  final bool isQrPayment;
  final bool isRetry;
  final bool isExpired;
  final VoidCallback onPressed;

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
                onPressed: isProcessing || !isEnabled ? null : onPressed,
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
                    : Text(
                        isExpired
                            ? 'Kedaluwarsa'
                            : isRetry
                            ? 'Coba Lagi'
                            : isQrPayment
                            ? 'Cek Status'
                            : 'Bayar Sekarang',
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
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
