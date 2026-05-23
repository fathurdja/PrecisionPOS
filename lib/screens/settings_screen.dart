import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../services/bluetooth_printer_service.dart';
import 'settings/tax_service_setting.dart';
import 'settings/receipt_template_setting.dart';
import 'settings/staff_management_screen.dart';
import 'settings/store_information_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {


  Future<void> _showPrinterSetupDialog() async {
    try {
      final printerService = BluetoothPrinterService();
      bool isEnabled = await printerService.isBluetoothEnabled;
      if (!isEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tolong nyalakan Bluetooth terlebih dahulu.')));
        }
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Pilih Printer Bluetooth'),
            content: FutureBuilder(
              future: printerService.getPairedDevices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Tidak ada perangkat Bluetooth ter-pairing ditemukan. Error: ${snapshot.error ?? "Kosong"}');
                }
                final devices = snapshot.data!;
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(device.name),
                        subtitle: Text(device.macAdress),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('printer_mac', device.macAdress);
                          await prefs.setString('printer_name', device.name);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Printer disetel ke ${device.name}. Mencoba koneksi...'),
                            ));
                          }
                          
                          try {
                            bool connected = await printerService.connect(device.macAdress);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(connected ? 'Berhasil terhubung ke ${device.name}!' : 'Gagal terhubung.'),
                                backgroundColor: connected ? AppColors.secondary : Colors.red,
                              ));
                            }
                          } catch (e) {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koneksi Error: $e')));
                             }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e\n\nTip: Hentikan aplikasi (Stop) lalu jalankan ulang (Run) karena kita baru saja menginstal library Bluetooth.'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

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
                const Text(
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
                  _SettingsItem(Icons.person_outline, 'Profile', 'Manage your account details', null),
                  _SettingsItem(Icons.store, 'Store Information', 'Business name, address, logo', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoreInformationScreen()),
                    );
                  }),
                  _SettingsItem(Icons.group_outlined, 'Staff Management', 'Add or remove team members', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StaffManagementScreen()),
                    );
                  }),
                ]),
                const SizedBox(height: 24),
                _buildSettingsGroup('Preferences', [
                  _SettingsItem(Icons.receipt_long, 'Receipt Template', 'Customize receipt layout', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReceiptTemplateSettingScreen()),
                    );
                  }),
                  _SettingsItem(Icons.percent, 'Tax & Service', 'Configure tax rates', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TaxServiceSettingScreen()),
                    );
                  }),
                  _SettingsItem(Icons.notifications_outlined, 'Notifications', 'Alert preferences', null),
                ]),
                const SizedBox(height: 24),
                _buildSettingsGroup('System', [
                  _SettingsItem(Icons.sync, 'Data Sync', 'Cloud & backup settings', null),
                  _SettingsItem(Icons.print_outlined, 'Printer Setup', 'Connect receipt printers', _showPrinterSetupDialog),
                  _SettingsItem(Icons.info_outline, 'About', 'Version & legal information', null),
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
                    onTap: item.onTap,
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
  final VoidCallback? onTap;

  _SettingsItem(this.icon, this.title, this.subtitle, this.onTap);
}

