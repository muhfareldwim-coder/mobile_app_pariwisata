import 'package:flutter/material.dart';

import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/main_navigation_page.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    forgotPassword: (_) => const ForgotPasswordPage(),
    home: (_) => const MainNavigationPage(),
  };

  const AppRoutes._();
}
