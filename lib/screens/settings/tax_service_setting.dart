import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_format.dart';

class TaxServiceSettingScreen extends StatefulWidget {
  const TaxServiceSettingScreen({super.key});

  @override
  State<TaxServiceSettingScreen> createState() => _TaxServiceSettingScreenState();
}

class _TaxServiceSettingScreenState extends State<TaxServiceSettingScreen> {
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _taxRate = 8.0;
  double _serviceRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _taxController.addListener(_updatePreviewFromControllers);
    _serviceController.addListener(_updatePreviewFromControllers);
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _taxRate = prefs.getDouble('tax_rate') ?? 8.0;
      _serviceRate = prefs.getDouble('service_rate') ?? 0.0;
      _taxController.text = _taxRate.toStringAsFixed(_taxRate % 1 == 0 ? 0 : 1);
      _serviceController.text = _serviceRate.toStringAsFixed(_serviceRate % 1 == 0 ? 0 : 1);
      _isLoading = false;
    });
  }

  void _updatePreviewFromControllers() {
    final taxVal = double.tryParse(_taxController.text) ?? 0.0;
    final serviceVal = double.tryParse(_serviceController.text) ?? 0.0;
    setState(() {
      _taxRate = taxVal;
      _serviceRate = serviceVal;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tax_rate', _taxRate);
    await prefs.setDouble('service_rate', _serviceRate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tax & Service rates saved successfully!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double mockSubtotal = 100000.0;
    final double serviceChargeVal = mockSubtotal * (_serviceRate / 100);
    final double taxVal = (mockSubtotal + serviceChargeVal) * (_taxRate / 100);
    final double grandTotalVal = mockSubtotal + serviceChargeVal + taxVal;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Tax & Service Charge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Interactive preview card
                      const Text(
                        'LIVE PREVIEW',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'SAMPLE RECEIPT PREVIEW',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Regular Item x2', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                Text(CurrencyFormat.idr(mockSubtotal), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, thickness: 1),
                            const SizedBox(height: 12),
                            _buildPreviewRow('Subtotal', CurrencyFormat.idr(mockSubtotal)),
                            const SizedBox(height: 6),
                            _buildPreviewRow(
                              'Service Charge (${_serviceRate.toStringAsFixed(_serviceRate % 1 == 0 ? 0 : 1)}%)',
                              CurrencyFormat.idr(serviceChargeVal),
                            ),
                            const SizedBox(height: 6),
                            _buildPreviewRow(
                              'Tax (${_taxRate.toStringAsFixed(_taxRate % 1 == 0 ? 0 : 1)}%)',
                              CurrencyFormat.idr(taxVal),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, thickness: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'GRAND TOTAL',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                                Text(
                                  CurrencyFormat.idr(grandTotalVal),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input section
                      const Text(
                        'CONFIGURE RATES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter tax rate';
                                final val = double.tryParse(value);
                                if (val == null || val < 0 || val > 100) return 'Enter a value between 0% and 100%';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Government Tax (%)',
                                suffixIcon: const Icon(Icons.percent, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _serviceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter service charge';
                                final val = double.tryParse(value);
                                if (val == null || val < 0 || val > 100) return 'Enter a value between 0% and 100%';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Service Charge (%)',
                                suffixIcon: const Icon(Icons.room_service_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPreviewRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        Text(val, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
