import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/ticket.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../../core/utils/date_formatters.dart';
import '../booking/payment_page.dart';
import '../destination/explorer_page.dart';
import 'manage_trip_page.dart';
import 'qr_ticket_page.dart';

const _ticketNavy = Color(0xFF12304A);
const _ticketBlue = Color(0xFF244D70);
const _ticketBackground = Color(0xFFF6F8FB);
const _ticketSecondaryText = Color(0xFF8190A5);
const _ticketBorder = Color(0xFFE3EAF2);

class MyTicketPage extends StatefulWidget {
  const MyTicketPage({
    super.key,
    this.onExploreTap,
    this.isSelected = true,
  });

  final VoidCallback? onExploreTap;
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
    _loadedCustomerId = userId;
    if (widget.isSelected && userId != null) {
      unawaited(_loadTickets());
    }
  }

  @override
  void didUpdateWidget(covariant MyTicketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      _loadedCustomerId = null;
      _clearTickets();
    } else if (userId != _loadedCustomerId) {
      _loadedCustomerId = userId;
      _clearTickets();
      if (widget.isSelected) unawaited(_loadTickets());
    } else if (widget.isSelected && !oldWidget.isSelected) {
      unawaited(_loadTickets());
    }
  }

  Future<void> _loadTickets() async {
    final customerId = AuthService.currentUser?.id;
    if (customerId == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await TicketService().refreshFromServer(expectedCustomerId: customerId);
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearTickets() {
    if (TicketService.tickets.isEmpty) return;
    TicketService.tickets.clear();
    TicketService.revision.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ticketBackground,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const _TicketHeader(),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: TicketService.revision,
                builder: (context, revision, child) {
                  final tickets = TicketService.tickets;
                  final isAuthenticated = AuthService.currentUser != null;
                  final active = tickets.where(_isActive).toList();
                  final history = tickets.where(_isHistory).toList();
                  final displayed = switch (_selectedTab) {
                    0 => active,
                    1 => history,
                    _ => tickets,
                  };
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _TicketTabs(
                              selectedIndex: _selectedTab,
                              activeCount: active.length,
                              historyCount: history.length,
                              allCount: tickets.length,
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
                                _CompactTicketCard(
                                  ticket: ticket,
                                  selectedTab: _selectedTab,
                                  onPaymentReturned: _loadTickets,
                                ),
                              ],
                          ]),
                        ),
                      ),
                      if (!_isLoading && displayed.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyTickets(
                              selectedTab: _selectedTab,
                              requiresLogin: !isAuthenticated,
                              onExplore: _openExplorer,
                              onLogin: _openLogin,
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
    return ticket.hasIssuedTicket &&
        (ticket.hasActiveTicket || ticket.status == 'valid');
  }

  bool _isHistory(Ticket ticket) =>
      ticket.hasIssuedTicket &&
      (ticket.hasUsedTicket ||
          ticket.hasExpiredTicket ||
          const {'used', 'expired'}.contains(ticket.status));

  void _openExplorer() {
    final onExploreTap = widget.onExploreTap;
    if (onExploreTap != null) {
      onExploreTap();
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ExplorerPage()),
    );
  }

  Future<void> _openLogin() async {
    await Navigator.pushNamed(context, AppRoutes.login);
    if (!mounted || AuthService.currentUser == null) return;

    _loadedCustomerId = AuthService.currentUser?.id;
    _clearTickets();
    await _loadTickets();
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('ticket-header'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.viewPaddingOf(context).top + 10,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ticketNavy, _ticketBlue],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiket Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Kelola tiket dan pesanan perjalananmu.',
            style: TextStyle(
              color: Color(0xFFCCD8E5),
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTabs extends StatelessWidget {
  const _TicketTabs({
    required this.selectedIndex,
    required this.activeCount,
    required this.historyCount,
    required this.allCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int activeCount;
  final int historyCount;
  final int allCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ticketBorder),
        ),
        child: Row(
          children: [
            _TicketTabButton(
              label: 'Tiket aktif',
              count: activeCount,
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _TicketTabButton(
              label: 'Riwayat tiket',
              count: historyCount,
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            _TicketTabButton(
              label: 'Semua pesanan',
              count: allCount,
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 116,
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
                      color: selected ? Colors.white : _ticketSecondaryText,
                      fontSize: 11,
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
                    color: selected
                        ? const Color(0xFF3974D8)
                        : const Color(0xFFF0F3F7),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : _ticketSecondaryText,
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
  const _CompactTicketCard({
    required this.ticket,
    required this.selectedTab,
    required this.onPaymentReturned,
  });

  final Ticket ticket;
  final int selectedTab;
  final Future<void> Function() onPaymentReturned;

  bool get _canManageTrip =>
      selectedTab == 0 &&
      ticket.canOpenEticket &&
      ticket.hasIssuedTicket &&
      (ticket.hasActiveTicket || ticket.status == 'valid');

  void _openManageTrip(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => ManageTripPage(ticket: ticket)),
    );
  }

  Future<void> _openPayment(BuildContext context) async {
    final booking = Booking(
      id: ticket.bookingRecordId,
      code: ticket.bookingId,
      destinationId: ticket.destinationId,
      visitDate: ticket.visitDate,
      totalAmount: ticket.amountPaid,
      leaderName: ticket.leaderName,
      leaderEmail: ticket.leaderEmail,
      leaderPhone: ticket.leaderPhone,
      participants: [
        BookingParticipant(
          name: ticket.leaderName,
          ticketTypeId: 0,
          ticketTypeName: 'Tiket',
          ticketPrice: 0,
        ),
        for (final member in ticket.memberNames)
          BookingParticipant(
            name: member,
            ticketTypeId: 0,
            ticketTypeName: 'Tiket',
            ticketPrice: 0,
          ),
      ],
      status: ticket.bookingStatus,
      paymentDeadline: ticket.paymentDeadline,
    );
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PaymentPage(
          booking: booking,
          destination: Destination(
            id: ticket.destinationId,
            name: ticket.destinationName,
            location: ticket.destinationLocation,
            latitude: 0,
            longitude: 0,
            routeDistanceKm: 0,
            imageUrl: ticket.destinationImageUrl,
          ),
        ),
      ),
    );
    if (context.mounted) await onPaymentReturned();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ticketBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809233F),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.destinationName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ticketNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Jember',
                      style: const TextStyle(
                        color: _ticketSecondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(
                label: _ticketStatusLabel(ticket, selectedTab),
                background: _ticketStatusBackground(ticket),
                foreground: _ticketStatusForeground(ticket),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _ticketBackground,
              borderRadius: BorderRadius.circular(12),
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
                  label: 'Total pesanan',
                  value: _formatPrice(ticket.amountPaid),
                  detail:
                      '${ticket.quantity} tiket · ${_paymentStatusLabel(ticket.paymentStatus)}',
                  alignEnd: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kode ${ticket.bookingId}',
                  style: const TextStyle(
                    color: _ticketSecondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                ticket.paymentMethod.toUpperCase() == 'CASH'
                    ? 'Tunai di tempat'
                    : 'Payment Gateway',
                style: const TextStyle(
                  color: _ticketSecondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (ticket.canOpenEticket)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => QrTicketPage(ticket: ticket),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ticketNavy,
                      side: const BorderSide(color: _ticketBorder),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'E-ticket',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                )
              else if (ticket.canPay)
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openPayment(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ticketNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bayar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              if (ticket.canOpenEticket && _canManageTrip) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openManageTrip(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ticketNavy,
                      side: const BorderSide(color: _ticketBorder),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets({
    required this.selectedTab,
    required this.requiresLogin,
    required this.onExplore,
    required this.onLogin,
  });

  final int selectedTab;
  final bool requiresLogin;
  final VoidCallback onExplore;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final title = requiresLogin
        ? 'Login terlebih dahulu'
        : switch (selectedTab) {
            0 => 'Belum ada tiket aktif',
            1 => 'Belum ada riwayat tiket',
            _ => 'Belum ada pesanan',
          };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              requiresLogin
                  ? Icons.lock_outline_rounded
                  : selectedTab == 1
                  ? Icons.history_rounded
                  : Icons.confirmation_number_outlined,
              color: const Color(0xFF9AA6B6),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: _ticketNavy,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              requiresLogin
                  ? 'login untuk memulai perjalananmu.'
                  : 'Yuk pesan tiket untuk memulai perjalananmu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7890A1), fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: requiresLogin ? onLogin : onExplore,
              child: Text(requiresLogin ? 'Login sekarang' : 'pesan tiket sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

String _ticketStatusLabel(Ticket ticket, int selectedTab) {
  if (ticket.hasUsedTicket || ticket.status == 'used') {
    return 'Sudah digunakan';
  }
  if (!ticket.hasIssuedTicket && ticket.status == 'expired') {
    return 'Gagal';
  }
  if (ticket.hasExpiredTicket || ticket.status == 'expired') {
    return 'Kadaluarsa';
  }
  if (selectedTab == 1 && ticket.status == 'partial') {
    return 'Sebagian digunakan';
  }

  switch (ticket.bookingStatus) {
    case 'PAID':
      return 'Lunas';
    case 'PENDING':
      return 'Menunggu pembayaran';
    case 'EXPIRED':
      return 'Kadaluarsa';
    case 'FAILED':
      return 'Gagal';
    default:
      return 'Belum diproses';
  }
}

String _paymentStatusLabel(String status) => switch (status) {
  'PAID' => 'Lunas',
  'PENDING' => 'Menunggu pembayaran',
  'FAILED' => 'Gagal',
  'EXPIRED' => 'Kadaluarsa',
  _ => 'Belum dibayar',
};

Color _ticketStatusBackground(Ticket ticket) {
  switch (ticket.status) {
    case 'used':
      return const Color(0xFFEAF3EE);
    case 'valid':
      return const Color(0xFFFFF3E2);
    case 'pending':
    case 'failed':
    case 'expired':
      return const Color(0xFFFFEDEE);
    case 'partial':
      return const Color(0xFFEAF2F8);
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
    case 'pending':
    case 'failed':
    case 'expired':
      return const Color(0xFF9B303A);
    case 'partial':
      return const Color(0xFF1D4E89);
    default:
      return const Color(0xFF1D4E89);
  }
}

String _formatPrice(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
