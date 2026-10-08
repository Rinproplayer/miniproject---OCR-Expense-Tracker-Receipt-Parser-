import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/expense_receipt.dart';
import '../../models/category.dart';
import 'expense_provider.dart';

class FilterState {
  final String searchQuery;
  final ExpenseCategory? selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterState({
    this.searchQuery = '',
    this.selectedCategory,
    this.startDate,
    this.endDate,
  });

  FilterState copyWith({
    String? searchQuery,
    ExpenseCategory? selectedCategory,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(ExpenseCategory? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = FilterState(
      searchQuery: state.searchQuery,
      selectedCategory: state.selectedCategory,
      startDate: start,
      endDate: end,
    );
  }

  void resetFilters() {
    state = const FilterState();
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

final filteredExpensesProvider = Provider<List<ExpenseReceipt>>((ref) {
  final asyncExpenses = ref.watch(expenseListProvider);
  final filter = ref.watch(filterProvider);

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses.where((exp) {
        // Query match (merchant, note, raw text)
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final matchMerchant = exp.merchant.toLowerCase().contains(query);
          final matchNote = (exp.note ?? '').toLowerCase().contains(query);
          final matchRaw = (exp.rawOcrText ?? '').toLowerCase().contains(query);
          if (!matchMerchant && !matchNote && !matchRaw) return false;
        }

        // Category filter
        if (filter.selectedCategory != null &&
            exp.category != filter.selectedCategory) {
          return false;
        }

        // Date range filter
        if (filter.startDate != null && exp.date.isBefore(filter.startDate!)) {
          return false;
        }
        if (filter.endDate != null && exp.date.isAfter(filter.endDate!)) {
          return false;
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
