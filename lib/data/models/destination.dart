class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.location,
    this.description = '',
    this.imageUrl,
    this.ticketPrice = 0,
    this.category = 'ALAM',
    this.distanceKm = 0,
    this.rating = 0,
    this.reviewCount = '',
    this.facilities = const [],
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final String? imageUrl;
  final int ticketPrice;
  final String category;
  final double distanceKm;
  final double rating;
  final String reviewCount;
  final List<String> facilities;
}
