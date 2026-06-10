import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';

class TransactionRepository {
  Future<void> saveTransaction(
      TransactionModel transaction, List<OrderItemModel> items) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      await txn.insert('transactions', transaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      for (var item in items) {
        await txn.insert('order_items', item.toMap(), 
            conflictAlgorithm: ConflictAlgorithm.replace);
        
        final productMaps = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        if (productMaps.isNotEmpty) {
          final currentStock = productMaps.first['stok'] as int;
          final newStock = currentStock - item.qty;
          await txn.update(
            'products',
            {'stok': newStock},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }
    });
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('transactions', orderBy: 'tanggal DESC');

    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }
  
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('transactions', where: 'sync_status = ?', whereArgs: ['pending']);
    
    List<TransactionModel> transactions = [];
    for (var map in maps) {
      final itemsMaps = await db.query(
        'order_items',
        where: 'receipt_id = ?',
        whereArgs: [map['id']],
      );
      
      final items = itemsMaps.map((itemMap) => OrderItemModel.fromMap(itemMap)).toList();
      
      var mutableMap = Map<String, dynamic>.from(map);
      mutableMap['items'] = itemsMaps; // This will be passed to fromMap
      
      transactions.add(TransactionModel.fromMap(mutableMap));
    }
    return transactions;
  }

  Future<void> markAsSynced(String transactionId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('transactions', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [transactionId]);
  }

  Future<List<OrderItemModel>> getOrderItems(String receiptId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'order_items',
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
    );
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  Future<void> voidTransaction(String receiptId) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // 1. Update transaction status
      await txn.update(
        'transactions',
        {'status': 'voided'},
        where: 'id = ? OR receipt_number = ?',
        whereArgs: [receiptId, receiptId],
      );

      // 2. Fetch order items to restore stock
      final itemsMaps = await txn.query(
        'order_items',
        where: 'receipt_id = ?',
        whereArgs: [receiptId],
      );

      for (var map in itemsMaps) {
        final item = OrderItemModel.fromMap(map);
        final productMaps = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (productMaps.isNotEmpty) {
          final currentStock = productMaps.first['stok'] as int;
          final newStock = currentStock + item.qty;
          await txn.update(
            'products',
            {'stok': newStock},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }
    });
  }

  Future<Map<String, dynamic>> getTodaySalesSummary() async {
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    return getSummaryByDate(dateStr);
  }

  Future<Map<String, dynamic>> getSummaryByDate(String dateStr) async {
    return getSummaryByDateRange(dateStr, dateStr);
  }

  Future<Map<String, dynamic>> getSummaryByDateRange(String startDateStr, String endDateStr) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        SUM(total_price) as total_sales
      FROM transactions
      WHERE date(tanggal) >= ? AND date(tanggal) <= ? AND status != 'voided'
    ''', [startDateStr, endDateStr]);

    if (result.isNotEmpty) {
      return {
        'total_orders': result.first['total_orders'] ?? 0,
        'total_sales': result.first['total_sales'] ?? 0.0,
      };
    }
    return {'total_orders': 0, 'total_sales': 0.0};
  }

  Future<int> getTotalItemsSoldToday() async {
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    return getTotalItemsSoldByDate(dateStr);
  }

  Future<int> getTotalItemsSoldByDate(String dateStr) async {
    return getTotalItemsSoldByDateRange(dateStr, dateStr);
  }

  Future<int> getTotalItemsSoldByDateRange(String startDateStr, String endDateStr) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT SUM(oi.qty) as total_items
      FROM order_items oi
      JOIN transactions t ON oi.receipt_id = t.id
      WHERE date(t.tanggal) >= ? AND date(t.tanggal) <= ? AND t.status != 'voided'
    ''', [startDateStr, endDateStr]);
    
    if (result.isNotEmpty) {
      return (result.first['total_items'] as int?) ?? 0;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getHourlyPerformance(DateTime date) async {
    final String dateString = date.toIso8601String().split('T')[0];
    return getHourlyPerformanceByDate(dateString);
  }

  Future<List<Map<String, dynamic>>> getHourlyPerformanceByDate(String dateString) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        strftime('%H', tanggal) as hour,
        SUM(total_price) as hourly_sales
      FROM transactions
      WHERE date(tanggal) = ? AND status != 'voided'
      GROUP BY strftime('%H', tanggal)
      ORDER BY hour ASC
    ''', [dateString]);
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getRecentTransactionsWithItems({int limit = 5}) async {
    return getTransactionsByDateWithItems(null, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateWithItems(String? dateString, {int? limit}) async {
    return getTransactionsByDateRangeWithItems(dateString, dateString, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRangeWithItems(String? startDateStr, String? endDateStr, {int? limit}) async {
    final db = await DatabaseHelper.instance.database;
    
    String whereClause = 'status != ?';
    List<dynamic> whereArgs = ['voided'];
    
    if (startDateStr != null && endDateStr != null) {
      whereClause += ' AND date(tanggal) >= ? AND date(tanggal) <= ?';
      whereArgs.add(startDateStr);
      whereArgs.add(endDateStr);
    }
    
    final txns = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'tanggal DESC',
      limit: limit,
    );

    List<Map<String, dynamic>> result = [];
    
    for (var txn in txns) {
      final id = txn['id'] as String;
      
      final items = await db.rawQuery('''
        SELECT p.name, oi.qty
        FROM order_items oi
        JOIN products p ON oi.product_id = p.id
        WHERE oi.receipt_id = ?
        LIMIT 1
      ''', [id]);
      
      String itemName = 'Unknown Item';
      int itemQty = 0;
      int totalItems = 0;
      
      final totalItemsResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM order_items WHERE receipt_id = ?
      ''', [id]);
      
      if (totalItemsResult.isNotEmpty) {
        totalItems = (totalItemsResult.first['count'] as int?) ?? 0;
      }
      
      if (items.isNotEmpty) {
        itemName = items.first['name'] as String;
        itemQty = (items.first['qty'] as int?) ?? 0;
        
        if (totalItems > 1) {
          itemName += ' (+\${totalItems - 1} more)';
        }
      }
      
      result.add({
        'transaction': txn,
        'item_name': itemName,
        'qty': itemQty,
      });
    }
    
    return result;
  }
}
