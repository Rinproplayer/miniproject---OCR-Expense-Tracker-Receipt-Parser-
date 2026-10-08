import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/category.dart';
import '../../providers/filter_provider.dart';
import '../history/expense_detail_screen.dart';

class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final filter = ref.watch(filterProvider);

    final totalFilteredAmount = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chi tiêu VKU'),
        actions: [
          if (filter.searchQuery.isNotEmpty || filter.selectedCategory != null || filter.startDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Xóa bộ lọc',
              onPressed: () => ref.read(filterProvider.notifier).resetFilters(),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng, ghi chú...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(filterProvider.notifier).setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => ref.read(filterProvider.notifier).setSearchQuery(val),
            ),
          ),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: filter.selectedCategory == null,
                  onSelected: (_) => ref.read(filterProvider.notifier).setCategory(null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map((cat) {
                  final isSelected = filter.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                      label: Text(cat.displayName),
                      selected: isSelected,
                      selectedColor: cat.color.withOpacity(0.8),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      onSelected: (_) => ref.read(filterProvider.notifier).setCategory(cat),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 3. Stats Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredExpenses.length} kết quả',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                Text(
                  'Tổng: ${CurrencyFormatter.format(totalFilteredAmount)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // 4. Results List
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy hóa đơn phù hợp',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredExpenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exp = filteredExpenses[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: exp.category.color.withOpacity(0.15),
                          child: Icon(exp.category.icon, color: exp.category.color, size: 20),
                        ),
                        title: Text(exp.merchant, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${DateFormatter.format(exp.date)} • ${exp.category.displayName}',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(exp.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExpenseDetailScreen(expense: exp),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
