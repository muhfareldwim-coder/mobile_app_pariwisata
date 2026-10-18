import 'package:flutter/material.dart';
import 'package:curved_navigation_bar_pro/curved_navigation_bar_pro.dart';

import '../../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <CurvedNavigationItemPro>[
    CurvedNavigationItemPro(
      inactiveIcon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    CurvedNavigationItemPro(
      inactiveIcon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Jelajah',
    ),
    CurvedNavigationItemPro(
      inactiveIcon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Peta',
    ),
    CurvedNavigationItemPro(
      inactiveIcon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      label: 'Tiket',
    ),
    CurvedNavigationItemPro(
      inactiveIcon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBarPro(
      items: _items,
      currentIndex: selectedIndex,
      onTap: onSelected,
      backgroundColor: Colors.white,
      activeColor: AppColors.orange,
      activeIconColor: Colors.white,
      inactiveColor: const Color(0xFF8190A5),
      fabColor: AppColors.orange,
      barHeight: 72,
      fabRadius: 28,
      fabGap: 8,
      fabSink: 18,
      notchShoulderRadius: 12,
      cornerRadius: 22,
      contentPadding: 14,
      elevation: 12,
      shadowColor: const Color(0x1A08233F),
      animationDuration: const Duration(milliseconds: 400),
      animationCurve: Curves.easeInOutCubic,
      activeTextStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
      inactiveTextStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8190A5),
      ),
      inactiveIconSize: 21,
      activeIconSize: 23,
      useSafeArea: true,
    );
  }
}
