class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.routeDistanceKm,
    this.description = '',
    this.imageUrl,
    this.ticketPrice = 0,
    this.category = 'ALAM',
    this.distanceKm = 0,
    this.rating = 0,
    this.reviewCount = '',
    this.facilities = const [],
    this.openingHours = '',
    this.gallery = const [],
    this.ticketTypes = const [],
    this.reviews = const [],
  });

  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final double routeDistanceKm;
  final String description;
  final String? imageUrl;
  final int ticketPrice;
  final String category;
  final double distanceKm;
  final double rating;
  final String reviewCount;
  final List<String> facilities;
  final String openingHours;
  final List<DestinationGallery> gallery;
  final List<DestinationTicketType> ticketTypes;
  final List<DestinationReviewEntry> reviews;
}

class DestinationGallery {
  const DestinationGallery({required this.url, this.caption});

  final String url;
  final String? caption;
}

class DestinationTicketType {
  const DestinationTicketType({
    required this.id,
    required this.name,
    required this.price,
  });

  final int id;
  final String name;
  final int price;
}

class DestinationReviewEntry {
  const DestinationReviewEntry({
    required this.name,
    required this.rating,
    required this.review,
  });

  final String name;
  final int rating;
  final String review;
}
