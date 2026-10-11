import 'package:flutter/foundation.dart';

import '../models/destination_review.dart';
import 'ticket_service.dart';

class DestinationReviewService {
  static final List<DestinationReview> reviews = [];
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static List<DestinationReview> forDestination(String destinationId) =>
      reviews
          .where((review) => review.destinationId == destinationId)
          .toList()
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

  static DestinationReview? byUserForDestination(
    String destinationId,
    String userEmail,
  ) {
    for (final review in reviews) {
      if (review.destinationId == destinationId &&
          review.userEmail.trim().toLowerCase() ==
              userEmail.trim().toLowerCase()) {
        return review;
      }
    }
    return null;
  }

  static bool canReview({
    required String destinationId,
    required String userEmail,
  }) {
    final alreadyReviewed = byUserForDestination(
      destinationId,
      userEmail,
    );
    if (alreadyReviewed != null) return false;

    return TicketService.tickets.any(
      (ticket) =>
          ticket.destinationId == destinationId &&
          ticket.status == 'used' &&
          ticket.leaderEmail.trim().toLowerCase() ==
              userEmail.trim().toLowerCase(),
    );
  }

  static DestinationReview submit({
    required String destinationId,
    required String ticketId,
    required String userEmail,
    required String userName,
    required int rating,
    required String review,
  }) {
    final ticket = TicketService.findById(ticketId);
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be from 1 to 5.');
    }
    if (review.trim().isEmpty) {
      throw ArgumentError.value(review, 'review', 'Cannot be empty.');
    }
    if (ticket == null ||
        ticket.destinationId != destinationId ||
        ticket.status != 'used' ||
        ticket.leaderEmail.trim().toLowerCase() != normalizedEmail ||
        !canReview(destinationId: destinationId, userEmail: normalizedEmail)) {
      throw StateError('A used ticket is required to submit a review.');
    }

    final destinationReview = DestinationReview(
      id: 'REV-${DateTime.now().microsecondsSinceEpoch}',
      destinationId: destinationId,
      ticketId: ticketId,
      userEmail: normalizedEmail,
      userName: userName.trim(),
      rating: rating,
      review: review.trim(),
      createdAt: DateTime.now(),
    );
    reviews.add(destinationReview);
    revision.value++;
    return destinationReview;
  }
}
