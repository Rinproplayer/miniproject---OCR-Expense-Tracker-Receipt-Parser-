import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food (Ăn uống)';
      case ExpenseCategory.study:
        return 'Study (Học tập)';
      case ExpenseCategory.travel:
        return 'Travel (Đi lại)';
      case ExpenseCategory.gear:
        return 'Gear (Thiết bị)';
      case ExpenseCategory.entertainment:
        return 'Entertainment (Giải trí)';
      case ExpenseCategory.other:
        return 'Other (Khác)';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.study:
        return Icons.menu_book;
      case ExpenseCategory.travel:
        return Icons.directions_car;
      case ExpenseCategory.gear:
        return Icons.devices_other;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6D00); // Amber orange
      case ExpenseCategory.study:
        return const Color(0xFF2979FF); // Blue
      case ExpenseCategory.travel:
        return const Color(0xFF00BFA5); // Teal
      case ExpenseCategory.gear:
        return const Color(0xFF7C4DFF); // Purple
      case ExpenseCategory.entertainment:
        return const Color(0xFFFF5252); // Red accent
      case ExpenseCategory.other:
        return const Color(0xFF78909C); // Blue grey
    }
  }

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    final val = value.toLowerCase();
    if (val == 'food' || val.contains('ăn')) return ExpenseCategory.food;
    if (val == 'study' || val.contains('học')) return ExpenseCategory.study;
    if (val == 'travel' || val == 'transport' || val.contains('đi') || val.contains('xăng')) return ExpenseCategory.travel;
    if (val == 'gear' || val == 'utilities' || val.contains('thiết bị') || val.contains('in')) return ExpenseCategory.gear;
    if (val == 'entertainment' || val == 'clbevent' || val.contains('giải trí') || val.contains('clb')) return ExpenseCategory.entertainment;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val,
      orElse: () => ExpenseCategory.other,
    );
  }
}
