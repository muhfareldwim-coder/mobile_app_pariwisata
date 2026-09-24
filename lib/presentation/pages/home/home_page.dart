import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/destination.dart';
import '../booking/booking_page.dart';
import '../destination/explorer_page.dart';
import '../ticket/my_ticket_page.dart';

class HomePage extends StatelessWidget {
	const HomePage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('JemberGo'), actions: [IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.login), icon: const Icon(Icons.logout))]),
			body: ListView(padding: const EdgeInsets.all(20), children: [
				const Text('Sistem Pemesanan Tiket Wisata', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
				const SizedBox(height: 20),
				_ActionTile(title: 'Jelajah Destinasi', icon: Icons.explore, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerPage()))),
				_ActionTile(title: 'Pesan Tiket', icon: Icons.confirmation_number, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage(destination: Destination(id: 'papuma', name: 'Pantai Papuma', location: 'Jember', ticketPrice: 15000))))),
				_ActionTile(title: 'Tiket Saya', icon: Icons.qr_code, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketPage()))),
			]),
		);
	}
}

class _ActionTile extends StatelessWidget {
	const _ActionTile({required this.title, required this.icon, required this.onTap});
	final String title;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}