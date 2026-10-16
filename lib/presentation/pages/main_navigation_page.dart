import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/bottom_navigation.dart';
import 'destination/explorer_page.dart';
import 'home/home_page.dart';
import 'map/map_page.dart';
import 'profile/profile_page.dart';
import 'ticket/my_ticket_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
    this.locationProvider,
  });

  final int initialIndex;
  final Future<LatLng?> Function()? locationProvider;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _selectedIndex = widget.initialIndex;
  String _explorerCategory = 'Semua';

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _selectExplorerCategory(String category) {
    setState(() {
      _explorerCategory = category;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            onTabSelected: _selectTab,
            onCategorySelected: _selectExplorerCategory,
            locationProvider: widget.locationProvider,
          ),
          ExplorerPage(
            key: ValueKey(_explorerCategory),
            initialCategory: _explorerCategory,
          ),
          const MapPage(),
          MyTicketPage(
            isSelected: _selectedIndex == 3,
            onProfileTap: () => _selectTab(4),
          ),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
      ),
    );
  }
}
