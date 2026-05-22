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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        status $textType,
        customer_name TEXT,
        cashier_name TEXT,
        tax_amount REAL DEFAULT 0.0,
        service_amount REAL DEFAULT 0.0
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

    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        password TEXT,
        last_active TEXT,
        revenue REAL DEFAULT 0.0
      )
    ''');

    await _insertDummyProducts(db);
    await _insertInitialStaff(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN cashier_name TEXT');
      } catch (e) {
        print("Column cashier_name might already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN tax_amount REAL DEFAULT 0.0');
      } catch (e) {
        print("Column tax_amount might already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN service_amount REAL DEFAULT 0.0');
      } catch (e) {
        print("Column service_amount might already exist: $e");
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS staff (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          role TEXT NOT NULL,
          password TEXT,
          last_active TEXT,
          revenue REAL DEFAULT 0.0
        )
      ''');

      await _insertInitialStaff(db);
    }
  }

  Future _insertInitialStaff(Database db) async {
    final result = await db.query('staff', where: 'email = ?', whereArgs: ['kasir']);
    if (result.isEmpty) {
      await db.insert('staff', {
        'name': 'Budi Pemilik',
        'email': 'admin',
        'role': 'admin',
        'password': 'admin123',
        'last_active': DateTime.now().toIso8601String(),
        'revenue': 0.0,
      });
      await db.insert('staff', {
        'name': 'Ani Kasir',
        'email': 'kasir',
        'role': 'kasir',
        'password': 'kasir123',
        'last_active': DateTime.now().toIso8601String(),
        'revenue': 0.0,
      });
      await db.insert('staff', {
        'name': 'Dedi Kurir',
        'email': 'delivery',
        'role': 'delivery',
        'password': 'delivery123',
        'last_active': DateTime.now().toIso8601String(),
        'revenue': 0.0,
      });
    }
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
