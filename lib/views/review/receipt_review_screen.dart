import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/category.dart';
import '../../models/expense_receipt.dart';
import '../../providers/expense_provider.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final ExpenseReceipt? initialReceipt;
  final String? imagePath;
  final String? rawOcrText;
  final String? extractedMerchant;
  final double? extractedAmount;
  final DateTime? extractedDate;
  final ExpenseCategory? suggestedCategory;

  const ReceiptReviewScreen({
    super.key,
    this.initialReceipt,
    this.imagePath,
    this.rawOcrText,
    this.extractedMerchant,
    this.extractedAmount,
    this.extractedDate,
    this.suggestedCategory,
  });

  @override
  ConsumerState<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialReceipt;
    _merchantController = TextEditingController(
      text: rec?.merchant ?? widget.extractedMerchant ?? '',
    );

    final initialAmt = rec?.amount ?? widget.extractedAmount ?? 0.0;
    _amountController = TextEditingController(
      text: initialAmt > 0 ? initialAmt.toStringAsFixed(0) : '',
    );

    _noteController = TextEditingController(text: rec?.note ?? '');
    _selectedDate = rec?.date ?? widget.extractedDate ?? DateTime.now();
    _selectedCategory = rec?.category ?? widget.suggestedCategory ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final photo = widget.initialReceipt?.imagePath ?? widget.imagePath;
    final ocrText = widget.initialReceipt?.rawOcrText ?? widget.rawOcrText;

    final expense = ExpenseReceipt(
      id: widget.initialReceipt?.id,
      merchant: _merchantController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      imagePath: photo,
      rawOcrText: ocrText,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: widget.initialReceipt?.createdAt ?? DateTime.now(),
    );

    bool success = false;
    if (widget.initialReceipt?.id != null) {
      success = await ref.read(expenseListProvider.notifier).updateExpense(expense);
    } else {
      success = await ref.read(expenseListProvider.notifier).addExpense(expense);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialReceipt != null
                ? 'Đã cập nhật hóa đơn thành công!'
                : 'Đã lưu hóa đơn vào cơ sở dữ liệu!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi lưu dữ liệu!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageToShow = widget.initialReceipt?.imagePath ?? widget.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialReceipt != null ? 'Chỉnh sửa hóa đơn' : 'Xác nhận thông tin OCR'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveExpense,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: AppColors.primary),
            label: Text(
              'Lưu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Receipt Image Preview (if present)
              if (imageToShow != null && File(imageToShow).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.file(
                        File(imageToShow),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ảnh hóa đơn',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kiểm tra và sửa lại thông tin nhận diện trước khi lưu vào sổ thu chi VKU.',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Merchant Input
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng / Đơn vị bán',
                  prefixIcon: Icon(Icons.storefront),
                  hintText: 'VD: Highlands Coffee, Căn tin VKU...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên đơn vị / cửa hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền thanh toán',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: 'VNĐ',
                  helperText: _amountController.text.isNotEmpty
                      ? 'Thành chữ: ${CurrencyFormatter.format(double.tryParse(_amountController.text) ?? 0.0)}'
                      : null,
                ),
                onChanged: (text) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. Date selection
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ngày hóa đơn', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(
                            DateFormatter.format(_selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Thay đổi'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Category Selection Chips
              Text(
                'Danh mục chi tiêu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.displayName),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 7. Notes
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú thêm (tùy chọn)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'VD: Mua giáo trình Kỹ thuật phần mềm, ăn trưa cùng CLB...',
                ),
              ),
              const SizedBox(height: 16),

              // 8. OCR Raw Text Collapsible Accordion
              if (widget.rawOcrText != null && widget.rawOcrText!.isNotEmpty)
                ExpansionTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Xem nội dung OCR thô (ML Kit)'),
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        widget.rawOcrText!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // 9. Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveExpense,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu vào sổ thu chi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
