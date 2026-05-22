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
}
