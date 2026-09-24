import 'package:flutter/material.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/payment.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../widgets/custom_button.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required this.booking, required this.destination});

  final Booking booking;
  final Destination destination;

  Future<void> _pay(BuildContext context) async {
    await PaymentService().createPayment(Payment(id: 'PAY-${booking.id}', bookingId: booking.id, amount: destination.ticketPrice * booking.quantity, status: 'paid'));
    await TicketService().issueTicket(bookingId: booking.id, destinationName: destination.name, visitDate: booking.visitDate, adultCount: booking.adultCount, childCount: booking.childCount, leaderName: booking.leaderName, leaderEmail: booking.leaderEmail, leaderPhone: booking.leaderPhone, memberNames: booking.memberNames);
    if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          DropdownButtonFormField<String>(
            initialValue: 'qris',
            decoration: const InputDecoration(labelText: 'Metode pembayaran'),
            items: const [
              DropdownMenuItem(value: 'qris', child: Text('QRIS')),
              DropdownMenuItem(value: 'bank', child: Text('Transfer Bank')),
            ],
            onChanged: (_) {},
          ),
          const Spacer(),
          CustomButton(label: 'Bayar Sekarang', onPressed: () => _pay(context)),
        ]),
      ),
    );
  }
}