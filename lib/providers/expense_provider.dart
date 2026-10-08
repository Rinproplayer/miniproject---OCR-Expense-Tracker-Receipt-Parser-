import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../models/expense_receipt.dart';
import '../../models/category.dart';

class ExpenseListNotifier extends StateNotifier<AsyncValue<List<ExpenseReceipt>>> {
  ExpenseListNotifier() : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final list = await DatabaseHelper.instance.getAllExpenses();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addExpense(ExpenseReceipt expense) async {
    try {
      final id = await DatabaseHelper.instance.insertExpense(expense);
      final newExpense = expense.copyWith(id: id);
      state = state.whenData((list) => [newExpense, ...list]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseReceipt expense) async {
    try {
      await DatabaseHelper.instance.updateExpense(expense);
      state = state.whenData((list) =>
          list.map((e) => e.id == expense.id ? expense : e).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await DatabaseHelper.instance.deleteExpense(id);
      state = state.whenData((list) => list.where((e) => e.id != id).toList());
      return true;
    } catch (e) {
      return false;
    }
  }
}

final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<ExpenseReceipt>>>((ref) {
  return ExpenseListNotifier();
});

// Derived Providers for Statistics & Filtering
final totalSpendingProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  return asyncExpenses.maybeWhen(
    data: (expenses) => expenses.fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );
});

final currentMonthSpendingProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final now = DateTime.now();
  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0.0, (sum, e) => sum + e.amount);
    },
    orElse: () => 0.0,
  );
});

final todaySpendingProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final now = DateTime.now();
  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses
          .where((e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day)
          .fold(0.0, (sum, e) => sum + e.amount);
    },
    orElse: () => 0.0,
  );
});

final categoryBreakdownProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  return asyncExpenses.maybeWhen(
    data: (expenses) {
      final Map<ExpenseCategory, double> map = {};
      for (final e in expenses) {
        map[e.category] = (map[e.category] ?? 0.0) + e.amount;
      }
      return map;
    },
    orElse: () => {},
  );
});

final weeklySpendingProvider = Provider<Map<int, double>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final now = DateTime.now();
  final Map<int, double> weekly = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0};

  final monday = now.subtract(Duration(days: now.weekday - 1));
  final startOfMonday = DateTime(monday.year, monday.month, monday.day);
  final endOfWeek = startOfMonday.add(const Duration(days: 7));

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      for (final exp in expenses) {
        if (exp.date.isAfter(startOfMonday.subtract(const Duration(seconds: 1))) &&
            exp.date.isBefore(endOfWeek)) {
          weekly[exp.date.weekday] = (weekly[exp.date.weekday] ?? 0.0) + exp.amount;
        }
      }
      return weekly;
    },
    orElse: () => weekly,
  );
});
