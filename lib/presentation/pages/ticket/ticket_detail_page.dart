import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ticket.dart';
import 'qr_ticket_page.dart';

class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tiket')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blueDeep, Color(0xFF1C819F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white70,
                  size: 30,
                ),
                const SizedBox(height: 18),
                Text(
                  ticket.destinationName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kode tiket  ${ticket.id}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const Divider(height: 28, color: Colors.white30),
                _TicketInfoRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Tanggal kunjungan',
                  value:
                      '${ticket.visitDate.day}/${ticket.visitDate.month}/${ticket.visitDate.year}',
                  light: true,
                ),
                const SizedBox(height: 12),
                _TicketInfoRow(
                  icon: Icons.people_outline,
                  label: 'Jumlah peserta',
                  value:
                      '${ticket.adultCount} dewasa, ${ticket.childCount} anak',
                  light: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Data pemesan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _TicketInfoRow(
            icon: Icons.person_outline,
            label: 'Nama ketua rombongan',
            value: ticket.leaderName,
          ),
          const SizedBox(height: 14),
          _TicketInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: ticket.leaderEmail,
          ),
          const SizedBox(height: 14),
          _TicketInfoRow(
            icon: Icons.phone_outlined,
            label: 'Nomor HP',
            value: ticket.leaderPhone,
          ),
          if (ticket.memberNames.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Peserta lainnya',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final name in ticket.memberNames)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(name),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrTicketPage(ticket: ticket)),
            ),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Tampilkan QR Tiket'),
          ),
        ],
      ),
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.white : AppColors.ink;
    final secondary = light ? Colors.white70 : AppColors.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: light ? Colors.white70 : AppColors.blueDeep),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
