import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../data/models/ticket_reminder.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/language_preference_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../../data/services/ticket_reminder_read_service.dart';

const _notificationNavy = Color(0xFF12304A);
const _notificationBackground = Color(0xFFF6F8FB);
const _notificationSecondary = Color(0xFF8190A5);
const _notificationIconBackground = Color(0xFFF4F7FA);
const _expiredIconBackground = Color(0xFFFFF1F0);
const _expiredIconColor = Color(0xFFC91F1F);

class TicketNotificationsPage extends StatefulWidget {
  const TicketNotificationsPage({super.key, this.ticketService});

  final TicketService? ticketService;

  @override
  State<TicketNotificationsPage> createState() =>
      _TicketNotificationsPageState();
}

class _TicketNotificationsPageState extends State<TicketNotificationsPage> {
  bool _isLoading = AuthService.currentUser != null;
  bool _isMarkingRead = false;
  String? _loadError;

  TicketService get _ticketService => widget.ticketService ?? TicketService();

  @override
  void initState() {
    super.initState();
    if (AuthService.currentUser != null) {
      unawaited(_loadTickets());
    }
  }

  Future<void> _loadTickets() async {
    final customerId = AuthService.currentUser?.id;
    if (customerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await TicketReminderReadService.loadForCustomer(customerId);
      await _ticketService.refreshFromServer(expectedCustomerId: customerId);
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } on Exception catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMarkAsReadError(Object error) {
    final isEnglish =
        LanguagePreferenceService.locale.value.languageCode == 'en';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${isEnglish ? 'Could not mark notifications as read' : 'Notifikasi gagal ditandai dibaca'}: $error',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markAllRead(Iterable<TicketReminder> reminders) async {
    final customerId = AuthService.currentUser?.id;
    if (customerId == null) {
      return;
    }

    setState(() => _isMarkingRead = true);
    try {
      await TicketReminderReadService.markAllRead(customerId, reminders);
    } on StateError catch (error) {
      if (!mounted) return;
      _showMarkAsReadError(error);
    } on Exception catch (error) {
      if (!mounted) return;
      _showMarkAsReadError(error);
    } finally {
      if (mounted) setState(() => _isMarkingRead = false);
    }
  }

  Future<void> _openLogin() async {
    await Navigator.pushNamed(context, AppRoutes.login);
    if (mounted && AuthService.currentUser != null) {
      await _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _notificationBackground,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: _notificationNavy,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: TicketService.revision,
        builder: (context, _, _) => ValueListenableBuilder<int>(
          valueListenable: TicketReminderReadService.revision,
          builder: (context, _, _) {
            final reminders = TicketReminder.fromTickets(TicketService.tickets);
            final customerId = AuthService.currentUser?.id;
            final isSignedIn = customerId != null;
            final isReadStateLoaded =
                customerId != null &&
                TicketReminderReadService.isLoadedFor(customerId);
            final unreadReminders = <TicketReminder>[];
            if (customerId != null && isReadStateLoaded) {
              unreadReminders.addAll(
                reminders.where(
                  (reminder) =>
                      !TicketReminderReadService.isRead(customerId, reminder),
                ),
              );
            }
            final isCenteredState =
                !isSignedIn ||
                (reminders.isEmpty && !_isLoading && _loadError == null);
            return LayoutBuilder(
              builder: (context, constraints) => RefreshIndicator(
                onRefresh: _loadTickets,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: isCenteredState
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (unreadReminders.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _isMarkingRead
                                    ? null
                                    : () => _markAllRead(unreadReminders),
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text('Tandai dibaca'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _notificationNavy,
                                  backgroundColor: _notificationIconBackground,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (_isLoading) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 16),
                          ],
                          if (_loadError != null) ...[
                            _LoadError(
                              message: _loadError!,
                              onRetry: _loadTickets,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (!isSignedIn)
                            _SignInPrompt(onSignIn: _openLogin)
                          else if (reminders.isEmpty &&
                              !_isLoading &&
                              _loadError == null)
                            const _EmptyReminders()
                          else
                            for (final reminder in reminders) ...[
                              _ReminderCard(reminder: reminder),
                              const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder});

  final TicketReminder reminder;

  @override
  Widget build(BuildContext context) {
    final isToday = reminder.timing == TicketReminderTiming.visitToday;
    final isExpired = reminder.timing == TicketReminderTiming.expiredToday;
    final ticket = reminder.ticket;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isExpired
                  ? _expiredIconBackground
                  : _notificationIconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.confirmation_num_outlined,
              color: isExpired ? _expiredIconColor : _notificationNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Tiket sudah kedaluwarsa'
                      : isToday
                      ? 'Tiket kunjungan hari ini'
                      : 'Pengingat H-1 tiket',
                  style: const TextStyle(
                    color: _notificationNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                ValueListenableBuilder<Locale>(
                  valueListenable: LanguagePreferenceService.locale,
                  builder: (context, locale, _) => Text(
                    locale.languageCode == 'en'
                        ? isExpired
                              ? 'Your ticket for ${ticket.destinationName} has expired because the destination is closed.'
                              : isToday
                              ? 'You have a ticket for ${ticket.destinationName} today. Use it before it expires.'
                              : 'Tomorrow you have a ticket for ${ticket.destinationName}. Get your ticket ready to use.'
                        : isExpired
                        ? 'Tiket kunjunganmu ke ${ticket.destinationName} hari ini sudah kedaluwarsa karena jam operasional destinasi telah berakhir.'
                        : isToday
                        ? 'Kamu punya tiket untuk ${ticket.destinationName} hari ini. Gunakan sebelum kedaluwarsa.'
                        : 'Besok kamu memiliki tiket untuk ${ticket.destinationName}. Siapkan tiketmu untuk digunakan.',
                    style: const TextStyle(
                      color: _notificationSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  formatIndonesianDate(ticket.visitDate),
                  style: const TextStyle(
                    color: _notificationNavy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ValueListenableBuilder<Locale>(
                  valueListenable: LanguagePreferenceService.locale,
                  builder: (context, locale, _) => Text(
                    '${locale.languageCode == 'en' ? 'Booking code' : 'Kode booking'}: ${ticket.bookingId}',
                    style: const TextStyle(
                      color: _notificationSecondary,
                      fontSize: 10,
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

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Column(
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          color: _notificationSecondary,
          size: 48,
        ),
        const SizedBox(height: 12),
        const Text(
          'Belum ada pengingat tiket',
          style: TextStyle(
            color: _notificationNavy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
      ],
    ),
  );
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Column(
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: _notificationSecondary,
          size: 44,
        ),
        const SizedBox(height: 12),
        const Text(
          'Masuk untuk melihat pengingat tiket',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _notificationNavy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onSignIn,
          style: FilledButton.styleFrom(backgroundColor: _notificationNavy),
          child: const Text('Login sekarang'),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F0),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<Locale>(
          valueListenable: LanguagePreferenceService.locale,
          builder: (context, locale, _) => Text(
            '${locale.languageCode == 'en' ? 'Could not load reminders' : 'Pengingat gagal dimuat'}: $message',
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    ),
  );
}
