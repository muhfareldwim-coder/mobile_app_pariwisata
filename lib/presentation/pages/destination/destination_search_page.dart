import 'package:flutter/material.dart';

class DestinationSearchPage extends StatelessWidget {
  const DestinationSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Destinasi')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: TextField(decoration: InputDecoration(hintText: 'Cari destinasi...')),
      ),
    );
  }
}