import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../repositories/transaction_repository.dart';
import 'payment_success_screen.dart';
import '../utils/currency_format.dart';

class BonKreditScreen extends StatefulWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;

  const BonKreditScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  State<BonKreditScreen> createState() => _BonKreditScreenState();
}

class _BonKreditScreenState extends State<BonKreditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setDueDays(int days) {
    setState(() {
      _dueDate = DateTime.now().add(Duration(days: days));
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = TransactionRepository();
    
    // Create new transaction with updated status for credit
    final bonTxn = TransactionModel(
      receiptId: widget.transaction.receiptId,
      tanggal: widget.transaction.tanggal,
      totalHarga: widget.transaction.totalHarga,
      status: 'Bon · Belum Lunas',
    );

    await repo.saveTransaction(bonTxn, widget.items);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transaction: bonTxn,
            items: widget.items,
            method: 'Bon',
            dueDate: _formatDate(_dueDate),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Catat Bon / Piutang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF1E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'BON',
                style: TextStyle(color: Color(0xFFB07000), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWarningBanner(),
                const SizedBox(height: 24),
                _buildTotalCard(),
                const SizedBox(height: 24),
                _buildCustomerForm(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _saveInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Simpan & Cetak Bon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB07000), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Transaksi ini akan dicatat sebagai piutang. Pembayaran belum diterima.',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFFB07000).withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Tagihan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            CurrencyFormat.idr(widget.transaction.totalHarga),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATA PELANGGAN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          validator: (value) => (value == null || value.trim().length < 2) ? 'Nama diperlukan' : null,
          decoration: _inputDecoration('Nama Pelanggan (Wajib)'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('No. Telepon (Opsional)'),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'JATUH TEMPO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_dueDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _dueShortcutBtn(7, '7 Hari'),
            const SizedBox(width: 8),
            _dueShortcutBtn(14, '14 Hari'),
            const SizedBox(width: 8),
            _dueShortcutBtn(30, '30 Hari'),
          ],
        ),
        
        const SizedBox(height: 24),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: _inputDecoration('Catatan Tambahan (Opsional)'),
        ),
      ],
    );
  }

  Widget _dueShortcutBtn(int days, String label) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _setDueDays(days),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
