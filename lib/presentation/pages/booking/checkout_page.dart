import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../widgets/custom_button.dart';
import 'payment_page.dart';

String _rupiah(int amount) => 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    )}';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, required this.booking, required this.destination});

  final Booking booking;
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final total = destination.ticketPrice * booking.quantity;
    final date =
        '${booking.visitDate.day.toString().padLeft(2, '0')}/'
        '${booking.visitDate.month.toString().padLeft(2, '0')}/'
        '${booking.visitDate.year}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Ringkasan pesanan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _CheckoutCard(
                      title: 'Detail kunjungan',
                      icon: Icons.place_outlined,
                      children: [
                        _CheckoutRow(label: 'Destinasi', value: destination.name),
                        _CheckoutRow(label: 'Tanggal', value: date),
                        _CheckoutRow(
                          label: 'Jumlah tiket',
                          value:
                              '${booking.adultCount} dewasa, ${booking.childCount} anak',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CheckoutCard(
                      title: 'Data pemesan',
                      icon: Icons.person_outline,
                      children: [
                        _CheckoutRow(
                          label: 'Nama',
                          value: booking.leaderName,
                        ),
                        _CheckoutRow(
                          label: 'Email',
                          value: booking.leaderEmail,
                        ),
                        _CheckoutRow(
                          label: 'WhatsApp',
                          value: booking.leaderPhone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CheckoutCard(
                      title: 'Rincian pembayaran',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        _CheckoutRow(
                          label: 'Harga tiket × ${booking.quantity}',
                          value: _rupiah(total),
                        ),
                        const Divider(height: 24),
                        _CheckoutRow(
                          label: 'Total pembayaran',
                          value: _rupiah(total),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: CustomButton(
                    label: 'Pilih Pembayaran',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PaymentPage(
                          booking: booking,
                          destination: destination,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blueDeep, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized ? AppColors.ink : AppColors.muted,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
