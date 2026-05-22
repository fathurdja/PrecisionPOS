import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_config.dart';

class AppTopBar extends StatelessWidget {
  final String? trailingText;
  final String? profileImageUrl;

  const AppTopBar({
    super.key,
    this.trailingText,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Precision POS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (trailingText != null) ...[
                  Text(
                    trailingText!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // User avatar with role badge & logout popup
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await ApiConfig.clearAuth();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('user_name');
                      await prefs.remove('store_name');
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    }
                  },
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snap) {
                          final name = snap.data?.getString('user_name') ?? '...';
                          final role = snap.data?.getString('user_role') ?? '';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                              Text(role.toUpperCase(), style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
                            ],
                          );
                        },
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHighest,
                    ),
                    child: ClipOval(
                      child: Icon(
                        Icons.person,
                        color: AppColors.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
