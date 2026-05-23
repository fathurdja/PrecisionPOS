import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../data/database_helper.dart';
import '../services/pdf_receipt_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/currency_format.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;
  final String method;

  const ReceiptPreviewScreen({
    super.key,
    required this.transaction,
    required this.items,
    required this.method,
  });

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  String _selectedTemplate = 'classic';
  String _storeName = 'PRECISION BREW';
  String _storeAddress = 'Jl. Senopati No. 42, Jakarta Selatan';
  String _storePhone = '+62 21 555 0123';
  List<Map<String, dynamic>> _enrichedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedTemplate = prefs.getString('receipt_template') ?? 'classic';
      _storeName = prefs.getString('store_name') ?? 'PRECISION BREW';
      _storeAddress = prefs.getString('store_address') ?? 'Jl. Senopati No. 42, Jakarta Selatan';
      _storePhone = prefs.getString('store_phone') ?? '+62 21 555 0123';

      final db = await DatabaseHelper.instance.database;
      final enriched = <Map<String, dynamic>>[];

      for (var item in widget.items) {
        final pList = await db.query('products', where: 'id = ?', whereArgs: [item.productId]);
        String productName = pList.isNotEmpty ? pList.first['nama'] as String : 'Item ${item.productId}';
        enriched.add({
          'name': productName,
          'qty': item.qty,
          'subtotal': item.subtotal,
        });
      }

      setState(() {
        _enrichedItems = enriched;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading preview data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Column(
        children: [
          const AppTopBar(trailingText: 'Receipt Preview'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        _buildActionButtons(context),
                        const SizedBox(height: 32),
                        _buildReceiptCard(),
                        const SizedBox(height: 32),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: AppColors.outline),
                            SizedBox(width: 6),
                            Text(
                              'DIGITAL COPY • PAPERLESS CERTIFIED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.outline,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                final pdfFile = await PdfReceiptService().getInvoiceF4File(widget.transaction, widget.items);
                await WhatsAppService().sharePdfFile(pdfFile, text: 'Invoice dari ${_storeName} (${widget.transaction.receiptId})');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.share, size: 18),
            label: const Text(
              'Share WhatsApp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await PdfReceiptService().printInvoiceF4(widget.transaction, widget.items);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLowest,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text(
              'Export Invoice',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard() {
    switch (_selectedTemplate.toLowerCase()) {
      case 'modern':
        return _buildModernReceipt();
      case 'eco':
        return _buildEcoReceipt();
      case 'classic':
      default:
        return _buildClassicReceipt();
    }
  }

  // 1. CLASSIC MONOSPACE THERMAL RECEIPT
  Widget _buildClassicReceipt() {
    double subtotal = widget.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final formattedDate = widget.transaction.tanggal.length >= 16 
        ? widget.transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') 
        : widget.transaction.tanggal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4), // sharp corners for thermal receipt style
        border: Border.all(color: Colors.black26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              _storeName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _storeAddress,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Text(
              'Tel: $_storePhone',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '------------------------------------------',
            style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
          ),
          
          // Transaction Details
          Text('Receipt ID : ${widget.transaction.receiptId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
          Text('Date       : $formattedDate', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
          if (widget.transaction.customerName != null)
            Text('Customer   : ${widget.transaction.customerName}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
          Text('Cashier    : ${widget.transaction.cashierName ?? "System"}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
          
          const Text(
            '------------------------------------------',
            style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
          ),
          
          // Items Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Description', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('Subtotal', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Text(
            '- - - - - - - - - - - - - - - - - - - - -',
            style: TextStyle(fontFamily: 'monospace', color: Colors.black38),
          ),
          
          // Item list
          ..._enrichedItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['qty']}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                      ),
                    ),
                    Text(
                      CurrencyFormat.idr(item['subtotal'] as double),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              )),
              
          const Text(
            '------------------------------------------',
            style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
          ),
          
          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
              Text(CurrencyFormat.idr(subtotal), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
            ],
          ),
          if (widget.transaction.serviceAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Charge:', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
                Text(CurrencyFormat.idr(widget.transaction.serviceAmount), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
              ],
            ),
          if (widget.transaction.taxAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax:', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
                Text(CurrencyFormat.idr(widget.transaction.taxAmount), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
              ],
            ),
          const Text(
            '------------------------------------------',
            style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GRAND TOTAL:',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                CurrencyFormat.idr(widget.transaction.totalHarga),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Method:', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
              Text(widget.method.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Text(
            '------------------------------------------',
            style: TextStyle(fontFamily: 'monospace', color: Colors.black54),
          ),
          
          // QR
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.black,
              child: const Icon(
                Icons.qr_code_2,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Thank you for your purchase!',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 2. MODERN SLEEK RECEIPT
  Widget _buildModernReceipt() {
    double subtotal = widget.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final formattedDate = widget.transaction.tanggal.length >= 16 
        ? widget.transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') 
        : widget.transaction.tanggal;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner/Logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.coffee, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _storeName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'PREMIUM ATELIER RECEIPT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INVOICE TO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.outline)),
                        const SizedBox(height: 4),
                        Text(
                          widget.transaction.customerName ?? 'Guest Customer',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(widget.transaction.receiptId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(formattedDate, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Cashier info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cashier:', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    Text(
                      widget.transaction.cashierName ?? 'System Agent',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment:', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.method.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Item details
                const Text(
                  'ORDER ITEMS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline),
                ),
                const SizedBox(height: 8),
                
                ..._enrichedItems.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Quantity: ${item['qty']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormat.idr(item['subtotal'] as double),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                    )),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                
                // Totals
                _buildModernTotalRow('Subtotal', CurrencyFormat.idr(subtotal)),
                if (widget.transaction.serviceAmount > 0) ...[
                  const SizedBox(height: 6),
                  _buildModernTotalRow('Service Charge', CurrencyFormat.idr(widget.transaction.serviceAmount)),
                ],
                if (widget.transaction.taxAmount > 0) ...[
                  const SizedBox(height: 6),
                  _buildModernTotalRow('Tax', CurrencyFormat.idr(widget.transaction.taxAmount)),
                ],
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL PAID',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      Text(
                        CurrencyFormat.idr(widget.transaction.totalHarga),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/qr_code.png', // Fallback or placeholder
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.qr_code_2_rounded,
                        size: 90,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Thank you for your visit!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                Center(
                  child: Text(
                    '$_storeAddress • $_storePhone',
                    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }

  // 3. ECO FRIENDLY RECEIPT
  Widget _buildEcoReceipt() {
    double subtotal = widget.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final formattedDate = widget.transaction.tanggal.length >= 16 
        ? widget.transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') 
        : widget.transaction.tanggal;
    const greenAccent = Color(0xFF2E7D32);
    const lightGreen = Color(0xFFE8F5E9);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: greenAccent.withValues(alpha: 0.3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Eco banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: const BoxDecoration(
              color: greenAccent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  _storeName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forest_outlined, size: 12, color: greenAccent),
                        SizedBox(width: 6),
                        Text(
                          '100% PAPERLESS ECO-RECEIPT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: greenAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TRANSACTION ID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45)),
                        Text(widget.transaction.receiptId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: greenAccent)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45)),
                        Text(formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CUSTOMER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45)),
                        Text(widget.transaction.customerName ?? 'Eco Guest', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CASHIER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45)),
                        Text(widget.transaction.cashierName ?? 'System Agent', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(color: greenAccent, thickness: 1, height: 1),
                const SizedBox(height: 16),
                
                const Text(
                  'ITEMS ORDERED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: greenAccent),
                ),
                const SizedBox(height: 8),
                
                ..._enrichedItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['name']} (x${item['qty']})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          Text(
                            CurrencyFormat.idr(item['subtotal'] as double),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    )),
                
                const SizedBox(height: 12),
                const Divider(color: greenAccent, thickness: 1, height: 1),
                const SizedBox(height: 16),
                
                // Totals
                _buildEcoTotalRow('Subtotal', CurrencyFormat.idr(subtotal)),
                if (widget.transaction.serviceAmount > 0) ...[
                  const SizedBox(height: 6),
                  _buildEcoTotalRow('Service Charge', CurrencyFormat.idr(widget.transaction.serviceAmount)),
                ],
                if (widget.transaction.taxAmount > 0) ...[
                  const SizedBox(height: 6),
                  _buildEcoTotalRow('Eco Tax', CurrencyFormat.idr(widget.transaction.taxAmount)),
                ],
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: greenAccent),
                      ),
                      Text(
                        CurrencyFormat.idr(widget.transaction.totalHarga),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: greenAccent),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Method:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    Text(widget.method.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: greenAccent)),
                  ],
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: greenAccent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 80,
                      color: greenAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Save paper, save trees!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: greenAccent, fontStyle: FontStyle.italic),
                  ),
                ),
                Center(
                  child: Text(
                    '$_storeAddress • Tel: $_storePhone',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}
