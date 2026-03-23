import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../data/database_helper.dart';

class PdfReceiptService {
  Future<pw.Document> generateReceipt(TransactionModel transaction, List<OrderItemModel> items) async {
    final pdf = pw.Document();
    
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> enrichedItems = [];
    
    for (var item in items) {
      final pList = await db.query('products', where: 'id = ?', whereArgs: [item.productId]);
      String productName = pList.isNotEmpty ? pList.first['nama'] as String : 'Item ${item.productId}';
      enrichedItems.add({
        'name': productName,
        'qty': item.qty,
        'subtotal': item.subtotal,
      });
    }

    final formatCurrency = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('PRECISION POS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(transaction.receiptId, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Center(
                child: pw.Text(DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(transaction.tanggal)), style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              ...enrichedItems.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${item['name']} x ${item['qty']}', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text(formatCurrency.format(item['subtotal']), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  )
                );
              }),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatCurrency.format(transaction.totalHarga), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

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
