import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = 'JemberGo';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb
        ? 'http://localhost:8000/api/v1'
        : 'http://192.168.1.4:8000/api/v1',
  );

  const AppConstants._();
}
