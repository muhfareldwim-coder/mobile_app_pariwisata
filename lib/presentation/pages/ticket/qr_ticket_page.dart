import 'package:flutter/material.dart';

import '../../../data/models/ticket.dart';

class QrTicketPage extends StatelessWidget {
  const QrTicketPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('QR Tiket')), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.qr_code_2, size: 220), Text(ticket.id)])));
  }
}