import 'package:flutter/material.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../widgets/custom_button.dart';
import 'payment_page.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, required this.booking, required this.destination});

  final Booking booking;
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          ListTile(title: Text(destination.name), subtitle: Text('${booking.adultCount} dewasa, ${booking.childCount} anak\nTanggal: ${booking.visitDate.day}/${booking.visitDate.month}/${booking.visitDate.year}'), trailing: Text('Rp ${destination.ticketPrice * booking.quantity}')),
          ListTile(title: Text(booking.leaderName), subtitle: Text('${booking.leaderEmail}\n${booking.leaderPhone}')),
          const Spacer(),
          CustomButton(label: 'Pilih Pembayaran', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(booking: booking, destination: destination)))),
        ]),
      ),
    );
  }
}