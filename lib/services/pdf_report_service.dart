import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  Future<pw.Document> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required String title,
    required String notes,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final pdf = pw.Document();

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');
    
    String periodText = dateFormat.format(startDate);
    if (startDate != endDate) {
      periodText = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PRECISION POS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Sales & Performance Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('PERIOD', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                    pw.Text(periodText, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Printed: ${DateFormat("dd MMM yyyy, HH:mm").format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            
            // Custom Title & Notes (if provided)
            if (title.isNotEmpty) ...[
              pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
            ],
            if (notes.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(notes, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
              ),
              pw.SizedBox(height: 24),
            ],

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Sales', formatCurrency.format(summary['total_sales'] ?? 0)),
                  _buildSummaryItem('Total Orders', "${summary['total_orders'] ?? 0}"),
                  _buildSummaryItem('Items Sold', "${summary['items_sold'] ?? 0}"),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Transactions Title
            pw.Text('Transaction Log', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              headers: ['Date/Time', 'Receipt ID', 'Items', 'Total'],
              data: transactions.map((txData) {
                final tx = txData['transaction'];
                final dateStr = tx['tanggal'] as String;
                final date = DateTime.tryParse(dateStr);
                final formattedDate = date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : dateStr;
                
                return [
                  formattedDate,
                  tx['receipt_id'].toString(),
                  txData['item_name'],
                  formatCurrency.format(tx['total_harga'] ?? 0),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
      ],
    );
  }

  Future<void> exportAndPrintDailyReport({
    required DateTime startDate,
    required DateTime endDate,
    required String title,
    required String notes,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final pdf = await generateReport(
      startDate: startDate,
      endDate: endDate,
      title: title,
      notes: notes,
      summary: summary,
      transactions: transactions,
    );
    
    final dateFormat = DateFormat('yyyyMMdd');
    final filename = 'Report_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.pdf';
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: filename,
    );
  }
}
