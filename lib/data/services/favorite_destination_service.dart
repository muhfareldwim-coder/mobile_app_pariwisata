import 'package:flutter/foundation.dart';

import '../models/destination.dart';
import 'auth_service.dart';

class FavoriteDestinationService {
  static final ValueNotifier<int> revision = ValueNotifier(0);
  static final Map<String, Map<String, Destination>> _favorites = {};

  static String get _ownerId => AuthService.currentUser?.id ?? 'guest';

  static Set<String> get destinationIds =>
      Set.unmodifiable(_favorites[_ownerId]?.keys ?? const <String>[]);

  static List<Destination> get destinations =>
      List.unmodifiable(_favorites[_ownerId]?.values ?? const <Destination>[]);

  static bool contains(String destinationId) =>
      _favorites[_ownerId]?.containsKey(destinationId) ?? false;

  static bool toggle(Destination destination) {
    final favorites = _favorites.putIfAbsent(_ownerId, () => {});
    if (favorites.remove(destination.id) == null) {
      favorites[destination.id] = destination;
    }
    revision.value++;
    return favorites.containsKey(destination.id);
  }
}
