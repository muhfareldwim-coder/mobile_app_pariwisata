import 'package:flutter/material.dart';

import '../../data/models/ticket.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.confirmation_number_outlined),
        title: Text(ticket.destinationName),
        subtitle: Text('Tiket ${ticket.id}\n${ticket.leaderName} - ${ticket.visitDate.day}/${ticket.visitDate.month}/${ticket.visitDate.year}'),
        trailing: Text(ticket.status),
      ),
    );
  }
}