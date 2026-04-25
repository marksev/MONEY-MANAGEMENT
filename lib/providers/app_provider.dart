import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';

enum FilterPeriod { today, week, month, year }

class AppProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Expense> _expenses = [];
  FilterPeriod _filter = FilterPeriod.month;
  bool _loading = false;

  List<Category> get categories => _categories;
  List<Expense> get expenses => _expenses;
  FilterPeriod get filter => _filter;
  bool get loading => _loading;

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();
    _categories = await DatabaseHelper.instance.getCategories();
    _expenses = await DatabaseHelper.instance.getExpenses();
    _loading = false;
    notifyListeners();
  }

  void setFilter(FilterPeriod f) {
    _filter = f;
    notifyListeners();
  }

  List<Expense> get filteredExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      switch (_filter) {
        case FilterPeriod.today:
          return e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
        case FilterPeriod.week:
          // current calendar week, starting Monday
          final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
          return !e.date.isBefore(monday);
        case FilterPeriod.month:
          return e.date.year == now.year && e.date.month == now.month;
        case FilterPeriod.year:
          return e.date.year == now.year;
      }
    }).toList();
  }

  double get totalFiltered =>
      filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Total per category for the active filter period, sorted descending.
  List<MapEntry<Category, double>> get categoryTotals {
    final map = <int, double>{};
    for (final e in filteredExpenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    final result = <MapEntry<Category, double>>[];
    for (final entry in map.entries) {
      final cat = getCategoryById(entry.key);
      if (cat != null) result.add(MapEntry(cat, entry.value));
    }
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Category operations ──────────────────────────────────────────────────

  Future<void> addCategory(Category category) async {
    final id = await DatabaseHelper.instance.insertCategory(category);
    _categories.add(category.copyWith(id: id));
    _categories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await DatabaseHelper.instance.updateCategory(category);
    final i = _categories.indexWhere((c) => c.id == category.id);
    if (i != -1) _categories[i] = category;
    _categories.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ─── Expense operations ───────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    final id = await DatabaseHelper.instance.insertExpense(expense);
    _expenses.insert(0, expense.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await DatabaseHelper.instance.updateExpense(expense);
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    if (i != -1) _expenses[i] = expense;
    // re-sort by date desc
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
