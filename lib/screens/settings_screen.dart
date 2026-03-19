import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSettingsGroup('Account', [
                  _SettingsItem(Icons.person_outline, 'Profile', 'Manage your account details'),
                  _SettingsItem(Icons.store, 'Store Information', 'Business name, address, tax ID'),
                  _SettingsItem(Icons.group_outlined, 'Staff Management', 'Add or remove team members'),
                ]),
                const SizedBox(height: 24),
                _buildSettingsGroup('Preferences', [
                  _SettingsItem(Icons.receipt_long, 'Receipt Template', 'Customize receipt layout'),
                  _SettingsItem(Icons.percent, 'Tax & Service', 'Configure tax rates'),
                  _SettingsItem(Icons.notifications_outlined, 'Notifications', 'Alert preferences'),
                ]),
                const SizedBox(height: 24),
                _buildSettingsGroup('System', [
                  _SettingsItem(Icons.sync, 'Data Sync', 'Cloud & backup settings'),
                  _SettingsItem(Icons.print_outlined, 'Printer Setup', 'Connect receipt printers'),
                  _SettingsItem(Icons.info_outline, 'About', 'Version & legal information'),
                ]),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: AppColors.primary, size: 22),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _SettingsItem(this.icon, this.title, this.subtitle);
}
