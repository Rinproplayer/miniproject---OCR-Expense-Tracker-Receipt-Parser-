import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/ocr/receipt_regex_parser.dart';
import 'package:vku_expense_ocr/models/category.dart';

void main() {
  group('ReceiptRegexParser Unit Tests', () {
    test('Correctly parses Vietnamese Coffee receipt', () {
      const receipt = '''
      HIGHLANDS COFFEE - CHI NHÁNH ĐÀ NẴNG
      Địa chỉ: 123 Nguyễn Văn Thoại, Sơn Trà, Đà Nẵng
      Số HĐ: HD998231
      Ngày: 20/09/2026 09:30
      
      1. Phin Sữa Đá (L)     1     39.000
      2. Trà Sen Vàng (M)    1     45.000
      3. Bánh Mì Que         2     38.000
      
      Cộng tiền hàng:            122.000
      Thuế GTGT (10%):            12.200
      TỔNG CỘNG:                 134.200 đ
      Tiền mặt:                  150.000
      Tiền thừa:                  15.800
      ''';

      final result = ReceiptRegexParser.parse(receipt);

      expect(result.merchant.toUpperCase(), contains('HIGHLANDS COFFEE'));
      expect(result.amount, equals(134200.0));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(9));
      expect(result.date.day, equals(20));
      expect(result.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('Correctly parses Stationery / Study receipt', () {
      const receipt = '''
      NHÀ SÁCH FAHASA ĐÀ NẴNG
      Phiếu Thu Tiền
      Ngày bán: 05-10-2026
      
      Giáo trình Kỹ thuật phần mềm      150.000
      Vở kẻ ngang 200 trang              30.000
      Bút bi Thiên Long                  15.000
      
      Thành tiền: 195.000 VND
      ''';

      final result = ReceiptRegexParser.parse(receipt);

      expect(result.merchant.toUpperCase(), contains('FAHASA'));
      expect(result.amount, equals(195000.0));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(10));
      expect(result.date.day, equals(5));
      expect(result.suggestedCategory, equals(ExpenseCategory.study));
    });

    test('Correctly parses English receipt with comma separators', () {
      const receipt = '''
      Starbucks Coffee
      Date: 2026-10-01
      
      Caramel Macchiato    1    65,000
      Croissant           1    45,000
      
      Total Amount: 110,000
      ''';

      final result = ReceiptRegexParser.parse(receipt);

      expect(result.merchant.toLowerCase(), contains('starbucks'));
      expect(result.amount, equals(110000.0));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(10));
      expect(result.date.day, equals(1));
    });
  });
}
