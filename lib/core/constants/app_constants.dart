import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = 'JemberGo';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jembergo.my.id/api/v1',
  );

  const AppConstants._();
}
