import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../repositories/transaction_repository.dart';
import 'payment_success_screen.dart';
import '../utils/currency_format.dart';

class CashEntryScreen extends StatefulWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;

  const CashEntryScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  State<CashEntryScreen> createState() => _CashEntryScreenState();
}

class _CashEntryScreenState extends State<CashEntryScreen> {
  final TextEditingController _amountController = TextEditingController(text: '0');
  double _receivedAmount = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {
      _receivedAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    _amountController.text = amount.toInt().toString();
  }

  Future<void> _confirmPayment() async {
    if (_receivedAmount < widget.transaction.totalHarga) return;

    // Save transaction
    final repo = TransactionRepository();
    
    // Create new transaction with updated status
    final completedTxn = TransactionModel(
      receiptId: widget.transaction.receiptId,
      tanggal: widget.transaction.tanggal,
      totalHarga: widget.transaction.totalHarga,
      status: 'Completed',
    );

    await repo.saveTransaction(completedTxn, widget.items);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transaction: completedTxn,
            items: widget.items,
            method: 'Cash',
            receivedAmount: _receivedAmount,
            changeAmount: _receivedAmount - widget.transaction.totalHarga,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double change = _receivedAmount - widget.transaction.totalHarga;
    final bool canConfirm = _receivedAmount >= widget.transaction.totalHarga;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Pembayaran Tunai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'CASH',
                style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalDisplay(),
              const SizedBox(height: 24),
              _buildQuickAmounts(),
              const SizedBox(height: 24),
              _buildInputArea(),
              const SizedBox(height: 24),
              _buildChangeDisplay(change, canConfirm),
            ],
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
          onPressed: canConfirm ? _confirmPayment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceContainerHighest,
            disabledForegroundColor: AppColors.outline,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.check),
          label: const Text('Konfirmasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTotalDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'TOTAL TAGIHAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormat.idr(widget.transaction.totalHarga),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOMINAL YANG DITERIMA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onTap: () {
            if (_amountController.text == '0') {
              _amountController.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    return Row(
      children: [
        Expanded(
          child: _quickAmountButton(50000),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAmountButton(100000),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAmountButton(widget.transaction.totalHarga, label: 'Uang Pas'),
        ),
      ],
    );
  }

  Widget _quickAmountButton(double amount, {String? label}) {
    return InkWell(
      onTap: () => _setAmount(amount),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label ?? 'Rp ${(amount / 1000).toInt()}k',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildChangeDisplay(double change, bool canConfirm) {
    if (!canConfirm) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text(
              'KURANG: Rp ${change.abs().toInt()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KEMBALIAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.secondary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormat.idr(change),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const Icon(Icons.receipt, color: Color(0xFF1B5E20), size: 32),
        ],
      ),
    );
  }
}
