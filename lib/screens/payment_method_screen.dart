import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import 'cash_entry_screen.dart';
import 'bon_kredit_screen.dart';
import 'qris_screen.dart';
import '../utils/currency_format.dart';

class PaymentMethodScreen extends StatefulWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;

  const PaymentMethodScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod;

  void _onMethodSelected(String method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  void _onNext() {
    if (_selectedMethod == null) return;
    
    if (_selectedMethod == 'Cash') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashEntryScreen(
            transaction: widget.transaction,
            items: widget.items,
          ),
        ),
      );
    } else if (_selectedMethod == 'Bon') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BonKreditScreen(
            transaction: widget.transaction,
            items: widget.items,
          ),
        ),
      );
    } else if (_selectedMethod == 'QRIS') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrisScreen(
            transaction: widget.transaction,
            items: widget.items,
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
        title: const Text('Pilih Metode Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOrderSummaryCard(),
              const SizedBox(height: 24),
              const Text(
                'METODE PEMBAYARAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _buildMethodCard(
                method: 'Cash',
                title: 'Tunai (Cash)',
                description: 'Bayar dengan uang tunai',
                icon: Icons.payments,
              ),
              const SizedBox(height: 12),
              _buildMethodCard(
                method: 'QRIS',
                title: 'QRIS',
                description: 'E-Wallet, m-Banking (Ovo, Gopay, Dana, dll)',
                icon: Icons.qr_code_scanner,
              ),
              const SizedBox(height: 12),
              _buildMethodCard(
                method: 'Bon',
                title: 'Bon / Kredit',
                description: 'Catat sebagai piutang',
                icon: Icons.receipt_long,
                isBon: true,
              ),
              const SizedBox(height: 48),
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
        child: ElevatedButton(
          onPressed: _selectedMethod != null ? _onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceContainerHighest,
            disabledForegroundColor: AppColors.outline,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text('Lanjutkan Pembayaran →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    double subtotal = 0;
    for (var item in widget.items) {
      subtotal += item.subtotal;
    }
    double serviceCharge = widget.transaction.serviceAmount;
    double tax = widget.transaction.taxAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN PESANAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.qty}x Item ${item.productId}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(CurrencyFormat.idr(item.subtotal)),
              ],
            ),
          )),
          if (widget.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '+ ${widget.items.length - 3} item lainnya',
                style: const TextStyle(color: AppColors.outline, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: AppColors.onSurfaceVariant)),
              Text(CurrencyFormat.idr(subtotal), style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
          if (serviceCharge > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Charge', style: TextStyle(color: AppColors.onSurfaceVariant)),
                Text(CurrencyFormat.idr(serviceCharge), style: const TextStyle(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
          if (tax > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax', style: TextStyle(color: AppColors.onSurfaceVariant)),
                Text(CurrencyFormat.idr(tax), style: const TextStyle(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Text(
                CurrencyFormat.idr(widget.transaction.totalHarga),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required String method,
    required String title,
    required String description,
    required IconData icon,
    bool isBon = false,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => _onMethodSelected(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isBon)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF1E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PIUTANG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB07000),
                  ),
                ),
              ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
            if (!isSelected)
              const Icon(Icons.radio_button_unchecked, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}
