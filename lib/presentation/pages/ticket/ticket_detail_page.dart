import 'package:flutter/material.dart';

import '../../../data/models/ticket.dart';
import 'qr_ticket_page.dart';

class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) => QrTicketPage(ticket: ticket);
}
