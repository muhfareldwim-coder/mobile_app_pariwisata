import 'package:flutter/material.dart';

import '../../../data/models/destination.dart';
import '../../../data/models/booking.dart';
import '../../../data/services/booking_service.dart';
import '../../widgets/custom_button.dart';
import 'checkout_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.destination});

  final Destination destination;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime date = DateTime.now();
  int adultCount = 1;
  int childCount = 0;
  final formKey = GlobalKey<FormState>();
  final leaderNameController = TextEditingController();
  final leaderEmailController = TextEditingController();
  final leaderPhoneController = TextEditingController();
  final memberControllers = <TextEditingController>[];

  @override
  void dispose() {
    leaderNameController.dispose();
    leaderEmailController.dispose();
    leaderPhoneController.dispose();
    for (final controller in memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncMemberFields() {
    final memberCount = adultCount + childCount - 1;
    while (memberControllers.length < memberCount) {
      memberControllers.add(TextEditingController());
    }
    while (memberControllers.length > memberCount) {
      memberControllers.removeLast().dispose();
    }
  }

  Future<void> _continueToCheckout() async {
    if (!formKey.currentState!.validate()) return;
    final today = DateTime.now();
    if (date.isBefore(DateTime(today.year, today.month, today.day))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal pemesanan tidak boleh sudah berlalu')));
      return;
    }
    final booking = await BookingService().createBooking(Booking(
      id: 'BOOK-${BookingService.bookings.length + 1}',
      destinationId: widget.destination.id,
      visitDate: date,
      adultCount: adultCount,
      childCount: childCount,
      leaderName: leaderNameController.text.trim(),
      leaderEmail: leaderEmailController.text.trim(),
      leaderPhone: leaderPhoneController.text.trim(),
      memberNames: memberControllers.map((controller) => controller.text.trim()).toList(),
    ));
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(booking: booking, destination: widget.destination)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Tiket')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.destination.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('Harga tiket: Rp ${widget.destination.ticketPrice}'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () async { final selected = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: date); if (selected != null) setState(() => date = selected); }, child: Text('Tanggal pemesanan: ${date.day}/${date.month}/${date.year}')),
            const SizedBox(height: 12),
            _Counter(label: 'Tiket dewasa', value: adultCount, onChanged: (value) { setState(() { adultCount = value; _syncMemberFields(); }); }),
            _Counter(label: 'Tiket anak', value: childCount, onChanged: (value) { setState(() { childCount = value; _syncMemberFields(); }); }),
            const SizedBox(height: 12),
            Text('Data ketua kelompok', style: Theme.of(context).textTheme.titleMedium),
            TextFormField(controller: leaderNameController, decoration: const InputDecoration(labelText: 'Nama ketua kelompok'), validator: _required),
            TextFormField(controller: leaderEmailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (value) { if (_required(value) != null) return _required(value); if (!(value!.contains('@'))) return 'Email tidak valid'; return null; }),
            TextFormField(controller: leaderPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP'), validator: _required),
            if (memberControllers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Nama anggota', style: Theme.of(context).textTheme.titleMedium),
              for (var index = 0; index < memberControllers.length; index++) TextFormField(controller: memberControllers[index], decoration: InputDecoration(labelText: 'Nama anggota ${index + 1}'), validator: _required),
            ],
            const SizedBox(height: 24),
            CustomButton(label: 'Lanjut Checkout', onPressed: _continueToCheckout),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label),
    const Spacer(),
    IconButton(onPressed: value > 0 && !(label == 'Tiket dewasa' && value == 1) ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove)),
    Text('$value'),
    IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add)),
  ]);
}