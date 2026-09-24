import 'package:flutter/material.dart';

import '../../../data/models/destination.dart';
import '../../widgets/custom_button.dart';

class DestinationDetailPage extends StatelessWidget {
  const DestinationDetailPage({super.key, required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(destination.name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(destination.location, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(destination.description.isEmpty ? 'Informasi destinasi wisata.' : destination.description),
            const Spacer(),
            CustomButton(label: 'Pesan Tiket', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}