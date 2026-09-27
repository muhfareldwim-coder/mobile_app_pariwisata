import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.explore_outlined, 'Eksplor'),
    (Icons.confirmation_number_outlined, 'Tiket'),
    (Icons.person_outline, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1208233F),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[index].$1,
                          size: 21,
                          color: selectedIndex == index
                              ? AppColors.orange
                              : const Color(0xFF9AA5B1),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[index].$2,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: selectedIndex == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedIndex == index
                                ? AppColors.navy
                                : const Color(0xFF9AA5B1),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 13,
                          height: 2,
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? AppColors.orange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
