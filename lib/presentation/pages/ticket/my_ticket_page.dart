import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/ticket.dart';
import '../../../data/services/ticket_service.dart';
import 'qr_ticket_page.dart';

const _ticketNavy = Color(0xFF0B294A);
const _ticketBlue = Color(0xFF0874E8);
const _ticketOrange = Color(0xFFE98600);
const _ticketBackground = Color(0xFFF9F8FF);

class MyTicketPage extends StatefulWidget {
  const MyTicketPage({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<MyTicketPage> createState() => _MyTicketPageState();
}

class _MyTicketPageState extends State<MyTicketPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ticketBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TicketHeader(onProfileTap: widget.onProfileTap),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: TicketService.revision,
                builder: (context, revision, child) {
                  final tickets = TicketService.tickets;
                  final active = tickets.where(_isActive).toList();
                  final history = tickets
                      .where((ticket) => !_isActive(ticket))
                      .toList();
                  final displayed = _selectedTab == 0 ? active : history;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _TicketTabs(
                        selectedIndex: _selectedTab,
                        activeCount: active.length,
                        historyCount: history.length,
                        onSelected: (index) =>
                            setState(() => _selectedTab = index),
                      ),
                      const SizedBox(height: 12),
                      if (displayed.isEmpty)
                        _EmptyTickets(isHistory: _selectedTab == 1)
                      else ...[
                        _ActiveTicketCard(ticket: displayed.first),
                        for (final ticket in displayed.skip(1)) ...[
                          const SizedBox(height: 14),
                          _CompactTicketCard(ticket: ticket),
                        ],
                      ],
                      const SizedBox(height: 20),
                      const _TicketHelpSection(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(Ticket ticket) {
    final today = DateTime.now();
    final visitDay = DateTime(
      ticket.visitDate.year,
      ticket.visitDate.month,
      ticket.visitDate.day,
    );
    return ticket.status == 'valid' &&
        !visitDay.isBefore(DateTime(today.year, today.month, today.day));
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Image.asset(
              'assets/logo_jembergonobackgroud.png',
              width: 38,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.landscape_rounded,
                color: _ticketOrange,
                size: 29,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JEMBERGO',
                    style: TextStyle(
                      color: _ticketOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ticket',
                    style: TextStyle(
                      color: _ticketNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: onProfileTap ?? () {},
              tooltip: 'Profil',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF061D38),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTabs extends StatelessWidget {
  const _TicketTabs({
    required this.selectedIndex,
    required this.activeCount,
    required this.historyCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int activeCount;
  final int historyCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TicketTabButton(
              label: 'Tiket Aktif',
              count: activeCount,
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _TicketTabButton(
              label: 'Riwayat Selesai',
              count: historyCount,
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTabButton extends StatelessWidget {
  const _TicketTabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ticketNavy : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF454B58),
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _ticketBlue : const Color(0xFFD8DDF0),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF46526C),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTicketCard extends StatelessWidget {
  const _ActiveTicketCard({required this.ticket});

  final Ticket ticket;

  String get _qrData =>
      'JEMBERGO|${ticket.id}|${ticket.bookingId}|${ticket.destinationName}|${ticket.visitDate.toIso8601String()}';

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1609233F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _TicketImageHero(ticket: ticket),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              children: [
                _BookingCodeRow(bookingId: ticket.bookingId),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailColumn(
                        label: 'Jadwal Masuk',
                        value: _formatDate(ticket.visitDate),
                        detail: '08:00 - 17:00 WIB',
                      ),
                    ),
                    Expanded(
                      child: _DetailColumn(
                        label: 'Rincian Pengunjung',
                        value: '${ticket.quantity} Tiket',
                        detail: ticket.amountPaid > 0
                            ? '${_formatPrice(ticket.amountPaid)} (Lunas)'
                            : 'QRIS (Lunas)',
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const _DashedDivider(),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 164,
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
                      const SizedBox(height: 7),
                      const Text(
                        'Scan barcode langsung di pos loket gerbang masuk',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4D5665),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 43,
                        child: FilledButton.icon(
                          onPressed: () => _openTicketDetail(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _ticketNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_2, size: 18),
                          label: const Text(
                            'QR Penuh',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 43,
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unduh PDF tersedia setelah backend aktif.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFE4E8FF),
                            foregroundColor: _ticketBlue,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 17),
                          label: const Text(
                            'Unduh PDF',
                            style: TextStyle(fontSize: 11),
                          ),
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

  void _openTicketDetail(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => QrTicketPage(ticket: ticket)),
    );
  }
}

class _TicketImageHero extends StatelessWidget {
  const _TicketImageHero({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ticket.destinationImageUrl != null &&
              ticket.destinationImageUrl!.isNotEmpty)
            Image.network(
              ticket.destinationImageUrl!,
              fit: BoxFit.cover,
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
                stops: [0.3, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _Badge(
              icon: Icons.confirmation_number_rounded,
              label: 'Tiket Wisata Resmi',
              background: const Color(0xFFF4F8FF),
              foreground: _ticketNavy,
            ),
          ),
          const Positioned(
            right: 12,
            top: 12,
            child: _Badge(
              icon: Icons.circle,
              label: 'Siap Digunakan',
              background: Color(0xFFFFF8EC),
              foreground: Color(0xFF8A4D00),
              iconSize: 7,
            ),
          ),
          Positioned(
            left: 13,
            right: 13,
            bottom: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '⌖ Jember, Jawa Timur',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
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
      child: Icon(Icons.landscape_rounded, color: _ticketNavy, size: 38),
    ),
  );
}

class _BookingCodeRow extends StatelessWidget {
  const _BookingCodeRow({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2FF),
        borderRadius: BorderRadius.circular(8),
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
                    color: Color(0xFF777F8E),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bookingId,
                  style: const TextStyle(
                    color: _ticketNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: bookingId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode booking disalin.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Salin kode booking',
            icon: const Icon(Icons.copy_rounded, color: _ticketBlue, size: 17),
          ),
        ],
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  const _DetailColumn({
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
          style: const TextStyle(color: Color(0xFF7A818D), fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: _ticketNavy,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: alignEnd ? _ticketBlue : const Color(0xFF626B79),
            fontSize: 9,
            fontWeight: alignEnd ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        (constraints.maxWidth / 8).floor(),
        (_) => Container(width: 4, height: 1, color: const Color(0xFFCDD3E1)),
      ),
    ),
  );
}

class _CompactTicketCard extends StatelessWidget {
  const _CompactTicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ticket.destinationImageUrl == null
                      ? const _TicketImageFallback()
                      : Image.network(
                          ticket.destinationImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _TicketImageFallback(),
                        ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Badge(
                      icon: Icons.park_outlined,
                      label: 'Wisata',
                      background: Color(0xFFE6EAFF),
                      foreground: _ticketNavy,
                      iconSize: 10,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.destinationName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ticketNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Jember',
                      style: const TextStyle(
                        color: Color(0xFF7B8290),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(
                icon: Icons.circle,
                label: 'Terkonfirmasi',
                background: const Color(0xFFE6EEFF),
                foreground: _ticketBlue,
                iconSize: 6,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DetailColumn(
                    label: 'Tanggal Kunjungan',
                    value: _formatDate(ticket.visitDate),
                    detail: '',
                  ),
                ),
                _DetailColumn(
                  label: 'Pesanan',
                  value: '${ticket.quantity} tiket',
                  detail: ticket.amountPaid > 0
                      ? _formatPrice(ticket.amountPaid)
                      : 'QRIS lunas',
                  alignEnd: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.tag, color: Color(0xFF838A96), size: 17),
              Expanded(
                child: Text(
                  ticket.bookingId,
                  style: const TextStyle(
                    color: Color(0xFF59616E),
                    fontSize: 11,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => QrTicketPage(ticket: ticket),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: _ticketNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text(
                  'Lihat Detail',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.iconSize = 10,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets({required this.isHistory});

  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          Icon(
            isHistory
                ? Icons.history_rounded
                : Icons.confirmation_number_outlined,
            color: const Color(0xFF9AA6B6),
            size: 39,
          ),
          const SizedBox(height: 10),
          Text(
            isHistory ? 'Belum ada tiket selesai' : 'Belum ada tiket aktif',
            style: const TextStyle(
              color: _ticketNavy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tiket yang sudah dibeli akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7C8491), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TicketHelpSection extends StatelessWidget {
  const _TicketHelpSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: _ticketBlue, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bantuan & Kebijakan Tiket',
                      style: TextStyle(
                        color: _ticketNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Informasi mudah seputar tiket JemberGo',
                      style: TextStyle(color: Color(0xFF727A88), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const _HelpTile(
            icon: Icons.access_time_rounded,
            title: 'Ketentuan Jadwal Ulang (Reschedule)',
            content: 'Tiket yang sudah dibeli tidak dapat dijadwalkan ulang (reschedule).',
          ),
          const _HelpTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Kebijakan Pengembalian Dana (Refund)',
            content: 'Tiket yang sudah dibeli tidak dapat dikembalikan dananya (refund).',
          ),
          const _HelpTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Kendala Scan Barcode di Lokasi?',
            content: 'Tunjukkan kode booking kepada petugas loket untuk pemeriksaan manual.',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_rounded, color: _ticketBlue, size: 19),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp Helpdesk Dispar',
                        style: TextStyle(
                          color: _ticketNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Respon cepat 08:00 - 18:00 WIB',
                        style: TextStyle(color: Color(0xFF707988), fontSize: 9),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Helpdesk akan tersedia setelah kontak resmi ditambahkan.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ticketNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(58, 31),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(fontSize: 9),
                  ),
                  child: const Text('Hubungi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 9),
        childrenPadding: const EdgeInsets.fromLTRB(36, 0, 12, 10),
        leading: Icon(icon, color: _ticketBlue, size: 17),
        title: Text(
          title,
          style: const TextStyle(
            color: _ticketNavy,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF1F2FF),
        collapsedBackgroundColor: const Color(0xFFF1F2FF),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        children: [
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF697486),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
