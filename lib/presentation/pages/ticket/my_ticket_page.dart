import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/ticket.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../../core/utils/date_formatters.dart';
import 'manage_trip_page.dart';
import 'qr_ticket_page.dart';

const _ticketNavy = Color(0xFF173B60);
const _ticketBlue = Color(0xFF0874E8);
const _ticketOrange = Color(0xFFF58B05);
const _ticketBackground = Color(0xFFF8FAFC);

class MyTicketPage extends StatefulWidget {
  const MyTicketPage({super.key, this.onProfileTap, this.isSelected = true});

  final VoidCallback? onProfileTap;
  final bool isSelected;

  @override
  State<MyTicketPage> createState() => _MyTicketPageState();
}

class _MyTicketPageState extends State<MyTicketPage> {
  int _selectedTab = 0;
  bool _isLoading = false;
  String? _loadError;
  String? _loadedCustomerId;

  @override
  void initState() {
    super.initState();
    final userId = AuthService.currentUser?.id;
    if (widget.isSelected && userId != null) {
      _loadedCustomerId = userId;
      unawaited(_loadTickets());
    }
  }

  @override
  void didUpdateWidget(covariant MyTicketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      _loadedCustomerId = null;
    } else if (widget.isSelected && userId != _loadedCustomerId) {
      _loadedCustomerId = userId;
      unawaited(_loadTickets());
    }
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await TicketService().refreshFromServer();
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _TicketTabs(
                              selectedIndex: _selectedTab,
                              activeCount: active.length,
                              historyCount: history.length,
                              onSelected: (index) =>
                                  setState(() => _selectedTab = index),
                            ),
                            if (_loadError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _loadError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _loadTickets,
                                child: const Text('Muat ulang tiket'),
                              ),
                            ],
                            if (_isLoading) ...[
                              const SizedBox(height: 24),
                              const Center(child: CircularProgressIndicator()),
                            ],
                            const SizedBox(height: 12),
                            if (!_isLoading)
                              for (final ticket in displayed) ...[
                                if (ticket != displayed.first)
                                  const SizedBox(height: 14),
                                _CompactTicketCard(ticket: ticket),
                              ],
                          ]),
                        ),
                      ),
                      if (!_isLoading && displayed.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _EmptyTickets(
                                    isHistory: _selectedTab == 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                    'Tiket Saya',
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
        color: const Color(0xFFEAF2F8),
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
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF454B58),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _ticketBlue : const Color(0xFFDCE7EE),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF46526C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          style: const TextStyle(color: Color(0xFF7890A1), fontSize: 12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Jember',
                      style: const TextStyle(
                        color: Color(0xFF7B8290),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(
                icon: _ticketStatusIcon(ticket),
                label: _ticketStatusLabel(ticket),
                background: _ticketStatusBackground(ticket),
                foreground: _ticketStatusForeground(ticket),
                iconSize: 11,
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
                    value: formatIndonesianDate(ticket.visitDate),
                    detail: '',
                  ),
                ),
                _DetailColumn(
                  label: 'Total dibayar',
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
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => QrTicketPage(ticket: ticket),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ticketNavy,
                    side: const BorderSide(color: Color(0xFFDCE2F5)),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right, size: 17),
                  label: const Text(
                    'Lihat Detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (ticket.bookingRecordId.isNotEmpty &&
                  ticket.status == 'valid') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ManageTripPage(ticket: ticket),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ticketNavy,
                      side: const BorderSide(color: Color(0xFFDCE2F5)),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                    label: const Text(
                      'Kelola perjalanan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
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
              fontSize: 11,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tiket yang sudah dibeli akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7890A1), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

String _ticketStatusLabel(Ticket ticket) {
  switch (ticket.status) {
    case 'used':
      return 'Sudah digunakan';
    case 'valid':
      return 'Siap digunakan';
    default:
      return 'Terkonfirmasi';
  }
}

Color _ticketStatusBackground(Ticket ticket) {
  switch (ticket.status) {
    case 'used':
      return const Color(0xFFEAF3EE);
    case 'valid':
      return const Color(0xFFFFF3E2);
    default:
      return const Color(0xFFEAF2F8);
  }
}

Color _ticketStatusForeground(Ticket ticket) {
  switch (ticket.status) {
    case 'used':
      return const Color(0xFF13795B);
    case 'valid':
      return const Color(0xFF9A5200);
    default:
      return const Color(0xFF1D4E89);
  }
}

IconData _ticketStatusIcon(Ticket ticket) {
  switch (ticket.status) {
    case 'used':
      return Icons.check_circle_rounded;
    case 'valid':
      return Icons.schedule_rounded;
    default:
      return Icons.info_rounded;
  }
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
