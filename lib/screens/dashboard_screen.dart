import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../repositories/transaction_repository.dart';
import '../utils/currency_format.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNewOrder;

  const DashboardScreen({super.key, this.onNewOrder});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _repo = TransactionRepository();
  bool _isLoading = true;
  double _todaySales = 0.0;
  int _totalOrders = 0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await _repo.getTodaySalesSummary();
    final recent = await _repo.getRecentTransactionsWithItems(limit: 5);
    
    if (mounted) {
      setState(() {
        _todaySales = summary['total_sales'] ?? 0.0;
        _totalOrders = summary['total_orders'] ?? 0;
        _recentTransactions = recent;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
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
                const SizedBox(height: 16),
                _buildDailyPerformance(),
                const SizedBox(height: 32),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                _buildRecentTransactions(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPerformance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAILY PERFORMANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("TODAY'S SALES", _isLoading ? '...' : _formatCurrency(_todaySales), 'Live', Icons.trending_up)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('TOTAL ORDERS', _isLoading ? '...' : _totalOrders.toString(), 'Today', Icons.check_circle)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String badge, IconData badgeIcon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(badgeIcon, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        // New Order - Full width primary gradient
        GestureDetector(
          onTap: () {
            if (widget.onNewOrder != null) {
              widget.onNewOrder!();
            } else {
              Navigator.pushNamed(context, '/order');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Order',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start a fresh transaction',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionCard(Icons.inventory_2, 'Inventory', '854 Items Stocked')),
            const SizedBox(width: 16),
            Expanded(child: _buildActionCard(Icons.group, 'Customers', '2.4k Registered')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT TRANSACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryFixedDim,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: _isLoading 
              ? [const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))]
              : _recentTransactions.isEmpty
                  ? [const Padding(padding: EdgeInsets.all(24), child: Text('No recent transactions.'))]
                  : List.generate(_recentTransactions.length, (index) {
                      final txData = _recentTransactions[index];
                      final tx = txData['transaction'];
                      final String status = tx['status'];
                      final double amount = tx['total_harga'] ?? 0.0;
                      final String timeStr = DateTime.parse(tx['tanggal']).toLocal().toString().substring(11, 16);
                      final String receiptId = tx['receipt_id'].toString();
                      
                      return _buildTransactionItem(
                        'Order #${receiptId.length > 4 ? receiptId.substring(receiptId.length - 4) : receiptId}', 
                        '$timeStr • $status', 
                        _formatCurrency(amount), 
                        index % 2 != 0
                      );
                    }),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, bool alternate) {
    return Container(
      color: alternate ? AppColors.surfaceContainerLow.withValues(alpha: 0.5) : Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.point_of_sale,
              color: AppColors.onSecondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
