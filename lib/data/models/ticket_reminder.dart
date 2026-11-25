import 'ticket.dart';

enum TicketReminderTiming { visitToday, visitTomorrow, expiredToday }

class TicketReminder {
  const TicketReminder({required this.ticket, required this.timing});

  final Ticket ticket;
  final TicketReminderTiming timing;

  String get id =>
      '${ticket.bookingId}_${ticket.visitDate.year}-${ticket.visitDate.month}-${ticket.visitDate.day}_${timing.name}';

  static List<TicketReminder> fromTickets(
    Iterable<Ticket> tickets, {
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();
    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final reminders = <TicketReminder>[];

    for (final ticket in tickets) {
      if (!ticket.hasIssuedTicket) {
        continue;
      }

      final visitDate = DateTime(
        ticket.visitDate.year,
        ticket.visitDate.month,
        ticket.visitDate.day,
      );
      if (visitDate == today) {
        final isExpired =
            ticket.hasExpiredTicket || ticket.status.toLowerCase() == 'expired';
        if (isExpired) {
          reminders.add(
            TicketReminder(
              ticket: ticket,
              timing: TicketReminderTiming.expiredToday,
            ),
          );
        } else if (ticket.hasActiveTicket ||
            ticket.status.toLowerCase() == 'valid') {
          reminders.add(
            TicketReminder(
              ticket: ticket,
              timing: TicketReminderTiming.visitToday,
            ),
          );
        }
      } else if (visitDate == tomorrow &&
          (ticket.hasActiveTicket || ticket.status.toLowerCase() == 'valid')) {
        reminders.add(
          TicketReminder(
            ticket: ticket,
            timing: TicketReminderTiming.visitTomorrow,
          ),
        );
      }
    }

    return reminders;
  }
}
