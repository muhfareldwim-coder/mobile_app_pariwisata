import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/ticket.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../../data/services/ticket_pdf_service.dart';

const _ticketNavy = Color(0xFF173B60);
const _ticketBackground = Color(0xFFF8FAFC);

class QrTicketPage extends StatelessWidget {
  const QrTicketPage({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: TicketService.revision,
    builder: (context, revision, child) {
      final currentTicket = TicketService.findById(ticket.id) ?? ticket;
      final currentQrData = TicketService.qrPayload(currentTicket);
      return Scaffold(
        backgroundColor: _ticketBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _ticketNavy,
          title: const Text('Detail E-Tiket'),
          centerTitle: false,
          surfaceTintColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _TicketPass(
              ticket: currentTicket,
              qrData: currentQrData,
              onCopy: () => _copyBookingCode(context),
            ),
            const SizedBox(height: 12),
            if ((currentTicket.hasUsedTicket ||
                    currentTicket.status == 'used' ||
                    currentTicket.status == 'partial') &&
                !currentTicket.isReviewed)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => _writeReview(context, currentTicket),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF58B05),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text('Beri Review'),
                ),
              ),
          ],
        ),
      );
    },
  );

  Future<void> _copyBookingCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: ticket.bookingId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode booking disalin.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _writeReview(BuildContext context, Ticket currentTicket) async {
    final formKey = GlobalKey<FormState>();
    final reviewController = TextEditingController();
    var rating = 5;
    final review = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Beri Review'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bagaimana pengalamanmu di destinasi ini?'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setDialogState(() => rating = index + 1),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF58B05),
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: reviewController,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tulis ulasanmu',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ulasan tidak boleh kosong.'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, (
                    rating,
                    reviewController.text.trim(),
                  ));
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    reviewController.dispose();
    if (review == null || !context.mounted) return;
    try {
      await TicketService().submitReview(
        ticketId: currentTicket.id,
        rating: review.$1,
        review: review.$2,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih, review berhasil dikirim.')),
      );
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

Future<void> downloadTicketPdf(BuildContext context, Ticket ticket) async {
  try {
    final saved = await TicketPdfService.save(ticket);
    if (!context.mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF e-tiket berhasil disimpan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on Exception catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF e-tiket gagal disimpan: $error'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TicketPass extends StatelessWidget {
  const _TicketPass({
    required this.ticket,
    required this.qrData,
    required this.onCopy,
  });

  final Ticket ticket;
  final String qrData;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1609233F),
            blurRadius: 13,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _TicketHero(ticket: ticket),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tunjukkan kode booking kepada petugas saat tiba di destinasi.',
                  style: TextStyle(
                    color: Color(0xFF617486),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TicketDetailBadge(
                        label: _formatPaymentStatus(ticket.paymentStatus),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TicketDetailBadge(
                        label: _formatTicketDate(ticket.visitDate),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => downloadTicketPdf(context, ticket),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ticketNavy,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: _ticketNavy),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text(
                            'Unduh PDF',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BookingCodePanel(bookingId: ticket.bookingId, onCopy: onCopy),
                const SizedBox(height: 14),
                Text(
                  'Ketua kelompok',
                  style: const TextStyle(
                    color: Color(0xFF7890A1),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ticket.leaderName,
                  style: const TextStyle(
                    color: _ticketNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ticket.leaderEmail.isNotEmpty ||
                    ticket.leaderPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      ticket.leaderEmail,
                      ticket.leaderPhone,
                    ].where((value) => value.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      color: Color(0xFF626B79),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TicketInfo(
                        label: 'Total peserta',
                        value: '${ticket.memberNames.length + 1} orang',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TicketInfo(
                        label: 'Total dibayar',
                        value: _formatPrice(ticket.amountPaid),
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const _DashedRule(),
                const SizedBox(height: 13),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _TicketStatusLabel(status: ticket.status),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 180,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: _ticketNavy,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: _ticketNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Kode QR booking',
                            style: TextStyle(
                              color: _ticketNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Satu kode QR untuk seluruh peserta dalam booking ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF617486),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _TicketMetaRow(
                            label: 'Kode booking',
                            value: ticket.bookingId,
                          ),
                          _TicketMetaRow(
                            label: 'Jumlah peserta',
                            value: '${ticket.memberNames.length + 1} orang',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketHero extends StatelessWidget {
  const _TicketHero({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ticket.destinationImageUrl != null &&
              ticket.destinationImageUrl!.isNotEmpty)
            Image.network(
              ticket.destinationImageUrl!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => const _TicketImageFallback(),
            )
          else
            const _TicketImageFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD900152D)],
                stops: [0.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketImageFallback extends StatelessWidget {
  const _TicketImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFDDEAF2),
    child: Center(
      child: Icon(Icons.landscape_rounded, color: _ticketNavy, size: 42),
    ),
  );
}

class _TicketDetailBadge extends StatelessWidget {
  const _TicketDetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 3),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _ticketNavy),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _ticketNavy,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _BookingCodePanel extends StatelessWidget {
  const _BookingCodePanel({required this.bookingId, required this.onCopy});

  final String bookingId;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KODE BOOKING',
                  style: TextStyle(
                    color: Color(0xFF737B89),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bookingId,
                  style: const TextStyle(
                    color: _ticketNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'Salin kode booking',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _ticketNavy,
              side: const BorderSide(color: Color(0xFFD7E2EA)),
            ),
            icon: const Icon(Icons.copy_rounded, color: _ticketNavy, size: 18),
          ),
        ],
      ),
    );
  }
}

class _TicketInfo extends StatelessWidget {
  const _TicketInfo({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7890A1), fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: _ticketNavy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TicketStatusLabel extends StatelessWidget {
  const _TicketStatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      'pending' => (
        'Menunggu pembayaran',
        const Color(0xFF8A4D00),
        const Color(0xFFFFF8EC),
      ),
      'used' => (
        'Sudah digunakan',
        const Color(0xFF16854B),
        const Color(0xFFE9F7EF),
      ),
      'partial' => (
        'Sebagian digunakan',
        const Color(0xFF173B60),
        const Color(0xFFEAF2F8),
      ),
      'expired' => (
        'Kedaluwarsa',
        const Color(0xFF9B303A),
        const Color(0xFFFFEDEE),
      ),
      'failed' => ('Gagal', const Color(0xFF9B303A), const Color(0xFFFFEDEE)),
      'unknown' => (
        'Tidak diketahui',
        const Color(0xFF617486),
        const Color(0xFFEAF2F8),
      ),
      _ => ('Terkonfirmasi', const Color(0xFF16854B), const Color(0xFFE9F7EF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TicketMetaRow extends StatelessWidget {
  const _TicketMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF7890A1), fontSize: 11),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _ticketNavy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) =>
                Container(width: 4, height: 1, color: const Color(0xFFCDD3E1)),
          ),
        );
      },
    );
  }
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _formatTicketDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _formatPaymentStatus(String status) => switch (status) {
  'PAID' => 'Lunas',
  'PENDING' => 'Menunggu pembayaran',
  'FAILED' => 'Gagal',
  'EXPIRED' => 'Kedaluwarsa',
  _ => 'Belum dibayar',
};
