import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../data/database_helper.dart';

class PdfReceiptService {
  // F4 page format: 215mm x 330mm
  static final PdfPageFormat f4Format = PdfPageFormat(
    215 * PdfPageFormat.mm,
    330 * PdfPageFormat.mm,
    marginAll: 20 * PdfPageFormat.mm,
  );

  Future<pw.Document> generateReceipt(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = pw.Document();
    
    // Load store & template settings
    final prefs = await SharedPreferences.getInstance();
    final template = prefs.getString('receipt_template') ?? 'classic';
    final storeName = prefs.getString('store_name') ?? 'PRECISION BREW';
    final storeAddress = prefs.getString('store_address') ?? 'Jl. Senopati No. 42, Jakarta Selatan';
    final storePhone = prefs.getString('store_phone') ?? '+62 21 555 0123';

    // Enrich items with real names
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> enrichedItems = [];
    for (var item in items) {
      final pList = await db.query('products', where: 'id = ?', whereArgs: [item.productId]);
      String productName = pList.isNotEmpty ? pList.first['nama'] as String : 'Item ${item.productId}';
      enrichedItems.add({
        'name': productName,
        'qty': item.qty,
        'subtotal': item.subtotal,
      });
    }

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedDate = transaction.tanggal.length >= 16 
        ? transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') 
        : transaction.tanggal;
    double subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

    // Apply template styles
    if (template.toLowerCase() == 'modern') {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            final primaryBlue = PdfColor.fromInt(0xFF003366);
            final bgGray = PdfColor.fromInt(0xFFF0F4F8);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: primaryBlue,
                  width: double.infinity,
                  child: pw.Column(
                    children: [
                      pw.Text(storeName.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.Text('PREMIUM ATELIER RECEIPT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Receipt ID: ${transaction.receiptId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 7)),
                if (transaction.customerName != null)
                  pw.Text('Customer: ${transaction.customerName}', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('Cashier: ${transaction.cashierName ?? "System"}', style: const pw.TextStyle(fontSize: 7)),
                
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, color: primaryBlue),
                pw.SizedBox(height: 4),

                pw.Text('ITEMS ORDERED', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                pw.SizedBox(height: 4),

                ...enrichedItems.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${item['name']} x${item['qty']}', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Text(formatCurrency.format(item['subtotal']), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(formatCurrency.format(subtotal), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (transaction.serviceAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Service Charge', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(formatCurrency.format(transaction.serviceAmount), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (transaction.taxAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tax', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(formatCurrency.format(transaction.taxAmount), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),

                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: bgGray,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL PAID', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                      pw.Text(formatCurrency.format(transaction.totalHarga), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text('Thank you for your visit!', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                ),
                pw.Center(
                  child: pw.Text('$storeAddress • Tel: $storePhone', style: const pw.TextStyle(fontSize: 6), textAlign: pw.TextAlign.center),
                ),
              ],
            );
          },
        ),
      );
    } else if (template.toLowerCase() == 'eco') {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            final ecoGreen = PdfColor.fromInt(0xFF2E7D32);
            final lightGreen = PdfColor.fromInt(0xFFE8F5E9);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('[ECO] ${storeName.toUpperCase()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ecoGreen)),
                ),
                pw.Center(
                  child: pw.Text('100% PAPERLESS ECO-RECEIPT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: ecoGreen)),
                ),
                pw.SizedBox(height: 8),
                pw.Text('ID: ${transaction.receiptId}', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 7)),
                if (transaction.customerName != null)
                  pw.Text('Customer: ${transaction.customerName}', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('Cashier: ${transaction.cashierName ?? "System"}', style: const pw.TextStyle(fontSize: 7)),
                
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, color: ecoGreen, borderStyle: pw.BorderStyle.dotted),
                pw.SizedBox(height: 4),

                ...enrichedItems.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${item['name']} x${item['qty']}', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Text(formatCurrency.format(item['subtotal']), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, color: ecoGreen, borderStyle: pw.BorderStyle.dotted),
                pw.SizedBox(height: 4),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(formatCurrency.format(subtotal), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (transaction.serviceAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Service Charge', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(formatCurrency.format(transaction.serviceAmount), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (transaction.taxAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Eco Tax', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(formatCurrency.format(transaction.taxAmount), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),

                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: lightGreen,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL AMOUNT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: ecoGreen)),
                      pw.Text(formatCurrency.format(transaction.totalHarga), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: ecoGreen)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text('Save paper, save trees!', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: ecoGreen)),
                ),
                pw.Center(
                  child: pw.Text('$storeAddress • Tel: $storePhone', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // Classic
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(storeName.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Center(
                  child: pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8)),
                ),
                pw.Center(
                  child: pw.Text('Tel: $storePhone', style: const pw.TextStyle(fontSize: 8)),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),
                
                pw.Text('Receipt ID : ${transaction.receiptId}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Date       : $formattedDate', style: const pw.TextStyle(fontSize: 8)),
                if (transaction.customerName != null)
                  pw.Text('Customer   : ${transaction.customerName}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Cashier    : ${transaction.cashierName ?? "System"}', style: const pw.TextStyle(fontSize: 8)),
                
                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),
                
                ...enrichedItems.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${item['name']} x${item['qty']}', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Text(formatCurrency.format(item['subtotal']), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                }),
                
                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(formatCurrency.format(subtotal), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (transaction.serviceAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Service Charge', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(formatCurrency.format(transaction.serviceAmount), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (transaction.taxAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tax', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(formatCurrency.format(transaction.taxAmount), style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.SizedBox(height: 4),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(formatCurrency.format(transaction.totalHarga), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Method', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(transaction.status == 'Bon' ? 'BON/KREDIT' : transaction.status, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 8)),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  // =============================================
  // F4 INVOICE GENERATION (215mm x 330mm)
  // =============================================

  Future<pw.MemoryImage?> _loadStoreLogo(String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty) return null;
    try {
      final file = File(logoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.MemoryImage(bytes);
      }
    } catch (e) {
      // Silently fail — no logo will be displayed
    }
    return null;
  }

  Future<pw.Document> generateInvoiceF4(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = pw.Document();
    
    // Load store settings
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('store_name') ?? 'PRECISION BREW';
    final storeAddress = prefs.getString('store_address') ?? 'Jl. Senopati No. 42, Jakarta Selatan';
    final storePhone = prefs.getString('store_phone') ?? '+62 21 555 0123';
    final storeEmail = prefs.getString('store_email') ?? '';
    final storeLogo = await _loadStoreLogo(prefs.getString('store_logo_path'));

    // Enrich items with real names and unit price
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> enrichedItems = [];
    for (var item in items) {
      final pList = await db.query('products', where: 'id = ?', whereArgs: [item.productId]);
      String productName = pList.isNotEmpty ? pList.first['nama'] as String : 'Item ${item.productId}';
      double unitPrice = pList.isNotEmpty ? (pList.first['harga'] as num).toDouble() : 0;
      enrichedItems.add({
        'name': productName,
        'qty': item.qty,
        'unit_price': unitPrice,
        'subtotal': item.subtotal,
      });
    }

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedDate = transaction.tanggal.length >= 16 
        ? transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') 
        : transaction.tanggal;
    double subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

    // Colors
    final primaryColor = PdfColor.fromInt(0xFF003366);
    final headerBg = PdfColor.fromInt(0xFF003366);
    final headerText = PdfColors.white;
    final lightBg = PdfColor.fromInt(0xFFF5F7FA);
    final borderColor = PdfColor.fromInt(0xFFDDE2E8);

    pdf.addPage(
      pw.Page(
        pageFormat: f4Format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER: Logo + Store Info =====
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: headerBg,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo
                    if (storeLogo != null)
                      pw.Container(
                        width: 60,
                        height: 60,
                        margin: const pw.EdgeInsets.only(right: 16),
                        child: pw.Image(storeLogo, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        width: 60,
                        height: 60,
                        margin: const pw.EdgeInsets.only(right: 16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            storeName.isNotEmpty ? storeName[0] : 'S',
                            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: headerBg),
                          ),
                        ),
                      ),
                    // Store Info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            storeName.toUpperCase(),
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: headerText),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(storeAddress, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Telp: $storePhone${storeEmail.isNotEmpty ? '  |  Email: $storeEmail' : ''}',
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey300),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ===== INVOICE TITLE & META =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 60,
                        height: 3,
                        color: primaryColor,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('No. Invoice', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(transaction.receiptId, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.SizedBox(height: 6),
                      pw.Text('Tanggal', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ===== CUSTOMER & CASHIER INFO =====
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Kepada:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            transaction.customerName ?? 'Walk-in Customer',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          if (transaction.customerPhone != null && transaction.customerPhone!.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Telp: ${transaction.customerPhone}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          ],
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Kasir:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            transaction.cashierName ?? 'System',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Metode: ${transaction.status == 'Bon' ? 'BON/KREDIT' : transaction.status}',
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ===== ITEMS TABLE =====
              pw.Text(
                'DETAIL PESANAN',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: headerText),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: headerBg),
                cellHeight: 32,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                headerAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
                headers: ['No', 'Nama Item', 'Qty', 'Harga Satuan', 'Subtotal'],
                data: enrichedItems.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  final item = entry.value;
                  return [
                    '$idx',
                    item['name'] as String,
                    '${item['qty']}',
                    formatCurrency.format(item['unit_price']),
                    formatCurrency.format(item['subtotal']),
                  ];
                }).toList(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(35),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                oddRowDecoration: pw.BoxDecoration(color: lightBg),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),

              pw.SizedBox(height: 16),

              // ===== TOTALS SECTION =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 250,
                    child: pw.Column(
                      children: [
                        _buildInvoiceTotalRow('Subtotal', formatCurrency.format(subtotal), borderColor),
                        if (transaction.serviceAmount > 0)
                          _buildInvoiceTotalRow('Service Charge', formatCurrency.format(transaction.serviceAmount), borderColor),
                        if (transaction.taxAmount > 0)
                          _buildInvoiceTotalRow('Pajak (Tax)', formatCurrency.format(transaction.taxAmount), borderColor),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: pw.BoxDecoration(
                            color: headerBg,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: headerText)),
                              pw.Text(formatCurrency.format(transaction.totalHarga), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: headerText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ===== FOOTER =====
              pw.Divider(color: borderColor),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Terima kasih atas kunjungan Anda!',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '$storeAddress  |  Telp: $storePhone${storeEmail.isNotEmpty ? '  |  $storeEmail' : ''}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Dokumen ini dicetak secara otomatis oleh sistem dan sah tanpa tanda tangan.',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildInvoiceTotalRow(String label, String value, PdfColor borderColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // =============================================
  // PRINT & FILE METHODS
  // =============================================

  Future<void> printReceipt(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = await generateReceipt(transaction, items);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${transaction.receiptId}',
    );
  }

  Future<File> getPdfFile(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = await generateReceipt(transaction, items);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${transaction.receiptId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> printInvoiceF4(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = await generateInvoiceF4(transaction, items);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${transaction.receiptId}',
      format: f4Format,
    );
  }

  Future<File> getInvoiceF4File(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = await generateInvoiceF4(transaction, items);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Invoice_${transaction.receiptId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
