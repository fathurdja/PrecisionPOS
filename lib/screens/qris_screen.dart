import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../repositories/transaction_repository.dart';
import '../data/database_helper.dart';
import 'payment_success_screen.dart';
import '../utils/currency_format.dart';

class QrisScreen extends StatefulWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;

  const QrisScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  State<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends State<QrisScreen> {
  bool _isProcessing = false;

  void _confirmDummyPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Dummy delay to simulate network call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Load active cashier name
    final prefs = await SharedPreferences.getInstance();
    final cashierName = prefs.getString('user_name');

    final repo = TransactionRepository();
    
    // Create new transaction with updated status and metadata
    final completedTxn = TransactionModel(
      id: widget.transaction.id,
      receiptNumber: widget.transaction.receiptNumber,
      tanggal: widget.transaction.tanggal,
      totalHarga: widget.transaction.totalHarga,
      status: 'completed',
      orderType: widget.transaction.orderType,
      paymentMethod: 'qris',
      customerName: widget.transaction.customerName,
      taxAmount: widget.transaction.taxAmount,
      serviceAmount: widget.transaction.serviceAmount,
      cashierName: cashierName,
    );

    await repo.saveTransaction(completedTxn, widget.items);

    // Update staff last_active
    if (cashierName != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'staff',
          {'last_active': DateTime.now().toIso8601String()},
          where: 'name = ?',
          whereArgs: [cashierName],
        );
      } catch (e) {
        print("Failed to update staff last_active: $e");
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transaction: completedTxn,
            items: widget.items,
            method: 'QRIS',
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
        title: const Text('Scan untuk Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TOTAL TAGIHAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormat.idr(widget.transaction.totalHarga),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=PRECISION-POS-${widget.transaction.receiptId}-${widget.transaction.totalHarga}',
                      width: 250,
                      height: 250,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 250, height: 250,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stack) => const SizedBox(
                        width: 250, height: 250,
                        child: Center(child: Icon(Icons.qr_code, size: 80, color: AppColors.outline)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Scan dengan aplikasi e-wallet atau m-banking',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text('NMID: ID1029384756', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Berlaku hingga 04:59',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _confirmDummyPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.verified),
                  label: Text(
                    _isProcessing ? 'Memverifikasi...' : 'Konfirmasi Dummy Pembayaran', 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
