import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/ticket.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../../data/services/ticket_pdf_service.dart';
import '../../../core/utils/date_formatters.dart';

const _ticketNavy = Color(0xFF173B60);
const _ticketBlue = Color(0xFF0874E8);
const _ticketBackground = Color(0xFFF8FAFC);

class QrTicketPage extends StatelessWidget {
  const QrTicketPage({super.key, required this.ticket});

  final Ticket ticket;

  String get _qrData => TicketService.qrPayload(ticket);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: TicketService.revision,
    builder: (context, revision, child) {
      final currentTicket = TicketService.findById(ticket.id) ?? ticket;
      final currentQrData = TicketService.qrPayload(currentTicket);
      return Scaffold(
        backgroundColor: _ticketBackground,
        appBar: AppBar(
          backgroundColor: _ticketBackground,
          foregroundColor: _ticketNavy,
          title: const Text('Detail E-Tiket'),
          centerTitle: false,
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
            _TicketUseStatus(ticket: currentTicket),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () => _showLargeQr(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ticketNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2, size: 19),
                      label: const Text('QR Penuh'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          downloadTicketPdf(context, currentTicket),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ticketBlue,
                        backgroundColor: const Color(0xFFEAF2F8),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 19),
                      label: const Text('Unduh PDF'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _TicketNotice(),
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

  Future<void> _showLargeQr(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ticket.destinationName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ticketNavy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 260,
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
            const SizedBox(height: 8),
            Text(
              ticket.bookingId,
              style: const TextStyle(
                color: _ticketNavy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    ),
  );
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

class _TicketUseStatus extends StatelessWidget {
  const _TicketUseStatus({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final isOwner =
        user != null &&
        user.email.trim().toLowerCase() ==
            ticket.leaderEmail.trim().toLowerCase();
    final now = DateTime.now();
    final visitDay = DateTime(
      ticket.visitDate.year,
      ticket.visitDate.month,
      ticket.visitDate.day,
    );
    final canConfirm =
        isOwner &&
        ticket.status == 'valid' &&
        !visitDay.isAfter(DateTime(now.year, now.month, now.day));

    if (ticket.status == 'used') {
      return const _UsageStatus(
        icon: Icons.verified_rounded,
        message: 'Tiket sudah digunakan',
        detail: 'Kamu sudah bisa memberikan rating dan ulasan.',
      );
    }

    if (!canConfirm) {
      final isUpcoming =
          ticket.status == 'valid' &&
          visitDay.isAfter(DateTime(now.year, now.month, now.day));
      return _UsageStatus(
        icon: isUpcoming
            ? Icons.event_available_rounded
            : Icons.confirmation_number_outlined,
        message: isUpcoming ? 'Tiket siap digunakan' : 'Tiket aktif',
        detail: isUpcoming
            ? 'Berlaku pada ${formatIndonesianDate(ticket.visitDate)}. Tunjukkan QR ini di pintu masuk.'
            : 'Tunjukkan QR ini kepada petugas di pintu masuk.',
        isUpcoming: isUpcoming,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: !canConfirm
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi kunjungan'),
                      content: const Text(
                        'Fitur scan QR petugas belum tersedia. Konfirmasi '
                        'hanya jika Anda benar-benar sudah menggunakan tiket '
                        'dan berkunjung ke destinasi.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Saya sudah berkunjung'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;

                  final currentUser = AuthService.currentUser;
                  final marked =
                      currentUser != null &&
                      TicketService.markAsUsed(ticket.id, currentUser.email);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        marked
                            ? 'Kunjungan dicatat. Rating dan ulasan sekarang tersedia.'
                            : 'Tiket ini belum dapat dikonfirmasi digunakan.',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: Text(
            canConfirm
                ? 'Konfirmasi sudah berkunjung'
                : 'Tersedia setelah tanggal kunjungan',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _ticketNavy,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Konfirmasi hanya jika kamu sudah berkunjung.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7890A1), fontSize: 11),
        ),
      ],
    );
  }
}

class _UsageStatus extends StatelessWidget {
  const _UsageStatus({
    required this.icon,
    required this.message,
    required this.detail,
    this.isUpcoming = false,
  });

  final IconData icon;
  final String message;
  final String detail;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: isUpcoming ? const Color(0xFFFFF3E2) : const Color(0xFFEAF3EE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: isUpcoming ? const Color(0xFF9A5200) : const Color(0xFF13795B),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: _ticketNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF617486),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
              children: [
                _BookingCodePanel(bookingId: ticket.bookingId, onCopy: onCopy),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TicketInfo(
                        label: 'Jadwal Masuk',
                        value: formatIndonesianDate(ticket.visitDate),
                        detail: '08:00 - 17:00 WIB',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TicketInfo(
                        label: 'Rincian Pengunjung',
                        value: '${ticket.quantity} Tiket',
                        detail: ticket.amountPaid > 0
                            ? '${_formatPrice(ticket.amountPaid)} (Lunas)'
                            : '${ticket.paymentMethod} (Lunas)',
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
                          const SizedBox(height: 9),
                          const Text(
                            'Tunjukkan QR e-tiket kepada petugas di pintu masuk',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF4A5363),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
            left: 12,
            top: 12,
            child: _TicketPill(
              icon: Icons.confirmation_number_rounded,
              label: 'Tiket Wisata Resmi',
              background: const Color(0xFFF4F8FF),
              foreground: _ticketNavy,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _TicketPill(
              icon: Icons.circle,
              label: ticket.status == 'used'
                  ? 'Sudah Digunakan'
                  : 'Siap Digunakan',
              background: ticket.status == 'used'
                  ? const Color(0xFFE9F7EF)
                  : const Color(0xFFFFF8EC),
              foreground: ticket.status == 'used'
                  ? const Color(0xFF16854B)
                  : const Color(0xFF8A4D00),
              iconSize: 7,
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
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        'Jember, Jawa Timur',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
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

class _TicketPill extends StatelessWidget {
  const _TicketPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.iconSize = 11,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: iconSize),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
          IconButton.filledTonal(
            onPressed: onCopy,
            tooltip: 'Salin kode booking',
            icon: const Icon(Icons.copy_rounded, color: _ticketBlue, size: 18),
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
    required this.detail,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final String detail;
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: alignEnd ? _ticketBlue : const Color(0xFF626B79),
            fontSize: 11,
            fontWeight: alignEnd ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
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

class _TicketNotice extends StatelessWidget {
  const _TicketNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(11),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: _ticketBlue, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tunjukkan QR ini kepada petugas gerbang. QR hanya berlaku untuk tanggal kunjungan yang tertera.',
            style: TextStyle(
              color: Color(0xFF4E5C72),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
