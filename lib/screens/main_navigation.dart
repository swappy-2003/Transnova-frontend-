import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'activity/activity_screen.dart';
import 'buy/buy_screen.dart';
import 'cashout/cashout_screen.dart';
import 'home/home_screen.dart';
import 'scan/scan_qr_screen.dart';
import 'send/send_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final ValueNotifier<String?> _scannedRecipientNotifier = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _scannedRecipientNotifier.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _openQrScanner() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;
    _scannedRecipientNotifier.value = scanned;
    _onTabTapped(1); // Switch to Transfer screen with pre-filled recipient
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onCustomTap,
  }) {
    final isSelected = onCustomTap == null && _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onCustomTap ?? () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppTheme.brandBlack : AppTheme.darkSurfaceVariantText,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.uiStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.brandBlack : AppTheme.darkSurfaceVariantText,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateTab: _onTabTapped,
        onScanQr: _openQrScanner,
      ),
      SendScreen(
        onTransferSuccess: () => _onTabTapped(4),
        scannedRecipientNotifier: _scannedRecipientNotifier,
      ), // 1: Transfer
      BuyScreen(onDepositSuccess: () => _onTabTapped(0)), // 2: Top Up
      CashoutScreen(onCashoutSuccess: () => _onTabTapped(4)), // 3: Cash out
      const ActivityScreen(), // 4: History / Activity
      const SettingsScreen(), // 5: Profile / Settings
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.brandBlack,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Activity',
                index: 4,
              ),
              _buildNavItem(
                icon: Icons.qr_code_scanner_rounded,
                activeIcon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                index: -1,
                onCustomTap: _openQrScanner,
              ),
              _buildNavItem(
                icon: Icons.send_outlined,
                activeIcon: Icons.send_rounded,
                label: 'Transfer',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
