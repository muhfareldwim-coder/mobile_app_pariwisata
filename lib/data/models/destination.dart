class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.location,
    this.description = '',
    this.imageUrl,
    this.ticketPrice = 0,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final String? imageUrl;
  final int ticketPrice;
}