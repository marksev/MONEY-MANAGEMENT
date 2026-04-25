import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('money_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT    NOT NULL,
        emoji TEXT    NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId  INTEGER NOT NULL,
        amount      REAL    NOT NULL,
        description TEXT    NOT NULL,
        date        TEXT    NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    // Seed default categories
    const defaults = [
      {'name': 'Food',          'emoji': '🍔', 'color': 0xFFE74C3C},
      {'name': 'Transport',     'emoji': '🚗', 'color': 0xFF3498DB},
      {'name': 'Fuel',          'emoji': '⛽', 'color': 0xFFF39C12},
      {'name': 'Clothes',       'emoji': '👕', 'color': 0xFF9B59B6},
      {'name': 'Health',        'emoji': '💊', 'color': 0xFF2ECC71},
      {'name': 'Entertainment', 'emoji': '🎬', 'color': 0xFF1ABC9C},
      {'name': 'Shopping',      'emoji': '🛍️', 'color': 0xFFE67E22},
      {'name': 'Home',          'emoji': '🏠', 'color': 0xFF607D8B},
    ];
    for (final cat in defaults) {
      await db.insert('categories', cat);
    }
  }

  // ─── Categories ──────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap()..remove('id'));
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Expenses ────────────────────────────────────────────────────────────────

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
