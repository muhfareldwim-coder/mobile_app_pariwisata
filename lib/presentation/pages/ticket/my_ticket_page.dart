import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/ticket_service.dart';
import '../../widgets/ticket_card.dart';
import 'ticket_detail_page.dart';

class MyTicketPage extends StatelessWidget {
  const MyTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = TicketService.tickets;

    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Saya')),
      body: tickets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.sky.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 42,
                        color: AppColors.blueDeep,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada tiket',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiket yang berhasil dipesan akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Perjalanan Anda',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tickets.length} tiket',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 16),
                for (final ticket in tickets) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailPage(ticket: ticket),
                        ),
                      ),
                      child: TicketCard(ticket: ticket),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
