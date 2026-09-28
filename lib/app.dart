import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'data/models/destination.dart';
import 'presentation/pages/booking/booking_page.dart';

class PariwisataApp extends StatelessWidget {
  const PariwisataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JemberGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blueDeep,
          primary: AppColors.blueDeep,
          secondary: AppColors.orange,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: AppColors.muted),
          hintStyle: const TextStyle(color: AppColors.muted),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.blueDeep, width: 1.4),
          ),
        ),
      ),
      home: const BookingPage(
        destination: Destination(
          id: 'papuma',
          name: 'Pantai Tanjung Papuma',
          location: 'Jember, Jawa Timur',
          ticketPrice: 25000,
        ),
      ),
    );
  }
}
