import 'booking.dart';
import 'destination.dart';

class TripManagement {
  const TripManagement({
    required this.booking,
    required this.destination,
    required this.ticketTypes,
    required this.remainingSlots,
    this.pendingChange,
  });

  final Booking booking;
  final Destination destination;
  final List<DestinationTicketType> ticketTypes;
  final int remainingSlots;
  final PendingTripChange? pendingChange;
}

class PendingTripChange {
  const PendingTripChange({
    required this.id,
    required this.amount,
    required this.status,
  });

  final String id;
  final int amount;
  final String status;
}

class TripMemberDraft {
  const TripMemberDraft({required this.name, required this.ticketTypeId});

  final String name;
  final int ticketTypeId;
}
