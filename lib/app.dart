import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'presentation/pages/auth/login_page.dart';

class PariwisataApp extends StatelessWidget {
  const PariwisataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JemberGo',
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        fontFamily: 'Arial',
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.field,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.blue, width: 2),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
