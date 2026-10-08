import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/expense_receipt.dart';
import '../../models/category.dart';
import '../../providers/expense_provider.dart';
import '../review/receipt_review_screen.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseReceipt expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasImage = expense.imagePath != null && File(expense.imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ReceiptReviewScreen(initialReceipt: expense),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Xóa hóa đơn',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Xóa hóa đơn "${expense.merchant}" khỏi hệ thống?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Xóa vĩnh viễn'),
                    ),
                  ],
                ),
              );

              if (confirm == true && expense.id != null) {
                await ref.read(expenseListProvider.notifier).deleteExpense(expense.id!);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Receipt Image
            if (hasImage)
              GestureDetector(
                onTap: () {
                  // Fullscreen Image dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: Image.file(
                              File(expense.imagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.file(
                        File(expense.imagePath!),
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Chạm để phóng to', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 2. Main Price Card
            Card(
              elevation: 0,
              color: expense.category.color.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: expense.category.color.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      expense.merchant,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(expense.amount),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: expense.category.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      avatar: Icon(expense.category.icon, size: 16, color: Colors.white),
                      label: Text(expense.category.displayName),
                      backgroundColor: expense.category.color,
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Detail Info List
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                    title: const Text('Ngày lập hóa đơn'),
                    subtitle: Text(DateFormatter.formatFull(expense.date)),
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary),
                      title: const Text('Ghi chú'),
                      subtitle: Text(expense.note!),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: AppColors.primary),
                    title: const Text('Thời gian lưu'),
                    subtitle: Text(DateFormatter.formatFull(expense.createdAt)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Raw OCR Text
            if (expense.rawOcrText != null && expense.rawOcrText!.isNotEmpty)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.text_snippet_outlined, color: AppColors.primary),
                  title: const Text('Bản ghi nhận diện chữ OCR thô'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        expense.rawOcrText!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
