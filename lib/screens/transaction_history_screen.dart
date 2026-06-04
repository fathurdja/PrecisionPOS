import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'receipt_preview_screen.dart';
import '../utils/currency_format.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionRepository _repo = TransactionRepository();
  List<TransactionModel> _transactions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txns = await _repo.getTransactions();
    if (mounted) {
      setState(() {
        _transactions = txns;
      });
    }
  }

  Future<void> _voidTransaction(String receiptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Transaction?'),
        content: Text('Are you sure you want to void $receiptId and restore stock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Void'),
          ),
        ],
      )
    );

    if (confirm == true) {
      await _repo.voidTransaction(receiptId);
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Transaction voided and stock restored.', style: TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: AppColors.outlineVariant, // Replaced standard surface background with tonal outline variant
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        );
      }
    }
  }

  Future<void> _showTransactionDetails(TransactionModel t) async {
    final items = await _repo.getOrderItems(t.receiptId);
    
    if (!mounted) return;
    
    String method = 'CASH/QRIS';
    if (t.status == 'Bon · Belum Lunas') {
        method = 'BON';
    } else if (t.status == 'Void') {
        method = 'VOID';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptPreviewScreen(
          transaction: t,
          items: items,
          method: method,
        ),
      ),
    );
  }

  Map<String, List<TransactionModel>> get _groupedTransactions {
    final filtered = _transactions.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.receiptId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             t.totalHarga.toString().contains(_searchQuery);
    }).toList();
    
    final Map<String, List<TransactionModel>> groups = {};
    for (var t in filtered) {
      final dateStr = t.tanggal.length >= 10 ? t.tanggal.substring(0, 10) : 'Unknown Date';
      groups.putIfAbsent(dateStr, () => []).add(t);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildDynamicList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search receipt ID, date or amount...',
          hintStyle: TextStyle(
            color: AppColors.outline,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDynamicList() {
    final groups = _groupedTransactions;
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No transactions found.', style: TextStyle(color: AppColors.outline)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final date = entry.key;
        final txns = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...txns.map((t) => _buildTransactionCard(t)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionCard(TransactionModel t) {
    final isVoid = t.status == 'Void' || t.status == 'Refunded';
    final isPending = t.status == 'Pending';

    Color bgColor = AppColors.surfaceContainerLowest;
    Color statusBg = AppColors.secondaryContainer.withValues(alpha: 0.3);
    Color statusDot = AppColors.secondary;
    Color statusText = AppColors.onSecondaryContainer;

    if (isVoid) {
      statusBg = AppColors.errorContainer.withValues(alpha: 0.3);
      statusDot = AppColors.error;
      statusText = AppColors.onErrorContainer;
    } else if (isPending) {
      statusBg = AppColors.tertiaryFixed.withValues(alpha: 0.3);
      statusDot = AppColors.onTertiaryFixedVariant;
      statusText = AppColors.onTertiaryFixedVariant;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isVoid ? Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${t.receiptId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.tanggal.length >= 16 ? t.tanggal.substring(11, 16).replaceFirst('T', ' ') : t.tanggal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.outline,
                    ),
                  ),
                  if (t.customerName != null && t.customerName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          t.customerName!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              _buildStatusBadge(t.status, statusBg, statusDot, statusText),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isVoid)
                ElevatedButton(
                  onPressed: () => _voidTransaction(t.receiptId),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.errorContainer,
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Void', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                 const SizedBox(),
              Text(
                CurrencyFormat.idr(t.totalHarga),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isVoid ? AppColors.outline : AppColors.primary,
                  decoration: isVoid ? TextDecoration.lineThrough : null,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => _showTransactionDetails(t),
              icon: Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
              label: Text('Lihat Detail Pesanan', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color bgColor, Color dotColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
