import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        merchant TEXT NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Nạp một số dữ liệu mẫu giả định để demo biểu đồ ngay lập tức
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    final sampleItems = [
      {
        'amount': 45000.0,
        'date': now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
        'merchant': 'Highlands Coffee',
        'category': 'Food',
        'imagePath': null,
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'amount': 120000.0,
        'date': now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
        'merchant': 'Nhà sách Fahasa',
        'category': 'Study',
        'imagePath': null,
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'amount': 35000.0,
        'date': now.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10),
        'merchant': 'Grab Bike',
        'category': 'Travel',
        'imagePath': null,
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'amount': 250000.0,
        'date': now.subtract(const Duration(days: 4)).toIso8601String().substring(0, 10),
        'merchant': 'Chuột không dây Logitech',
        'category': 'Gear',
        'imagePath': null,
        'createdAt': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
      {
        'amount': 85000.0,
        'date': now.subtract(const Duration(days: 5)).toIso8601String().substring(0, 10),
        'merchant': 'Vé xem phim CGV',
        'category': 'Entertainment',
        'imagePath': null,
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
    ];

    for (final item in sampleItems) {
      await db.insert('transactions', item);
    }
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<double> getTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM transactions');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Tính tổng chi tiêu gom theo từng danh mục
  Future<Map<String, double>> getCategoryDistribution() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      GROUP BY category
    ''');

    final Map<String, double> distribution = {
      'Food': 0.0,
      'Study': 0.0,
      'Travel': 0.0,
      'Gear': 0.0,
      'Entertainment': 0.0,
    };

    for (final row in result) {
      final category = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (category != null) {
        distribution[category] = total;
      }
    }

    return distribution;
  }

  /// Lấy tổng chi tiêu 7 ngày trong tuần gần nhất
  Future<Map<String, double>> getWeeklySpending() async {
    final db = await database;
    final now = DateTime.now();

    // Khởi tạo map cho 7 ngày qua
    final Map<String, double> weekly = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = day.toIso8601String().substring(0, 10);
      weekly[dateKey] = 0.0;
    }

    final startDate = now.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT date, SUM(amount) as total
      FROM transactions
      WHERE date >= ?
      GROUP BY date
    ''', [startDate]);

    for (final row in result) {
      final date = row['date'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (date != null && weekly.containsKey(date)) {
        weekly[date] = total;
      }
    }

    return weekly;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
