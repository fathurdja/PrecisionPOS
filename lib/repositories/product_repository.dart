import '../data/database_helper.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'package:sqflite/sqflite.dart';

class ProductRepository {
  Future<List<ProductModel>> getProducts() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final apiRes = await ApiService().getProducts();
      if (apiRes['success'] == true && apiRes['data'] != null) {
        final List<dynamic> pList = apiRes['data'];
        
        await db.transaction((txn) async {
          for (var item in pList) {
            final product = ProductModel.fromJson(item);
            await txn.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });
      } else {
        print('API getProducts failed: ${apiRes['message']}');
      }
    } catch (e) {
      print('Exception in API getProducts: $e');
    }

    final maps = await db.query('products');
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<int> reduceStock(String productId, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    final productMaps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productMaps.isNotEmpty) {
      final currentStock = productMaps.first['stok'] as int;
      final newStock = currentStock - quantity;

      return await db.update(
        'products',
        {'stok': newStock},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
    return 0;
  }

  Future<int> restoreStock(String productId, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    final productMaps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productMaps.isNotEmpty) {
      final currentStock = productMaps.first['stok'] as int;
      final newStock = currentStock + quantity;

      return await db.update(
        'products',
        {'stok': newStock},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
    return 0;
  }
}
