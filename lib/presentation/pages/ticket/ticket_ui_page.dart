import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ticket.dart';
import '../../../data/services/ticket_service.dart';
import '../destination/explorer_page.dart';
import '../home/home_page.dart';
import '../map/map_page.dart';
import '../profile/profile_page.dart';
import 'ticket_detail_page.dart';

String _formatDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} '
    '${_months[date.month - 1]} ${date.year}';

String _formatRupiah(int amount) =>
    'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

const _weekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _months = [
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

const _ticketNavy = Color(0xFF0D2B4A);
const _ticketBackground = Color(0xFFF8F7FF);
const _ticketLavender = Color(0xFFF0F1FF);

class TicketUIPage extends StatefulWidget {
  const TicketUIPage({super.key});

  @override
  State<TicketUIPage> createState() => _TicketUIPageState();
}

class _TicketUIPageState extends State<TicketUIPage> {
  bool _showHistory = false;

  static const _ticketCode = 'JMB-2026-88910';

  List<Ticket> get _activeTickets {
    final today = DateUtils.dateOnly(DateTime.now());
    return TicketService.tickets.where((ticket) {
      return ticket.status == 'valid' &&
          !DateUtils.dateOnly(ticket.visitDate).isBefore(today);
    }).toList();
  }

  List<Ticket> get _historyTickets {
    final today = DateUtils.dateOnly(DateTime.now());
    return TicketService.tickets.where((ticket) {
      return ticket.status != 'valid' ||
          DateUtils.dateOnly(ticket.visitDate).isBefore(today);
    }).toList();
  }

  Future<void> _copyTicketCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode tiket berhasil disalin')),
    );
  }

  void _showFullQr({
    String code = _ticketCode,
    String destination = 'Pantai Tanjung Papuma',
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'QR Tiket',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tunjukkan QR ini kepada petugas di pintu masuk',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: code,
                size: 240,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
              const SizedBox(height: 12),
              Text(
                destination,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Tiket $code',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf({
    required String code,
    required String destination,
    required String visitDate,
    required String quantity,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'JemberGo - Tiket Wisata',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(destination, style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Text('Tanggal kunjungan: $visitDate'),
              pw.Text('Jumlah tiket: $quantity'),
              pw.SizedBox(height: 20),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: code,
                width: 180,
                height: 180,
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                code,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Tunjukkan QR ini kepada petugas di pintu masuk.'),
            ],
          ),
        ),
      ),
    );

    final ready = await Printing.layoutPdf(
      name: 'tiket-$code.pdf',
      onLayout: (_) => document.save(),
    );
    if (!mounted || !ready) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF tiket siap dicetak atau disimpan')),
    );
  }

  void _openProfile() {
    _openDestination(4);
  }

  Future<void> _openDestination(int index) async {
    final Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
      case 1:
        page = const ExplorerPage();
      case 2:
        page = const MapPage();
      case 4:
        page = const ProfilePage();
      default:
        return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) setState(() {});
  }

  void _openTicketDetails(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => TicketDetailPage(ticket: ticket)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ticketBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _TicketHeader(onProfile: _openProfile),
                Expanded(
                  child: _showHistory
                      ? _HistoryPage(
                          tickets: _historyTickets,
                          onOpenTicket: (ticket) => _openTicketDetails(ticket),
                          onExplore: () => _openDestination(1),
                          onShowActive: () {
                            setState(() => _showHistory = false);
                          },
                        )
                      : _ActiveTicketPage(
                          tickets: _activeTickets,
                          historyTickets: _historyTickets,
                          onCopyCode: _copyTicketCode,
                          onShowQr: (ticket) => _showFullQr(
                            code: ticket?.id ?? _ticketCode,
                            destination:
                                ticket?.destinationName ??
                                'Pantai Tanjung Papuma',
                          ),
                          onDownloadPdf: (ticket) => _downloadPdf(
                            code: ticket?.id ?? _ticketCode,
                            destination:
                                ticket?.destinationName ??
                                'Pantai Tanjung Papuma',
                            visitDate: ticket == null
                                ? 'Minggu, 28 Sep 2026'
                                : _formatDate(ticket.visitDate),
                            quantity: ticket == null
                                ? '2 dewasa'
                                : '${ticket.adultCount} dewasa, ${ticket.childCount} anak',
                          ),
                          onOpenTicket: (ticket) => _openTicketDetails(ticket),
                          onShowHistory: () {
                            setState(() => _showHistory = true);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _TicketNavigationBar(
        onDestinationSelected: _openDestination,
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          Image.asset(
            'assets/logo_jembergonobackgroud.png',
            width: 34,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: _ticketNavy,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    children: [
                      TextSpan(text: 'JEMBER'),
                      TextSpan(
                        text: 'GO',
                        style: TextStyle(color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Ticket',
                  style: TextStyle(
                    color: _ticketNavy,
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _ticketNavy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketNavigationBar extends StatelessWidget {
  const _TicketNavigationBar({required this.onDestinationSelected});

  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
      (Icons.explore_outlined, Icons.explore, 'Jelajah'),
      (Icons.map_outlined, Icons.map, 'Peta'),
      (Icons.confirmation_number_outlined, Icons.confirmation_number, 'Tiket'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        color: Colors.white,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _TicketNavigationItem(
                  icon: items[index].$1,
                  selectedIcon: items[index].$2,
                  label: items[index].$3,
                  selected: index == 3,
                  onTap: () => onDestinationSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketNavigationItem extends StatelessWidget {
  const _TicketNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _ticketNavy : const Color(0xFF59636C);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFDDF3F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(selected ? selectedIcon : icon, color: color, size: 21),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 10,
              height: 1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTicketPage extends StatelessWidget {
  const _ActiveTicketPage({
    required this.tickets,
    required this.historyTickets,
    required this.onCopyCode,
    required this.onShowQr,
    required this.onDownloadPdf,
    required this.onOpenTicket,
    required this.onShowHistory,
  });

  final List<Ticket> tickets;
  final List<Ticket> historyTickets;
  final ValueChanged<String> onCopyCode;
  final ValueChanged<Ticket?> onShowQr;
  final ValueChanged<Ticket?> onDownloadPdf;
  final ValueChanged<Ticket> onOpenTicket;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      children: [
        _TicketTabs(
          showHistory: false,
          onTapActive: () {},
          onTapHistory: onShowHistory,
          activeCount: tickets.isEmpty ? 2 : tickets.length,
          historyCount: historyTickets.isEmpty ? 5 : historyTickets.length,
        ),
        const SizedBox(height: 8),
        if (tickets.isEmpty)
          _ActiveTicketCard(
            ticket: null,
            ticketCode: _TicketUIPageState._ticketCode,
            onCopyCode: () => onCopyCode(_TicketUIPageState._ticketCode),
            onShowQr: () => onShowQr(null),
            onDownloadPdf: () => onDownloadPdf(null),
            onOpenTicket: null,
          )
        else
          for (final ticket in tickets) ...[
            _ActiveTicketCard(
              ticket: ticket,
              ticketCode: ticket.id,
              onCopyCode: () => onCopyCode(ticket.id),
              onShowQr: () => onShowQr(ticket),
              onDownloadPdf: () => onDownloadPdf(ticket),
              onOpenTicket: () => onOpenTicket(ticket),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 14),
        if (historyTickets.isEmpty)
          _HistoryTicketCard(onTap: onShowHistory)
        else
          _HistoryTicketCard(
            ticket: historyTickets.last,
            onTap: () => onOpenTicket(historyTickets.last),
          ),
        const SizedBox(height: 20),
        _TicketHelpCard(onContact: () => _showHelpContact(context)),
      ],
    );
  }

  void _showHelpContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Helpdesk JemberGo'),
        content: const Text(
          'Hubungi WhatsApp helpdesk melalui kontak resmi JemberGo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({
    required this.tickets,
    required this.onOpenTicket,
    required this.onShowActive,
    required this.onExplore,
  });

  final List<Ticket> tickets;
  final ValueChanged<Ticket> onOpenTicket;
  final VoidCallback onShowActive;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _TicketTabs(
          showHistory: true,
          onTapActive: onShowActive,
          onTapHistory: () {},
          activeCount: TicketService.tickets
              .where((ticket) => ticket.status == 'valid')
              .length,
          historyCount: tickets.length,
        ),
        const SizedBox(height: 18),
        Text(
          'Tiket selesai',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Perjalanan wisata yang sudah Anda selesaikan',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(Icons.history, size: 52, color: AppColors.blue),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada tiket selesai',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tiket yang sudah digunakan akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onExplore,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Jelajahi wisata'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final ticket in tickets) ...[
            _HistoryTicketCard(
              ticket: ticket,
              onTap: () => onOpenTicket(ticket),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _TicketTabs extends StatelessWidget {
  const _TicketTabs({
    required this.showHistory,
    required this.onTapActive,
    required this.onTapHistory,
    required this.activeCount,
    required this.historyCount,
  });

  final bool showHistory;
  final VoidCallback onTapActive;
  final VoidCallback onTapHistory;
  final int activeCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Tiket Aktif',
              selected: !showHistory,
              onTap: onTapActive,
              activeCount: activeCount,
              historyCount: 0,
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Riwayat Selesai',
              selected: showHistory,
              onTap: onTapHistory,
              activeCount: 0,
              historyCount: historyCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeCount,
    required this.historyCount,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int activeCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ticketNavy : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((label == 'Tiket Aktif' && activeCount > 0) ||
                  (label == 'Riwayat Selesai' && historyCount > 0)) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${label == 'Tiket Aktif' ? activeCount : historyCount}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketDashedDivider extends StatelessWidget {
  const _TicketDashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 7).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => const SizedBox(
                width: 4,
                child: ColoredBox(color: Color(0xFFD5D8E4)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveTicketCard extends StatelessWidget {
  const _ActiveTicketCard({
    required this.ticket,
    required this.ticketCode,
    required this.onCopyCode,
    required this.onShowQr,
    required this.onDownloadPdf,
    required this.onOpenTicket,
  });

  final Ticket? ticket;
  final String ticketCode;
  final VoidCallback onCopyCode;
  final VoidCallback onShowQr;
  final VoidCallback onDownloadPdf;
  final VoidCallback? onOpenTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueDeep.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenTicket,
            child: _DestinationHero(
              destinationName:
                  ticket?.destinationName ?? 'Pantai Tanjung Papuma',
              location: ticket?.location ?? 'Wuluhan, Jember',
              imageUrl: ticket?.imageUrl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: _ticketLavender,
                    borderRadius: BorderRadius.circular(12),
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
                                color: AppColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ticket?.id ?? 'JMB-2026-88910',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ticketNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          onPressed: onCopyCode,
                          tooltip: 'Salin kode tiket',
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.copy_outlined,
                            size: 16,
                            color: _ticketNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jadwal Masuk',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket == null
                                ? 'Minggu, 28 Sep 2026'
                                : _formatDate(ticket!.visitDate),
                            style: const TextStyle(
                              color: _ticketNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            '08:00 – 17:00 WIB',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Rincian Pengunjung',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket == null
                                ? '2 Tiket Dewasa'
                                : '${ticket!.adultCount} Dewasa, ${ticket!.childCount} Anak',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: _ticketNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ticket == null || ticket!.totalPrice == 0
                                ? 'Rp 50.000 (Lunas)'
                                : '${_formatRupiah(ticket!.totalPrice)} (Lunas)',
                            style: const TextStyle(
                              color: Color(0xFF0064D9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _TicketDashedDivider(),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: _ticketLavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(
                          data: ticketCode,
                          size: 156,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 14,
                            color: _ticketNavy,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Scan barcode di pintu gerbang masuk',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onShowQr,
                        icon: const Icon(Icons.crop_free, size: 17),
                        label: const Text('QR Penuh'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _ticketNavy,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onDownloadPdf,
                        icon: const Icon(Icons.download_outlined, size: 17),
                        label: const Text('Unduh PDF'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E9FF),
                          foregroundColor: _ticketNavy,
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
}

class _DestinationHero extends StatelessWidget {
  const _DestinationHero({
    required this.destinationName,
    required this.location,
    this.imageUrl,
  });

  final String destinationName;
  final String location;
  final String? imageUrl;
  static const _imageUrl =
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21'
      '?auto=format&fit=crop&w=1000&q=80';

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl;
    return SizedBox(
      height: 144,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            resolvedImageUrl != null && resolvedImageUrl.isNotEmpty
                ? resolvedImageUrl
                : _imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _ScenicFallback(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x11000000), Color(0xB8000000)],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.confirmation_number,
                    color: Color(0xFFE88C00),
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tiket Wisata Resmi',
                    style: TextStyle(
                      color: _ticketNavy,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFFE88C00)),
                  SizedBox(width: 5),
                  Text(
                    'Siap Digunakan',
                    style: TextStyle(
                      color: Color(0xFF985100),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
                  destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 13, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      location,
                      style: TextStyle(color: Colors.white, fontSize: 10),
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

class _ScenicFallback extends StatelessWidget {
  const _ScenicFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC7DB), Color(0xFF16789B), Color(0xFF0D3B66)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 30,
            child: Icon(Icons.wb_sunny, color: Color(0xFFFFD166), size: 30),
          ),
          Positioned(
            left: 30,
            bottom: 8,
            child: Icon(Icons.landscape, color: Color(0xFF175A70), size: 90),
          ),
          Positioned(
            right: 20,
            bottom: -15,
            child: Icon(Icons.landscape, color: Color(0xFF0D3B66), size: 110),
          ),
        ],
      ),
    );
  }
}

class _HistoryTicketCard extends StatelessWidget {
  const _HistoryTicketCard({this.ticket, this.onTap});

  final Ticket? ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final destinationName = ticket?.destinationName ?? 'Puncak Rembangan';
    final imageUrl = ticket?.imageUrl;
    final visitDate = ticket == null
        ? 'Sabtu, 03 Okt 2026'
        : _formatDate(ticket!.visitDate);
    final summary = ticket == null
        ? '1 Tiket  •  Rp 10.000'
        : '${ticket!.quantity} Tiket  •  ${_formatRupiah(ticket!.totalPrice)}';
    final bookingCode = ticket?.id ?? 'JMB-2026-90432';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EFF8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 60,
                    child: Image.network(
                      imageUrl != null && imageUrl.isNotEmpty
                          ? imageUrl
                          : _DestinationHero._imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ScenicFallback(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Agrowisata',
                              style: TextStyle(
                                color: _ticketNavy,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ticket != null && ticket!.status == 'valid'
                                  ? 'Terkonfirmasi'
                                  : 'Selesai',
                              style: const TextStyle(
                                color: Color(0xFF005BC5),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destinationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ticketNavy,
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticket?.location ?? 'Arjasa, Jember',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: _ticketLavender,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Kunjungan',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visitDate,
                          style: const TextStyle(
                            color: _ticketNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Pesanan',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: const TextStyle(
                          color: _ticketNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.tag, color: AppColors.muted, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    bookingCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ticketNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text('Lihat Detail  ›'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketHelpCard extends StatelessWidget {
  const _TicketHelpCard({required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EFF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4E9FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Color(0xFF005BC5),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
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
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _HelpTile(
            icon: Icons.access_time,
            iconColor: Color(0xFFEE8A00),
            title: 'Ketentuan Jadwal Ulang (Reschedule)',
            detail: 'Perubahan jadwal mengikuti ketentuan destinasi dan ketersediaan tiket.',
          ),
          const SizedBox(height: 5),
          const _HelpTile(
            icon: Icons.currency_exchange,
            iconColor: Color(0xFF1267D6),
            title: 'Kebijakan Pengembalian Dana (Refund)',
            detail:
                'Pengajuan refund mengikuti kebijakan pembatalan yang berlaku.',
          ),
          const SizedBox(height: 5),
          const _HelpTile(
            icon: Icons.phone_android,
            iconColor: _ticketNavy,
            title: 'Kendala Scan Barcode di Lokasi?',
            detail: 'Naikkan kecerahan layar dan tunjukkan QR tiket secara penuh kepada petugas.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: _ticketLavender,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1679E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
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
                        style: TextStyle(color: AppColors.muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onContact,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ticketNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
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
    required this.iconColor,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _ticketLavender,
          borderRadius: BorderRadius.circular(9),
        ),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(42, 0, 12, 10),
          minTileHeight: 39,
          leading: Icon(icon, color: iconColor, size: 17),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ticketNavy,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                detail,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
