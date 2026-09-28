import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ticket.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final isValid = ticket.status == 'valid';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.sky.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.blueDeep,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${ticket.visitDate.day}/${ticket.visitDate.month}/${ticket.visitDate.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isValid
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isValid ? 'Aktif' : ticket.status,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isValid
                                ? AppColors.success
                                : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
