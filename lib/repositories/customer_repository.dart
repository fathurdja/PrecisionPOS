import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CustomerModel>> getCustomers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) {
      return CustomerModel.fromMap(maps[i]);
    });
  }

  Future<int> addCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) {
      return CustomerModel.fromMap(maps[i]);
    });
  }
}
