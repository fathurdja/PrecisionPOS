import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Defines a single navigation tab with its icon, label, and the
/// logical screen key used by [MainShell] to decide which body to show.
class NavItem {
  final IconData icon;
  final String label;
  final String key; // e.g. 'sales', 'order', 'history', 'reports', 'settings', 'delivery'

  const NavItem({required this.icon, required this.label, required this.key});
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String userRole;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  });

  /// Returns the visible tabs based on the active user role.
  /// ─────────────────────────────────────────────────────
  /// admin   → Sales, History, Reports, Settings
  /// kasir   → Order, Reports
  /// delivery → Delivery  (single tab)
  /// ─────────────────────────────────────────────────────
  static List<NavItem> getTabsForRole(String role) {
    switch (role) {
      case 'kasir':
        return const [
          NavItem(icon: Icons.point_of_sale, label: 'Order', key: 'order'),
          NavItem(icon: Icons.analytics_outlined, label: 'Reports', key: 'reports'),
        ];
      case 'delivery':
        return const [
          NavItem(icon: Icons.delivery_dining, label: 'Delivery', key: 'delivery'),
        ];
      case 'admin':
      default:
        return const [
          NavItem(icon: Icons.point_of_sale, label: 'Sales', key: 'sales'),
          NavItem(icon: Icons.history, label: 'History', key: 'history'),
          NavItem(icon: Icons.analytics_outlined, label: 'Reports', key: 'reports'),
          NavItem(icon: Icons.settings_outlined, label: 'Settings', key: 'settings'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = getTabsForRole(userRole);

    // If only a single tab, hide the bottom nav entirely
    if (tabs.length <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              return _buildNavItem(index, tabs[index].icon, tabs[index].label);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.emeraldActive : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
