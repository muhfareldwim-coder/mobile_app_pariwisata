import 'package:flutter/material.dart';

import '../../data/models/destination.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination, this.onTap});

  final Destination destination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.landscape_outlined),
        title: Text(destination.name),
        subtitle: Text(destination.location),
        trailing: Text('Rp ${destination.ticketPrice}'),
      ),
    );
  }
}