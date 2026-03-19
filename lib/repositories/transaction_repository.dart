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
        await txn.insert('order_items', item.toMap());
        
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
        {'status': 'Void'},
        where: 'receipt_id = ?',
        whereArgs: [receiptId],
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
}
