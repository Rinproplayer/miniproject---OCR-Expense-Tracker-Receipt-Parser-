import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/expense_receipt.dart';
import '../../models/category.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT,
        rawOcrText TEXT,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Create
  Future<int> insertExpense(ExpenseReceipt expense) async {
    final db = await instance.database;
    return await db.insert(
      AppConstants.tableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Read all
  Future<List<ExpenseReceipt>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableName,
      orderBy: 'date DESC, id DESC',
    );
    return result.map((json) => ExpenseReceipt.fromMap(json)).toList();
  }

  /// Read by ID
  Future<ExpenseReceipt?> getExpenseById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ExpenseReceipt.fromMap(maps.first);
    }
    return null;
  }

  /// Update
  Future<int> updateExpense(ExpenseReceipt expense) async {
    final db = await instance.database;
    return await db.update(
      AppConstants.tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      AppConstants.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total spending
  Future<double> getTotalSpending() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM ${AppConstants.tableName}',
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Category Breakdown for Donut Chart
  Future<Map<ExpenseCategory, double>> getCategoryBreakdown() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM ${AppConstants.tableName} 
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> breakdown = {};
    for (var row in result) {
      final category = ExpenseCategoryExtension.fromString(row['category'] as String?);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      breakdown[category] = total;
    }
    return breakdown;
  }

  /// Weekly Spending (last 7 days) for Bar Chart
  Future<Map<int, double>> getWeeklySpending() async {
    final expenses = await getAllExpenses();
    final now = DateTime.now();
    // Map weekday (1=Mon ... 7=Sun) to total
    final Map<int, double> weekly = {
      1: 0.0,
      2: 0.0,
      3: 0.0,
      4: 0.0,
      5: 0.0,
      6: 0.0,
      7: 0.0,
    };

    // Beginning of current week (Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonday = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfMonday.add(const Duration(days: 7));

    for (var exp in expenses) {
      if (exp.date.isAfter(startOfMonday.subtract(const Duration(seconds: 1))) &&
          exp.date.isBefore(endOfWeek)) {
        weekly[exp.date.weekday] = (weekly[exp.date.weekday] ?? 0.0) + exp.amount;
      }
    }

    return weekly;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
