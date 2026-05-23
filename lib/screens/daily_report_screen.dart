import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../repositories/transaction_repository.dart';
import '../services/data_export_service.dart';
import '../services/data_import_service.dart';
import '../services/pdf_report_service.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final TransactionRepository _repo = TransactionRepository();
  bool _isLoading = true;
  double _todaySales = 0.0;
  int _itemsSold = 0;
  double _avgTicket = 0.0;
  List<Map<String, dynamic>> _hourlyPerformance = [];
  List<double> _hourlyBuckets = List.filled(7, 0.0);
  double _maxHourlySales = 100.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Hari Ini';
  final List<String> _periods = ['Hari Ini', 'Bulan Ini', 'Tahun Ini', 'Semua Waktu', 'Kustom'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    
    final effectiveStart = _selectedPeriod == 'Semua Waktu' ? '2000-01-01' : startStr;
    final effectiveEnd = _selectedPeriod == 'Semua Waktu' ? '2100-01-01' : endStr;

    final summary = await _repo.getSummaryByDateRange(effectiveStart, effectiveEnd);
    final itemsSold = await _repo.getTotalItemsSoldByDateRange(effectiveStart, effectiveEnd);
    
    List<Map<String, dynamic>> hourly = [];
    if (startStr == endStr && _selectedPeriod != 'Semua Waktu') {
      hourly = await _repo.getHourlyPerformanceByDate(startStr);
    }
    
    final recent = await _repo.getTransactionsByDateRangeWithItems(
      _selectedPeriod == 'Semua Waktu' ? null : startStr, 
      _selectedPeriod == 'Semua Waktu' ? null : endStr, 
      limit: 100
    );
    
    if (mounted) {
      setState(() {
        _todaySales = summary['total_sales'] ?? 0.0;
        final totalOrders = summary['total_orders'] ?? 0;
        _itemsSold = itemsSold;
        _avgTicket = totalOrders > 0 ? (_todaySales / totalOrders) : 0.0;
        _hourlyPerformance = hourly;
        
        _hourlyBuckets = List.filled(7, 0.0);
        _maxHourlySales = 100.0;
        for (var data in _hourlyPerformance) {
          int hour = int.tryParse(data['hour'].toString()) ?? 0;
          double sales = (data['hourly_sales'] as num?)?.toDouble() ?? 0.0;
          int bucketIndex = 0;
          if (hour >= 8 && hour < 10) bucketIndex = 0;
          else if (hour >= 10 && hour < 12) bucketIndex = 1;
          else if (hour >= 12 && hour < 14) bucketIndex = 2;
          else if (hour >= 14 && hour < 16) bucketIndex = 3;
          else if (hour >= 16 && hour < 18) bucketIndex = 4;
          else if (hour >= 18 && hour < 20) bucketIndex = 5;
          else if (hour >= 20) bucketIndex = 6;
          _hourlyBuckets[bucketIndex] += sales;
        }
        for (double val in _hourlyBuckets) {
          if (val > _maxHourlySales) _maxHourlySales = val;
        }
        _maxHourlySales = _maxHourlySales * 1.2;

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
                _buildOfflineStatus(),
                const SizedBox(height: 24),
                _buildHeadline(),
                const SizedBox(height: 24),
                _buildSummaryCards(),
                const SizedBox(height: 24),
                if (_startDate.year == _endDate.year && _startDate.month == _endDate.month && _startDate.day == _endDate.day && _selectedPeriod != 'Semua Waktu') ...[
                  _buildHourlyPerformance(),
                  const SizedBox(height: 24),
                ],
                _buildRecentTransactions(),
                const SizedBox(height: 24),
                _buildManageData(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'OFFLINE BACKUP STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Text(
            'Last synced 2 mins ago',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    String dateRangeText = '';
    if (_selectedPeriod == 'Semua Waktu') {
      dateRangeText = 'Semua Waktu';
    } else if (_startDate.year == _endDate.year && _startDate.month == _endDate.month && _startDate.day == _endDate.day) {
      dateRangeText = DateFormat('dd MMM yyyy').format(_startDate);
    } else {
      dateRangeText = '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}';
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    items: _periods.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                          final now = DateTime.now();
                          if (newValue == 'Hari Ini') {
                            _startDate = now;
                            _endDate = now;
                          } else if (newValue == 'Bulan Ini') {
                            _startDate = DateTime(now.year, now.month, 1);
                            _endDate = now;
                          } else if (newValue == 'Tahun Ini') {
                            _startDate = DateTime(now.year, 1, 1);
                            _endDate = now;
                          }
                        });
                        
                        if (newValue == 'Kustom') {
                          final DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: AppColors.onSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                            _loadData();
                          } else {
                            setState(() {
                              _selectedPeriod = 'Hari Ini';
                              _startDate = DateTime.now();
                              _endDate = DateTime.now();
                            });
                            _loadData();
                          }
                        } else {
                          _loadData();
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateRangeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Total Sales - full width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL SALES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  Icon(Icons.payments, color: AppColors.secondary),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _isLoading ? '...' : _formatCurrency(_todaySales),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEMS SOLD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoading ? '...' : _itemsSold.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVG TICKET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoading ? '...' : _formatCurrency(_avgTicket),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHourlyPerformance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hourly Performance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const labels = ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00'];
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  double val = _hourlyBuckets[index];
                  double maxVal = _hourlyBuckets.reduce((a, b) => a > b ? a : b);
                  Color color = (val > 0 && val == maxVal) ? AppColors.primary : AppColors.surfaceContainer;
                  return _buildBarGroup(index, val, color);
                }),
                maxY: _maxHourlySales,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
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
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'ITEM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'QTY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'PRICE',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (_recentTransactions.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('No recent transactions.'))
              else
                ...List.generate(_recentTransactions.length, (index) {
                  final txData = _recentTransactions[index];
                  final tx = txData['transaction'];
                  final String receiptId = tx['receipt_id'].toString();
                  final double amount = tx['total_harga'] ?? 0.0;
                  final String itemName = txData['item_name'];
                  final int qty = txData['qty'];
                  
                  return Column(
                    children: [
                      _buildTableRow(
                        itemName, 
                        '#${receiptId.length > 8 ? receiptId.substring(receiptId.length - 8) : receiptId}', 
                        qty.toString().padLeft(2, '0'), 
                        _formatCurrency(amount)
                      ),
                      if (index < _recentTransactions.length - 1)
                        Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.1)),
                    ],
                  );
                }),
              // View Full Journal
              InkWell(
                onTap: () {
                  // Navigate to History Screen
                  Navigator.pushNamed(context, '/history');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      'VIEW FULL JOURNAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryFixedDim,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String name, String trxId, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trxId,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageData() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download, color: AppColors.secondaryFixed),
              const SizedBox(width: 12),
              Text(
                'Manage Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Securely export your daily transaction logs or import legacy data to the cloud vault.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onPrimaryContainer,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPdfCustomizationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryFixed,
                foregroundColor: AppColors.onSecondaryFixed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: Text(
                'Download Report as PDF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preparing export...')),
                  );
                  await DataExportService().exportTransactions();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.table_chart, size: 16),
              label: Text(
                'Export as .CSV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await DataImportService().importTransactions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data imported successfully!')),
                    );
                    _loadData(); // reload dashboard
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Import failed: $e')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(
                'Import Data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPdfCustomizationDialog() {
    final titleController = TextEditingController(text: 'Laporan Penjualan Kopi Senja');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          title: Text('Kustomisasi PDF', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Laporan',
                  labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan Tambahan',
                  labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
                final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
                
                final effectiveStart = _selectedPeriod == 'Semua Waktu' ? '2000-01-01' : startStr;
                final effectiveEnd = _selectedPeriod == 'Semua Waktu' ? '2100-01-01' : endStr;

                // Fetch all transactions for the selected range for the PDF
                final allTxns = await _repo.getTransactionsByDateRangeWithItems(
                  effectiveStart, effectiveEnd,
                  limit: 1000 // A reasonably large number to get all for the report
                );

                await PdfReportService().exportAndPrintDailyReport(
                  startDate: _startDate,
                  endDate: _endDate,
                  title: titleController.text,
                  notes: notesController.text,
                  summary: {
                    'total_sales': _todaySales,
                    'total_orders': (_todaySales > 0 && _avgTicket > 0) ? (_todaySales / _avgTicket).round() : 0,
                    'items_sold': _itemsSold,
                  },
                  transactions: allTxns,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buat PDF'),
            ),
          ],
        );
      },
    );
  }
}
