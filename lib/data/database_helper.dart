import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('precision_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        nama $textType,
        harga $realType,
        stok $integerType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        receipt_id TEXT PRIMARY KEY,
        tanggal $textType,
        total_harga $realType,
        status $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id $idType,
        receipt_id $textType,
        product_id $integerType,
        qty $integerType,
        subtotal $realType,
        FOREIGN KEY (receipt_id) REFERENCES transactions (receipt_id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await _insertDummyProducts(db);
  }

  Future _insertDummyProducts(Database db) async {
    final String response =
        await rootBundle.loadString('assets/data/product.json');
    final List<dynamic> data = json.decode(response);

    for (var item in data) {
      final product = ProductModel.fromJson(item as Map<String, dynamic>);
      await db.insert('products', product.toJson());
    }
    print("Database Initialized and Dummy Products Inserted.");
  }
}
