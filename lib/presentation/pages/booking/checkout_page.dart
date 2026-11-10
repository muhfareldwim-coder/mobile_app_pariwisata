import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../../core/utils/date_formatters.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/booking_service.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.booking,
    required this.destination,
    required this.canCancelBooking,
    this.bookingService,
  });

  final Booking booking;
  final Destination destination;
  final bool canCancelBooking;
  final BookingService? bookingService;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isCancelling = false;

  BookingService get _bookingService =>
      widget.bookingService ?? BookingService();

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text(
          'Pesanan ini akan dibatalkan dan tidak dapat dilanjutkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak, kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, batalkan pesanan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await _bookingService.cancelBooking(widget.booking.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi dan pembayaran')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      title: Text(widget.destination.name),
                      subtitle: Text(
                        '${widget.booking.quantity} tiket\nTanggal: '
                        '${formatIndonesianDate(widget.booking.visitDate)}',
                      ),
                      trailing: Text('Rp ${widget.booking.totalAmount}'),
                    ),
                    ListTile(
                      title: const Text('Kode pemesanan'),
                      subtitle: Text(widget.booking.code),
                    ),
                    const Divider(),
                    for (final participant in widget.booking.participants)
                      ListTile(
                        title: Text(participant.name),
                        subtitle: Text(
                          participant.ticketTypeId == 0
                              ? 'Peserta'
                              : participant.ticketTypeName,
                        ),
                        trailing: participant.ticketTypeId == 0
                            ? null
                            : Text('Rp ${participant.ticketPrice}'),
                      ),
                    const Divider(),
                    ListTile(
                      title: const Text('Ketua pemesanan'),
                      subtitle: Text(
                        '${widget.booking.leaderName}\n'
                        '${widget.booking.leaderEmail}\n'
                        '${widget.booking.leaderPhone}',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PaymentPage(
                        booking: widget.booking,
                        destination: widget.destination,
                      ),
                    ),
                  ),
                  child: const Text('Pilih Pembayaran'),
                ),
              ),
              if (widget.canCancelBooking) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  child: _isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Batalkan pesanan'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
