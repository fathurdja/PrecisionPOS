import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/product_model.dart';
import '../data/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final ProductRepository _productRepo = ProductRepository();

  Future<int?> _getDeviceId() async {
    // A simplistic way to get a device id for sync (since API requires integer device_id). 
    // Usually the backend provides this upon register-device.
    final prefs = await SharedPreferences.getInstance();
    int? deviceId = prefs.getInt('device_id');
    if (deviceId == null) {
      // Just fallback to 1 for demo purposes if not registered properly
      return 1; 
    }
    return deviceId;
  }

  Future<bool> uploadTransactions() async {
    try {
      final unsynced = await _transactionRepo.getUnsyncedTransactions();
      if (unsynced.isEmpty) return true;

      final token = await ApiConfig.getToken();
      if (token == null) return false;

      final deviceId = await _getDeviceId();

      final payload = {
        'device_id': deviceId,
        'orders': unsynced.map((t) => t.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('\${ApiConfig.baseUrl}/sync/upload'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Mark all as synced
        for (var t in unsynced) {
          await _transactionRepo.markAsSynced(t.id);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Sync Upload Error: \$e');
      return false;
    }
  }

  Future<bool> downloadData() async {
    try {
      final token = await ApiConfig.getToken();
      if (token == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getString('last_sync_time');
      final deviceId = await _getDeviceId();

      String url = '\${ApiConfig.baseUrl}/sync/download?device_id=\$deviceId';
      if (lastSyncTime != null) {
        url += '&since=\$lastSyncTime';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer \$token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final db = await DatabaseHelper.instance.database;
        await db.transaction((txn) async {
          // Sync products
          if (data['products'] != null) {
            for (var item in data['products']) {
              final product = ProductModel.fromJson(item);
              await txn.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          // Sync orders (if any downloaded from server for this device)
          // Simplified here, skipping full order sync parsing as it's typically for multi-device environments
        });

        if (data['server_time'] != null) {
          await prefs.setString('last_sync_time', data['server_time']);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Sync Download Error: \$e');
      return false;
    }
  }

  Future<void> syncAll() async {
    await uploadTransactions();
    await downloadData();
  }
}
