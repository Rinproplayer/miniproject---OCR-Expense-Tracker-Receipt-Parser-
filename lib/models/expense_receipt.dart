import 'category.dart';

class ExpenseReceipt {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? imagePath;
  final String? rawOcrText;
  final String? note;
  final DateTime createdAt;

  ExpenseReceipt({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawOcrText,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenseReceipt copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? imagePath,
    String? rawOcrText,
    String? note,
    DateTime? createdAt,
  }) {
    return ExpenseReceipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseReceipt.fromMap(Map<String, dynamic> map) {
    return ExpenseReceipt(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Chưa xác định',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ExpenseCategoryExtension.fromString(map['category'] as String?),
      imagePath: map['imagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
