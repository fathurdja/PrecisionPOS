import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';

class ReceiptTemplateSettingScreen extends StatefulWidget {
  const ReceiptTemplateSettingScreen({super.key});

  @override
  State<ReceiptTemplateSettingScreen> createState() => _ReceiptTemplateSettingScreenState();
}

class _ReceiptTemplateSettingScreenState extends State<ReceiptTemplateSettingScreen> {
  String _selectedTemplate = 'classic';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplateSetting();
  }

  Future<void> _loadTemplateSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTemplate = prefs.getString('receipt_template') ?? 'classic';
      _isLoading = false;
    });
  }

  Future<void> _selectTemplate(String templateId) async {
    setState(() {
      _selectedTemplate = templateId;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receipt_template', templateId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt template set to ${templateId.toUpperCase()}!'),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Receipt Templates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'CHOOSE RECEIPT STYLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTemplateCard(
                      id: 'classic',
                      title: 'Classic / Thermal',
                      description: 'Traditional monochrome layout. Perfect for standard 80mm roll printers.',
                      previewWidget: _buildClassicPreview(),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTemplateCard(
                      id: 'modern',
                      title: 'Modern / Premium',
                      description: 'Sleek dark blue design with elegant layout structure and clear divisions.',
                      previewWidget: _buildModernPreview(),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTemplateCard(
                      id: 'eco',
                      title: 'Eco / Nature',
                      description: 'Growth green theme featuring a leaf icon and organic styling elements.',
                      previewWidget: _buildEcoPreview(),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTemplateCard({
    required String id,
    required String title,
    required String description,
    required Widget previewWidget,
  }) {
    final isSelected = _selectedTemplate == id;

    return GestureDetector(
      onTap: () => _selectTemplate(id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.01),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primary : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  ),
                ],
              ),
            ),
            
            // Visual mockup widget
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
                ),
                child: previewWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicPreview() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'PRECISION BREW',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
        ),
        Center(
          child: Text(
            'RCPT #00129 • Monospace Style',
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black54),
          ),
        ),
        SizedBox(height: 8),
        Text('--------------------------------', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black38)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('2x Kopi Susu', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87)),
            Text('Rp 30.000', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87)),
          ],
        ),
        Text('--------------------------------', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black38)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GRAND TOTAL', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
            Text('Rp 32.400', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Thank you for your purchase!',
            style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildModernPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.coffee, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRECISION BREW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primary)),
                Text('Sleek Premium Receipt', style: TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('2x Kopi Susu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
            Text('Rp 30.000', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: AppColors.primaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAND TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('Rp 32.400', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.eco, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRECISION BREW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.secondary)),
                Text('Eco-Friendly Receipt', style: TextStyle(fontSize: 9, color: AppColors.onSecondaryFixedVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.secondary.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('2x Kopi Susu', style: TextStyle(fontSize: 10, color: AppColors.onSurface)),
            Text('Rp 30.000', style: TextStyle(fontSize: 10, color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: AppColors.secondary.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GRAND TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
            Text('Rp 32.400', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 10),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forest_outlined, size: 10, color: AppColors.secondary),
              SizedBox(width: 4),
              Text('Save paper, save trees!', style: TextStyle(fontSize: 9, color: AppColors.secondary, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }
}
