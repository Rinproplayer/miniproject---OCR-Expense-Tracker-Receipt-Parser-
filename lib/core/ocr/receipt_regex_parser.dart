import '../utils/currency_formatter.dart';
import '../../models/category.dart';

class ParsedReceiptResult {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory suggestedCategory;
  final String rawText;
  final double confidenceScore;

  ParsedReceiptResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.suggestedCategory,
    required this.rawText,
    this.confidenceScore = 1.0,
  });
}

class ReceiptRegexParser {
  /// Main parsing pipeline
  static ParsedReceiptResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceiptResult(
        merchant: 'Hóa đơn chưa rõ',
        amount: 0.0,
        date: DateTime.now(),
        suggestedCategory: ExpenseCategory.other,
        rawText: rawText,
        confidenceScore: 0.0,
      );
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = extractMerchant(lines);
    final amount = extractTotalAmount(lines, rawText);
    final date = extractDate(lines, rawText) ?? DateTime.now();
    final category = suggestCategory(rawText, merchant);

    return ParsedReceiptResult(
      merchant: merchant,
      amount: amount,
      date: date,
      suggestedCategory: category,
      rawText: rawText,
      confidenceScore: (amount > 0 ? 0.5 : 0.0) + (merchant.isNotEmpty ? 0.3 : 0.0) + 0.2,
    );
  }

  /// Extract Merchant Header from top lines
  static String extractMerchant(List<String> lines) {
    final ignoreKeywords = [
      'hóa đơn', 'hoa don', 'phiếu', 'phieu', 'receipt', 'invoice',
      'thanh toán', 'tính tiền', 'gtgt', 'vat', 'cộng hòa', 'độc lập',
      'mst', 'mã số thuế', 'tel:', 'sđt:', 'địa chỉ', 'dia chi', 'address',
      'welcome', 'cảm ơn', 'cam on', 'order', 'bàn:', 'ban:', 'thu ngân',
    ];

    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Skip lines that are just numbers, symbols or boilerplate header lines
      if (line.length < 3 || RegExp(r'^[0-9\W]+$').hasMatch(line)) continue;

      bool isIgnore = false;
      for (final kw in ignoreKeywords) {
        if (lower.startsWith(kw) || lower == kw) {
          isIgnore = true;
          break;
        }
      }

      if (!isIgnore) {
        // Clean line
        String cleaned = line
            .replaceAll(RegExp(r'^[^\w\sÀ-ỹ]+|[^\w\sÀ-ỹ]+$'), '')
            .trim();
        if (cleaned.length >= 3) {
          return cleaned;
        }
      }
    }

    return lines.isNotEmpty ? lines.first : 'Cửa hàng không tên';
  }

  /// Extract Total Amount with Regex Heuristics
  static double extractTotalAmount(List<String> lines, String fullText) {
    // Regex matching total indicator labels
    final totalLabelRegex = RegExp(
      r'(tổng\s*cộng|tong\s*cong|tổng\s*tiền|tong\s*tien|thành\s*tiền|thanh\s*tien|cộng\s*tiền\s*hàng|tổng\s*thanh\s*toán|total\s*amount|grand\s*total|amount\s*due|total|payment|thanh\s*toán)',
      caseSensitive: false,
    );

    // Regex for numbers like: 120.000, 120,000, 120000, 45.50
    final numberRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?|\d+(?:[.,]\d+)?)');

    double bestAmount = 0.0;

    // Phase 1: Search specifically on lines containing Total labels
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (totalLabelRegex.hasMatch(line)) {
        // Find numbers in this line
        final matches = numberRegex.allMatches(line);
        if (matches.isNotEmpty) {
          final lastMatch = matches.last.group(0)!;
          final parsed = _parseCleanNumber(lastMatch);
          if (parsed > 0) return parsed;
        }

        // Sometimes the amount is on the next line immediately following the total label
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextMatches = numberRegex.allMatches(nextLine);
          if (nextMatches.isNotEmpty) {
            final parsed = _parseCleanNumber(nextMatches.first.group(0)!);
            if (parsed > 0) return parsed;
          }
        }
      }
    }

    // Phase 2: Fallback heuristic - examine the bottom half of the receipt for largest amount
    final candidateAmounts = <double>[];
    for (int i = (lines.length / 2).floor(); i < lines.length; i++) {
      final matches = numberRegex.allMatches(lines[i]);
      for (final match in matches) {
        final val = _parseCleanNumber(match.group(0)!);
        // Exclude dates like 2024, 2025, 2026 or small numbers like quantities < 100
        if (val > 1000 && val != 2024 && val != 2025 && val != 2026 && val != 2027) {
          candidateAmounts.add(val);
        }
      }
    }

    if (candidateAmounts.isNotEmpty) {
      candidateAmounts.sort();
      bestAmount = candidateAmounts.last;
    }

    return bestAmount;
  }

  static double _parseCleanNumber(String str) {
    try {
      // If it contains '.' and ',' like 1,234.50
      if (str.contains('.') && str.contains(',')) {
        if (str.lastIndexOf(',') > str.lastIndexOf('.')) {
          // European/Vietnamese style: 1.250,50
          str = str.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // US style: 1,250.50
          str = str.replaceAll(',', '');
        }
      } else if (str.contains('.')) {
        // e.g. 150.000 (thousands in VN) vs 15.50 (decimal)
        final parts = str.split('.');
        if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
          str = str.replaceAll('.', '');
        }
      } else if (str.contains(',')) {
        // e.g. 150,000 (thousands) vs 15,50
        final parts = str.split(',');
        if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
          str = str.replaceAll(',', '');
        } else {
          str = str.replaceAll(',', '.');
        }
      }
      return double.tryParse(str) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Extract Date from lines
  static DateTime? extractDate(List<String> lines, String fullText) {
    // Patterns:
    // 1. dd/mm/yyyy or dd-mm-yyyy or dd.mm.yyyy
    final dmyRegex = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\.-](0?[1-9]|1[012])[\/\.-](\d{4})\b');
    // 2. yyyy-mm-dd or yyyy/mm/dd
    final ymdRegex = RegExp(r'\b(\d{4})[\/\.-](0?[1-9]|1[012])[\/\.-](0?[1-9]|[12][0-9]|3[01])\b');
    // 3. dd/mm/yy
    final dmyShortRegex = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\.-](0?[1-9]|1[012])[\/\.-](\d{2})\b');

    for (final line in lines) {
      // Check YMD first
      final ymdMatch = ymdRegex.firstMatch(line);
      if (ymdMatch != null) {
        final year = int.parse(ymdMatch.group(1)!);
        final month = int.parse(ymdMatch.group(2)!);
        final day = int.parse(ymdMatch.group(3)!);
        if (_isValidDate(year, month, day)) {
          return DateTime(year, month, day);
        }
      }

      // Check DMY
      final dmyMatch = dmyRegex.firstMatch(line);
      if (dmyMatch != null) {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        if (_isValidDate(year, month, day)) {
          return DateTime(year, month, day);
        }
      }

      // Check short DMY (e.g. 15/09/25)
      final shortMatch = dmyShortRegex.firstMatch(line);
      if (shortMatch != null) {
        final day = int.parse(shortMatch.group(1)!);
        final month = int.parse(shortMatch.group(2)!);
        int year = int.parse(shortMatch.group(3)!);
        year += (year < 50 ? 2000 : 1900);
        if (_isValidDate(year, month, day)) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  static bool _isValidDate(int y, int m, int d) {
    if (y < 2000 || y > 2035) return false;
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;
    return true;
  }

  /// Suggest Category based on keywords
  static ExpenseCategory suggestCategory(String fullText, String merchant) {
    final lower = '$merchant $fullText'.toLowerCase();

    if (RegExp(r'(cà phê|coffee|cafe|trà sữa|milktea|quán|bún|phở|cơm|mì|nước|bánh|kfc|lotteria|highlands|phúc long|ăn|uống|food|restaurant|buffet)').hasMatch(lower)) {
      return ExpenseCategory.food;
    }
    if (RegExp(r'(photo|in ấn|in mau|ép plastic|giấy a4|cartridge|mực in|bản in|chuột|bàn phím|laptop|thiết bị|tai nghe|gear)').hasMatch(lower)) {
      return ExpenseCategory.gear;
    }
    if (RegExp(r'(sách|vở|giáo trình|bút|viết|tài liệu|nhà sách|fahasa|tiền học|stationery|study)').hasMatch(lower)) {
      return ExpenseCategory.study;
    }
    if (RegExp(r'(clb|câu lạc bộ|sự kiện|event|hội thảo|workshop|backdrop|banner|standee|decor|liên hoan|trại|cinema|phim|game|giải trí|karaoke)').hasMatch(lower)) {
      return ExpenseCategory.entertainment;
    }
    if (RegExp(r'(xăng|petrol|dầu|grab|be|gojek|gửi xe|vé xe|taxi|bãi đỗ|xe buýt|travel)').hasMatch(lower)) {
      return ExpenseCategory.travel;
    }

    return ExpenseCategory.other;
  }
}
