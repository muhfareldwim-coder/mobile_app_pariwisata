import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/payment.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/ticket_service.dart';
import '../ticket/ticket_ui_page.dart';
import '../../widgets/custom_button.dart';

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
  String _method = 'qris';
  bool _isPaying = false;

  Future<void> _pay() async {
    if (_isPaying) return;
    setState(() => _isPaying = true);

    try {
      await PaymentService().createPayment(
        Payment(
          id: 'PAY-${widget.booking.id}',
          bookingId: widget.booking.id,
          amount: widget.destination.ticketPrice * widget.booking.quantity,
          method: _method,
          status: 'paid',
        ),
      );
      await TicketService().issueTicket(
        bookingId: widget.booking.id,
        destinationName: widget.destination.name,
        visitDate: widget.booking.visitDate,
        adultCount: widget.booking.adultCount,
        childCount: widget.booking.childCount,
        leaderName: widget.booking.leaderName,
        leaderEmail: widget.booking.leaderEmail,
        leaderPhone: widget.booking.leaderPhone,
        memberNames: widget.booking.memberNames,
        location: widget.destination.location,
        imageUrl: widget.destination.imageUrl,
        unitPrice: widget.destination.ticketPrice,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const TicketUIPage()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.destination.ticketPrice * widget.booking.quantity;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total pembayaran',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rp ${total.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}',
                            style: const TextStyle(
                              color: AppColors.blueDeep,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih metode pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _method,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                          DropdownMenuItem(
                            value: 'bank',
                            child: Text('Transfer Bank'),
                          ),
                        ],
                        onChanged: _isPaying
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _method = value);
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _method == 'qris'
                          ? 'Pembayaran QRIS akan diproses secara simulasi.'
                          : 'Transfer bank akan diproses secara simulasi.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: CustomButton(
                    label: _isPaying ? 'Memproses...' : 'Bayar Sekarang',
                    onPressed: _isPaying ? null : _pay,
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
