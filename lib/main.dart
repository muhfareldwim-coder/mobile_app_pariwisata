import 'package:flutter/material.dart';

import 'app.dart';
import 'data/services/auth_service.dart';
import 'data/services/language_preference_service.dart';

export 'app.dart';
export 'presentation/pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.restoreSession();
  await LanguagePreferenceService.restore();
  runApp(const PariwisataApp());
}
