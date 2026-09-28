import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ticket.dart';
import '../../../data/services/ticket_service.dart';
import '../destination/explorer_page.dart';
import '../home/home_page.dart';
import '../map/map_page.dart';
import '../profile/profile_page.dart';
import 'ticket_pdf_download_stub.dart'
    if (dart.library.html) 'ticket_pdf_download_web.dart' as pdf_download;
import 'ticket_detail_page.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

DateTime get _demoVisitDate =>
    DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));

final _previewHistoryTicket = Ticket(
  id: 'JMB-2026-77802',
  bookingId: 'BOOK-DEMO',
  destinationName: 'Puncak Rembangan',
  visitDate: DateTime(2026, 2, 3),
  adultCount: 1,
  childCount: 0,
  leaderName: 'Pengguna JemberGo',
  leaderEmail: 'pengguna@example.com',
  leaderPhone: '0800000000',
  memberNames: [],
  status: 'used',
);

bool _hasVisitPassed(Ticket ticket) =>
    DateUtils.dateOnly(ticket.visitDate).isBefore(
      DateUtils.dateOnly(DateTime.now()),
    );

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

    final downloaded = await pdf_download.savePdf(
      await document.save(),
      'tiket-$code.pdf',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'PDF tiket berhasil diunduh'
              : 'Unduh PDF hanya tersedia di browser.',
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.blueDeep,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada notifikasi baru',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Informasi status tiket dan perjalanan akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _TicketHeader(
                  onNotifications: _showNotifications,
                  onProfile: _openProfile,
                  onHome: () => _openDestination(0),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _showHistory
                      ? _HistoryPage(
                          tickets: _historyTickets,
                          onOpenTicket: _openTicketDetails,
                          activeCount:
                              _activeTickets.isEmpty &&
                                  TicketService.tickets.isEmpty
                              ? 2
                              : _activeTickets.length,
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
                            visitDate: _formatDate(
                              ticket?.visitDate ?? _demoVisitDate,
                            ),
                            quantity: ticket == null
                                ? '2 dewasa'
                                : '${ticket.adultCount} dewasa, ${ticket.childCount} anak',
                          ),
                          onOpenTicket: _openTicketDetails,
                          onExplore: () => _openDestination(1),
                          onShowHistory: () {
                            setState(() => _showHistory = true);
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: NavigationBar(
                selectedIndex: 3,
                height: 64,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.sky.withValues(alpha: 0.5),
                onDestinationSelected: _openDestination,
                destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Jelajah',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Peta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number),
                  label: 'Tiket',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({
    required this.onNotifications,
    required this.onProfile,
    required this.onHome,
  });

  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          InkWell(
            onTap: onHome,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.blueDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onHome,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blueDeep,
                      ),
                      children: [
                        TextSpan(text: 'Jember'),
                        TextSpan(
                          text: 'Go',
                          style: TextStyle(color: AppColors.orange),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Tiket wisata',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifikasi',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.bg,
              foregroundColor: AppColors.blueDeep,
            ),
            icon: const Icon(Icons.notifications_none, size: 21),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(24),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.blueDeep,
              child: Icon(Icons.person, color: Colors.white, size: 19),
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
    required this.onExplore,
    required this.onShowHistory,
  });

  final List<Ticket> tickets;
  final List<Ticket> historyTickets;
  final ValueChanged<String> onCopyCode;
  final ValueChanged<Ticket?> onShowQr;
  final ValueChanged<Ticket?> onDownloadPdf;
  final ValueChanged<Ticket> onOpenTicket;
  final VoidCallback onExplore;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _TicketTabs(
          showHistory: false,
          onTapActive: () {},
          onTapHistory: onShowHistory,
          activeCount: tickets.isEmpty && TicketService.tickets.isEmpty
              ? 2
              : tickets.length,
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty && TicketService.tickets.isEmpty)
          _ActiveTicketCard(
            ticket: null,
            ticketCode: _TicketUIPageState._ticketCode,
            onCopyCode: () => onCopyCode(_TicketUIPageState._ticketCode),
            onShowQr: () => onShowQr(null),
            onDownloadPdf: () => onDownloadPdf(null),
            onOpenTicket: onExplore,
          )
        else if (tickets.isEmpty)
          _EmptyActiveTickets(onExplore: onExplore)
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
        if (historyTickets.isNotEmpty || TicketService.tickets.isEmpty) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Riwayat terakhir',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: onShowHistory,
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (historyTickets.isEmpty)
            _HistoryTicketCard(
              ticket: _previewHistoryTicket,
              onTap: () => onOpenTicket(_previewHistoryTicket),
            )
          else
            _HistoryTicketCard(
              ticket: historyTickets.last,
              onTap: () => onOpenTicket(historyTickets.last),
            ),
        ],
        const SizedBox(height: 20),
        Text(
          'Bantuan & Kebijakan',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const _HelpTile(
          icon: Icons.help_outline,
          title: 'Informasi tempat wisata',
          subtitle: 'Jam buka, lokasi, dan aturan masuk',
          detail: 'Periksa jam operasional dan aturan kunjungan destinasi sebelum berangkat.',
        ),
        const SizedBox(height: 8),
        const _HelpTile(
          icon: Icons.event_available_outlined,
          title: 'Kebijakan pengembalian dana',
          subtitle: 'Ketentuan perubahan dan pembatalan',
          detail: 'Pengajuan perubahan atau pembatalan mengikuti kebijakan destinasi yang dipilih.',
        ),
        const SizedBox(height: 8),
        const _HelpTile(
          icon: Icons.confirmation_number_outlined,
          title: 'Kendala scan QR tiket',
          subtitle: 'Cara menggunakan tiket digital',
          detail: 'Naikkan kecerahan layar dan tunjukkan QR secara penuh kepada petugas.',
        ),
      ],
    );
  }
}

class _EmptyActiveTickets extends StatelessWidget {
  const _EmptyActiveTickets({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            size: 52,
            color: AppColors.blue,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada tiket aktif',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tiket Anda yang akan datang akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Cari tiket wisata'),
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
    required this.activeCount,
    required this.onExplore,
  });

  final List<Ticket> tickets;
  final ValueChanged<Ticket> onOpenTicket;
  final VoidCallback onShowActive;
  final int activeCount;
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
          activeCount: activeCount,
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
  });

  final bool showHistory;
  final VoidCallback onTapActive;
  final VoidCallback onTapHistory;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Tiket Aktif',
              selected: !showHistory,
              onTap: onTapActive,
              count: activeCount,
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Riwayat Selesai',
              selected: showHistory,
              onTap: onTapHistory,
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
    this.count = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueDeep : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (label == 'Tiket Aktif' && count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
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
        borderRadius: BorderRadius.circular(20),
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
              location: 'Jember, Jawa Timur',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.blueDeep,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KODE TIKET',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticketCode,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onCopyCode,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Salin kode tiket',
                        icon: const Icon(
                          Icons.copy_outlined,
                          size: 18,
                          color: AppColors.blueDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TicketFact(
                        icon: Icons.calendar_month_outlined,
                        label: 'TANGGAL KUNJUNGAN',
                        value: _formatDate(
                          ticket?.visitDate ?? _demoVisitDate,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _TicketFact(
                        icon: Icons.people_outline,
                        label: 'JUMLAH TIKET',
                        value: ticket == null
                            ? '2 Tiket Dewasa'
                            : '${ticket!.adultCount} Dewasa, ${ticket!.childCount} Anak',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        '08:00 – 17:00 WIB',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ),
                    Text(
                      ticket == null ? 'Rp 50.000' : 'Lunas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.blueDeep,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7EDFA)),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: ticketCode,
                        size: 132,
                        backgroundColor: const Color(0xFFF5F8FF),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 14,
                            color: AppColors.blueDeep,
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
                      child: OutlinedButton.icon(
                        onPressed: onShowQr,
                        icon: const Icon(Icons.qr_code_2, size: 17),
                        label: const Text('QR Penuh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blueDeep,
                          side: const BorderSide(color: AppColors.blueDeep),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          backgroundColor: AppColors.blueDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
  });

  final String destinationName;
  final String location;
  static const _imageUrl =
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21'
      '?auto=format&fit=crop&w=1000&q=80';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl,
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
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF159947)),
                  SizedBox(width: 5),
                  Text(
                    'Tiket aktif',
                    style: TextStyle(
                      color: Color(0xFF14783C),
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

class _TicketFact extends StatelessWidget {
  const _TicketFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.blueDeep),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTicketCard extends StatelessWidget {
  const _HistoryTicketCard({
    this.ticket,
    this.onTap,
  });

  final Ticket? ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const demoDestination = 'Puncak Rembangan';
    const demoDate = 'Sabtu, 03 Feb 2026';
    const demoSummary = '1 Tiket  •  Rp 10.000';
    final destinationName = ticket?.destinationName ?? demoDestination;
    final visitDate =
        ticket == null ? demoDate : _formatDate(ticket!.visitDate);
    final summary = ticket == null
        ? demoSummary
        : '${ticket!.quantity} Tiket  •  ${_hasVisitPassed(ticket!) || ticket!.status != 'valid' ? 'Selesai' : 'Aktif'}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9DCB9E), Color(0xFF3E7960)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.forest_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visitDate,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: const TextStyle(
                        color: AppColors.blueDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(48, 0, 14, 14),
          leading: Icon(icon, color: AppColors.blueDeep, size: 20),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                detail,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
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
