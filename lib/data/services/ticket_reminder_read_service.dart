import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ticket_reminder.dart';

class TicketReminderReadService {
  static const _storageKeyPrefix = 'jembergo_ticket_reminder_read_';
  static final ValueNotifier<int> revision = ValueNotifier(0);
  static Set<String> _readReminderIds = {};
  static String? _customerId;
  static bool _isLoaded = false;
  static int _loadGeneration = 0;

  static bool isLoadedFor(String customerId) =>
      _customerId == customerId && _isLoaded;

  static bool isRead(String customerId, TicketReminder reminder) =>
      isLoadedFor(customerId) && _readReminderIds.contains(reminder.id);

  static bool hasUnread(String customerId, Iterable<TicketReminder> reminders) {
    if (!isLoadedFor(customerId)) {
      return false;
    }

    return reminders.any((reminder) => !_readReminderIds.contains(reminder.id));
  }

  static Future<void> loadForCustomer(String customerId) async {
    if (isLoadedFor(customerId)) {
      return;
    }

    final generation = ++_loadGeneration;
    _customerId = customerId;
    _readReminderIds = {};
    _isLoaded = false;
    revision.value++;

    final preferences = await SharedPreferences.getInstance();
    final savedReminderIds =
        preferences.getStringList('$_storageKeyPrefix$customerId') ?? [];
    if (generation != _loadGeneration) {
      return;
    }

    _readReminderIds = savedReminderIds.toSet();
    _isLoaded = true;
    revision.value++;
  }

  static void clearCurrentCustomer() {
    _loadGeneration++;
    _customerId = null;
    _readReminderIds = {};
    _isLoaded = false;
    revision.value++;
  }

  static Future<void> markAllRead(
    String customerId,
    Iterable<TicketReminder> reminders,
  ) async {
    if (!isLoadedFor(customerId)) {
      await loadForCustomer(customerId);
    }
    if (!isLoadedFor(customerId)) {
      throw StateError('Status baca notifikasi tidak berhasil dimuat.');
    }

    final updatedReminderIds = {..._readReminderIds};
    updatedReminderIds.addAll(reminders.map((reminder) => reminder.id));
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      '$_storageKeyPrefix$customerId',
      updatedReminderIds.toList()..sort(),
    );
    if (!saved) {
      throw StateError('Status baca notifikasi gagal disimpan.');
    }

    if (isLoadedFor(customerId)) {
      _readReminderIds = updatedReminderIds;
      revision.value++;
    }
  }
}
