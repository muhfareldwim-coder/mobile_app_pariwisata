import 'package:flutter/material.dart';

import '../../../data/services/ticket_service.dart';
import '../../widgets/ticket_card.dart';
import 'ticket_detail_page.dart';

class MyTicketPage extends StatelessWidget {
  const MyTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Saya')),
      body: TicketService.tickets.isEmpty ? const Center(child: Text('Belum ada tiket')) : ListView(padding: const EdgeInsets.all(16), children: [
        for (final ticket in TicketService.tickets) InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket))), child: TicketCard(ticket: ticket)),
      ]),
    );
  }
}