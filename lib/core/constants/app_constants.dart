import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = 'JemberGo';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb
        ? 'http://localhost:8000/api/v1'
        : 'http://10.0.2.2:8000/api/v1',
  );

  const AppConstants._();
}
