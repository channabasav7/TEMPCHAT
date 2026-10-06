import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../chat/chat_list_screen.dart';
import '../connections/connections_screen.dart';
import '../qr/my_qr_screen.dart';
import '../qr/scan_qr_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ChatListScreen(onNavigateToTab: _onTabSelected),
      const MyQrScreen(),
      const ScanQrScreen(),
      const ConnectionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.chat_bubble_outline, 'Chats'),
            _buildNavItem(1, Icons.qr_code_2_outlined, 'My QR'),
            _buildNavItem(2, Icons.qr_code_scanner_outlined, 'Scan'),
            _buildNavItem(3, Icons.people_outline, 'Connections'),
            _buildNavItem(4, Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.white : AppColors.dim;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryOrange : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
