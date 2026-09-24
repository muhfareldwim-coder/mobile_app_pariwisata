import 'package:flutter/material.dart';

import '../../../data/models/destination.dart';
import '../booking/booking_page.dart';
import '../../widgets/destination_card.dart';

class ExplorerPage extends StatelessWidget {
  const ExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    const destinations = [
      Destination(id: '1', name: 'Pantai Papuma', location: 'Jember', ticketPrice: 15000),
      Destination(id: '2', name: 'Air Terjun Tancak', location: 'Jember', ticketPrice: 10000),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Jelajah Destinasi')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: destinations.length,
        itemBuilder: (_, index) => DestinationCard(
          destination: destinations[index],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(destination: destinations[index]))),
        ),
      ),
    );
  }
}