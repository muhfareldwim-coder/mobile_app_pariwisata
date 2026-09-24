import 'package:flutter/material.dart';

import '../../../data/models/ticket.dart';
import 'qr_ticket_page.dart';

class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tiket')),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ticket.destinationName, style: Theme.of(context).textTheme.headlineSmall),
        Text('Kode tiket: ${ticket.id}'),
        Text('Tanggal pemesanan: ${ticket.visitDate.day}/${ticket.visitDate.month}/${ticket.visitDate.year}'),
        const SizedBox(height: 16),
        Text('Biodata ketua kelompok', style: Theme.of(context).textTheme.titleMedium),
        Text(ticket.leaderName),
        Text(ticket.leaderEmail),
        Text(ticket.leaderPhone),
        const SizedBox(height: 12),
        Text('Peserta: ${ticket.adultCount} dewasa, ${ticket.childCount} anak'),
        if (ticket.memberNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Nama anggota', style: Theme.of(context).textTheme.titleMedium),
          for (final name in ticket.memberNames) Text(name),
        ],
        const Spacer(),
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrTicketPage(ticket: ticket))), child: const Text('Tampilkan QR')),
      ])),
    );
  }
}