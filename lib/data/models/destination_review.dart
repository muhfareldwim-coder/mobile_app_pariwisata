class DestinationReview {
  const DestinationReview({
    required this.id,
    required this.destinationId,
    required this.ticketId,
    required this.userEmail,
    required this.userName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  final String id;
  final String destinationId;
  final String ticketId;
  final String userEmail;
  final String userName;
  final int rating;
  final String review;
  final DateTime createdAt;
}
