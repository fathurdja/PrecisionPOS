import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/transaction_repository.dart';

class DataExportService {
  final TransactionRepository _repo = TransactionRepository();

  Future<void> exportTransactions() async {
    try {
      final transactions = await _repo.getTransactions();
      
      List<List<dynamic>> rows = [];
      rows.add(["Receipt ID", "Tanggal", "Total Harga", "Status"]);

      for (var tx in transactions) {
        rows.add([
          tx.receiptId,
          tx.tanggal.replaceAll(',', ' '), 
          tx.totalHarga,
          tx.status,
        ]);
      }

      String csv = rows.map((row) => row.join(',')).join('\n');

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/precision_pos_transactions.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(path)], text: 'Precision POS Transactions Export');
    } catch (e) {
      print('Export error: $e');
      rethrow;
    }
  }
}
