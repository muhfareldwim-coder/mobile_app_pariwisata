import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/payment_service.dart';
import 'payment_page.dart';

const _confirmationNavy = AppColors.navy;
const _confirmationOrange = AppColors.orange;
const _confirmationBackground = Color(0xFFF6F8FB);

class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({
    super.key,
    required this.destination,
    required this.visitDate,
    required this.leaderName,
    required this.leaderEmail,
    required this.leaderPhone,
    required this.participants,
    required this.onConfirmBooking,
    this.paymentService,
  });

  final Destination destination;
  final DateTime visitDate;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final List<BookingParticipant> participants;
  final Future<Booking> Function() onConfirmBooking;
  final PaymentService? paymentService;

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  bool _isSubmitting = false;

  int get _totalAmount => widget.participants.fold<int>(
    0,
    (total, participant) => total + participant.ticketPrice,
  );

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final booking = await widget.onConfirmBooking();
      if (!mounted) return;
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PaymentPage(
            booking: booking,
            destination: widget.destination,
            paymentService: widget.paymentService,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _confirmationBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ConfirmationHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  const _ConfirmationProgress(),
                  const SizedBox(height: 18),
                  const Text(
                    'Konfirmasi Pesanan',
                    style: TextStyle(
                      color: _confirmationNavy,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Periksa kembali pesananmu sebelum melakukan pembayaran.',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConfirmationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ConfirmationInfoRow(
                          icon: Icons.place_outlined,
                          label: 'Destinasi',
                          value: widget.destination.name,
                        ),
                        const SizedBox(height: 14),
                        _ConfirmationInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Tanggal kunjungan',
                          value: formatIndonesianDate(widget.visitDate),
                        ),
                        const SizedBox(height: 14),
                        _ConfirmationInfoRow(
                          icon: Icons.person_outline,
                          label: 'Ketua kelompok',
                          value: widget.leaderName,
                        ),
                        const SizedBox(height: 14),
                        _ConfirmationInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email ketua',
                          value: widget.leaderEmail,
                        ),
                        const SizedBox(height: 14),
                        _ConfirmationInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Nomor telepon',
                          value: widget.leaderPhone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ConfirmationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rincian peserta',
                          style: TextStyle(
                            color: _confirmationNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (
                          var index = 0;
                          index < widget.participants.length;
                          index++
                        ) ...[
                          _ParticipantSummary(
                            participant: widget.participants[index],
                            isLeader: index == 0,
                          ),
                          if (index < widget.participants.length - 1)
                            const Divider(
                              height: 20,
                              color: Color(0xFFE8EDF3),
                            ),
                        ],
                        const Divider(
                          height: 24,
                          color: Color(0xFFE8EDF3),
                        ),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total peserta',
                                style: TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '${widget.participants.length} orang',
                              style: const TextStyle(
                                color: _confirmationNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total pesanan',
                                style: TextStyle(
                                  color: _confirmationNavy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              _formatPrice(_totalAmount),
                              style: const TextStyle(
                                color: _confirmationOrange,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _ConfirmationNote(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ConfirmationActionBar(
        total: _totalAmount,
        isSubmitting: _isSubmitting,
        onConfirm: _confirmBooking,
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  const _ConfirmationHeader({required this.onBack});

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
              tooltip: localized('Kembali'),
              icon: const Icon(Icons.arrow_back, color: _confirmationNavy),
            ),
            const Expanded(
              child: Text(
                'Konfirmasi Pesanan',
                style: TextStyle(
                  color: _confirmationNavy,
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

class _ConfirmationProgress extends StatelessWidget {
  const _ConfirmationProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _ConfirmationStep(
              number: '1',
              label: 'Data Peserta',
              complete: true,
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFD8E1EA))),
          Expanded(
            child: _ConfirmationStep(
              number: '2',
              label: 'Konfirmasi',
              active: true,
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFD8E1EA))),
          Expanded(child: _ConfirmationStep(number: '3', label: 'Pembayaran')),
          Expanded(child: Divider(color: Color(0xFFD8E1EA))),
          Expanded(child: _ConfirmationStep(number: '4', label: 'E-Tiket')),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({
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
    final color = active || complete
        ? _confirmationNavy
        : const Color(0xFFDCE5ED);
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: complete
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : Text(
                  number,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF68778A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? _confirmationNavy : const Color(0xFF8190A5),
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: child,
    );
  }
}

class _ConfirmationInfoRow extends StatelessWidget {
  const _ConfirmationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _confirmationNavy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8190A5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _confirmationNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantSummary extends StatelessWidget {
  const _ParticipantSummary({
    required this.participant,
    required this.isLeader,
  });

  final BookingParticipant participant;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLeader
                    ? '${participant.name} (${localized('Ketua')})'
                    : participant.name,
                style: const TextStyle(
                  color: _confirmationNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                participant.ticketTypeName,
                style: const TextStyle(
                  color: Color(0xFF8190A5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _formatPrice(participant.ticketPrice),
          style: const TextStyle(
            color: _confirmationNavy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationNote extends StatelessWidget {
  const _ConfirmationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: _confirmationNavy,
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'E-ticket diterbitkan setelah pembayaran berhasil dikonfirmasi.',
              style: TextStyle(
                color: _confirmationNavy,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationActionBar extends StatelessWidget {
  const _ConfirmationActionBar({
    required this.total,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final int total;
  final bool isSubmitting;
  final VoidCallback onConfirm;

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
                    'Total pesanan',
                    style: TextStyle(color: Color(0xFF8190A5), fontSize: 12),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _formatPrice(total),
                    style: const TextStyle(
                      color: _confirmationNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: isSubmitting ? null : onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _confirmationOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSubmitting) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
