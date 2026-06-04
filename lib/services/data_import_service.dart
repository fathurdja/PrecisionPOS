import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class DataImportService {
  final TransactionRepository _repo = TransactionRepository();

  Future<void> importTransactions() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        final input = await file.readAsLines();
        
        if (input.isEmpty) return;
        
        int startIndex = 0;
        if (input.first.toLowerCase().contains('receipt')) {
          startIndex = 1;
        }

        for (int i = startIndex; i < input.length; i++) {
          final rowSplit = input[i].split(',');
          final row = rowSplit.map((s) => s.trim()).toList();
          
          if (row.length < 4) continue;
          
          final String receiptId = row[0].toString();
          final String tanggal = row[1].toString(); // status expects a String
          final double totalHarga = double.tryParse(row[2].toString()) ?? 0.0;
          final String status = row[3].toString();
          
          final transaction = TransactionModel(
            id: receiptId, // Fallback to using receiptId as the ID if imported
            receiptNumber: receiptId,
            tanggal: tanggal,
            totalHarga: totalHarga,
            status: status,
            orderType: 'take-away',
            paymentMethod: 'cash',
          );
          
          await _repo.saveTransaction(transaction, []);
        }
      }
    } catch (e) {
      print('Import error: $e');
      rethrow;
    }
  }
}
