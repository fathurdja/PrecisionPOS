import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
      version: 4, // Increment to 4 to trigger wipe
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name $textType,
        category_id TEXT,
        description TEXT,
        barcode TEXT,
        purchase_price REAL,
        price $realType,
        is_active INTEGER NOT NULL DEFAULT 1,
        stok INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        receipt_number $textType,
        tanggal $textType,
        total_price $realType,
        status $textType,
        order_type $textType,
        payment_method $textType,
        tax_amount REAL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        received_amount REAL DEFAULT 0.0,
        change_amount REAL DEFAULT 0.0,
        customer_name TEXT,
        customer_phone TEXT,
        cashier_name TEXT,
        service_amount REAL DEFAULT 0.0,
        device_id INTEGER,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        receipt_id $textType,
        product_id $textType,
        qty $integerType,
        bonus_qty INTEGER DEFAULT 0,
        unit_price $realType,
        subtotal $realType,
        FOREIGN KEY (receipt_id) REFERENCES transactions (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name $textType,
        phone TEXT NOT NULL UNIQUE,
        created_at TEXT
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
    if (oldVersion < 4) {
      // User requested to wipe local data to migrate to new API
      print("Migrating to V4 - dropping all tables to wipe old data.");
      await db.execute('DROP TABLE IF EXISTS order_items');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS staff');
      
      await _createDB(db, newVersion);
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
    try {
      final String response =
          await rootBundle.loadString('assets/data/product.json');
      final List<dynamic> data = json.decode(response);
      
      final uuid = Uuid();

      for (var item in data) {
        // Map old structure to new structure if necessary, or just load new dummy format
        final oldMap = item as Map<String, dynamic>;
        
        final newMap = {
          'id': oldMap['id']?.toString() ?? uuid.v4(),
          'name': oldMap['nama'] ?? oldMap['name'] ?? 'Unknown',
          'price': ((oldMap['harga'] ?? oldMap['price'] ?? 0) as num).toDouble(),
          'stok': oldMap['stok'] ?? 100,
          'is_active': 1,
        };
        
        final product = ProductModel.fromJson(newMap);
        await db.insert('products', product.toJson());
      }
      print("Database Initialized and Dummy Products Inserted.");
    } catch (e) {
      print("Error loading dummy products: \$e");
    }
  }
}
