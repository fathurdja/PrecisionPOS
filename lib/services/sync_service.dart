import 'dart:convert';
import 'api_config.dart';
import 'api_client.dart';
import '../repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../data/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final ProductRepository _productRepo = ProductRepository();
  final ApiClient _client = ApiClient();

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
      // Force all transactions to 'pending' as requested by user
      final db = await DatabaseHelper.instance.database;
      await db.update('transactions', {'sync_status': 'pending'});

      final allTx = await _transactionRepo.getTransactions();
      print('=== DEBUG: ALL TRANSACTIONS IN LOCAL DB ===');
      print(jsonEncode(allTx.map((t) => t.toJson()).toList()));

      final unsynced = await _transactionRepo.getUnsyncedTransactions();
      print('=== DEBUG: UNSYNCED TRANSACTIONS ===');
      print(jsonEncode(unsynced.map((t) => t.toJson()).toList()));

      if (unsynced.isEmpty) {
        print('No unsynced transactions found.');
        return true;
      }

      final deviceId = await _getDeviceId();

      final payload = {
        'device_id': deviceId,
        'orders': unsynced.map((t) => t.toJson()).toList(),
      };
      
      print('=== SYNC UPLOAD DEBUG ===');
      print('Payload: ${jsonEncode(payload)}');

      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/sync/upload'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Mark all as synced
        for (var t in unsynced) {
          await _transactionRepo.markAsSynced(t.id);
        }
        return true;
      } else {
        print('Sync Upload Error Status: ${response.statusCode}');
        print('Sync Upload Error Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Sync Upload Exception: $e');
      return false;
    }
  }

  Future<bool> downloadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getString('last_sync_time');
      final deviceId = await _getDeviceId();

      final Map<String, String> queryParams = {
        'device_id': deviceId.toString(),
      };
      if (lastSyncTime != null) {
        queryParams['since'] = lastSyncTime;
      }

      final Uri uri = Uri.parse('${ApiConfig.baseUrl}/sync/download').replace(queryParameters: queryParams);

      final response = await _client.get(uri);
      
      print('=== SYNC DOWNLOAD DEBUG ===');
      print('URL: $uri');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

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
          // Sync customers
          if (data['customers'] != null) {
            for (var item in data['customers']) {
              final customer = CustomerModel.fromMap(item);
              await txn.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          // Sync orders (if any downloaded from server for this device)
          // Simplified here, skipping full order sync parsing as it's typically for multi-device environments
        });

        if (data['server_time'] != null) {
          await prefs.setString('last_sync_time', data['server_time']);
        }
        return true;
      } else {
        print('Sync Download Error Status: ${response.statusCode}');
        print('Sync Download Error Body: ${response.body}');
      }
      return false;
    } catch (e) {
      print('Sync Download Exception: $e');
      return false;
    }
  }

  Future<void> syncAll() async {
    await uploadTransactions();
    await downloadData();
  }
}
