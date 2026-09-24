import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Peta Wisata')), body: const Center(child: Icon(Icons.map_outlined, size: 120)));
  }
}